# Experimental GPU Bracket Matching using prefix sum
#
# Algorithm:
# 1. Compute depth delta: +1 for {[, -1 for }]
# 2. Inclusive prefix sum to get depth at each position
# 3. For opening brackets: depth -= 1 (to match closing bracket's depth)
# 4. Within each depth, pair opening with next closing

from std.gpu.host import DeviceContext, DeviceBuffer, HostBuffer
from std.gpu import block_dim, block_idx, thread_idx, barrier
from std.collections import List
from std.memory import UnsafePointer, memcpy
from std.math import ceildiv

from .kernels import BLOCK_SIZE_OPT

# Character type constants (must match stream_compact.mojo)
comptime CHAR_TYPE_OPEN_BRACE: UInt8 = UInt8(ord("{"))
comptime CHAR_TYPE_CLOSE_BRACE: UInt8 = UInt8(ord("}"))
comptime CHAR_TYPE_OPEN_BRACKET: UInt8 = UInt8(ord("["))
comptime CHAR_TYPE_CLOSE_BRACKET: UInt8 = UInt8(ord("]"))
comptime CHAR_TYPE_COLON: UInt8 = UInt8(ord(":"))
comptime CHAR_TYPE_COMMA: UInt8 = UInt8(ord(","))


def is_open(c: UInt8) -> Bool:
    """Check if character is an opening bracket."""
    return c == CHAR_TYPE_OPEN_BRACE or c == CHAR_TYPE_OPEN_BRACKET


def is_close(c: UInt8) -> Bool:
    """Check if character is a closing bracket."""
    return c == CHAR_TYPE_CLOSE_BRACE or c == CHAR_TYPE_CLOSE_BRACKET


def brackets_match(open_char: UInt8, close_char: UInt8) -> Bool:
    """Check if open and close brackets match."""
    return (
        open_char == CHAR_TYPE_OPEN_BRACE
        and close_char == CHAR_TYPE_CLOSE_BRACE
    ) or (
        open_char == CHAR_TYPE_OPEN_BRACKET
        and close_char == CHAR_TYPE_CLOSE_BRACKET
    )


# ===== Kernel 1: Compute depth deltas =====
def compute_depth_delta_kernel(
    char_types: UnsafePointer[UInt8, MutAnyOrigin],
    depth_deltas: UnsafePointer[Int32, MutAnyOrigin],
    n: UInt,
):
    """Compute depth delta for each position: +1 for {[, -1 for }], 0 otherwise.
    """
    var gid = Int(block_dim.x) * Int(block_idx.x) + Int(thread_idx.x)
    if gid >= Int(n):
        return

    var c = char_types[gid]
    var delta: Int32 = 0
    if is_open(c):
        delta = 1
    elif is_close(c):
        delta = -1

    depth_deltas[gid] = delta


# ===== Kernel 2: Block-level inclusive prefix sum for depths =====
def depth_prefix_sum_kernel(
    depth_deltas: UnsafePointer[Int32, MutAnyOrigin],
    depths: UnsafePointer[Int32, MutAnyOrigin],
    block_totals: UnsafePointer[Int32, MutAnyOrigin],
    n: UInt,
):
    """Compute inclusive prefix sum of depth deltas (Metal + CUDA compatible).

    Sequential single-thread scan avoids warp-shuffle intrinsics that the
    Metal backend does not support. The depth array is small (one entry per
    structural character) so this is fast in practice.
    """
    if Int(thread_idx.x) != 0 or Int(block_idx.x) != 0:
        return

    var running_sum: Int32 = 0
    for i in range(Int(n)):
        running_sum += depth_deltas[i]
        depths[i] = running_sum

    block_totals[0] = running_sum


# ===== Kernel 3: Add block offsets to depths =====
def add_depth_offsets_kernel(
    depths: UnsafePointer[Int32, MutAnyOrigin],
    block_offsets: UnsafePointer[Int32, MutAnyOrigin],
    n: UInt,
):
    """Add block offset to each depth value."""
    var bid = Int(block_idx.x)
    var gid = bid * Int(block_dim.x) + Int(thread_idx.x)

    if gid >= Int(n):
        return

    if bid > 0:
        depths[gid] = depths[gid] + block_offsets[bid]


# ===== Kernel 4: Adjust opening bracket depths =====
def adjust_open_depths_kernel(
    char_types: UnsafePointer[UInt8, MutAnyOrigin],
    depths: UnsafePointer[Int32, MutAnyOrigin],
    n: UInt,
):
    """For opening brackets, subtract 1 from depth so it matches closing bracket.
    """
    var gid = Int(block_dim.x) * Int(block_idx.x) + Int(thread_idx.x)
    if gid >= Int(n):
        return

    var c = char_types[gid]
    if is_open(c):
        depths[gid] = depths[gid] - 1


# ===== Helper: Compute hierarchical prefix sum =====
def _compute_depth_prefix_sum(
    ctx: DeviceContext,
    d_block_totals_ptr: UnsafePointer[Int32, MutAnyOrigin],
    d_block_prefix_ptr: UnsafePointer[Int32, MutAnyOrigin],
    num_blocks: Int,
) raises:
    """Recursively compute prefix sum of block totals."""
    if num_blocks <= BLOCK_SIZE_OPT:
        var d_dummy = ctx.enqueue_create_buffer[DType.int32](1)
        d_dummy.enqueue_fill(0)

        ctx.enqueue_function_unchecked[depth_prefix_sum_kernel](
            d_block_totals_ptr,
            d_block_prefix_ptr,
            d_dummy.unsafe_ptr(),
            UInt(num_blocks),
            grid_dim=1,
            block_dim=BLOCK_SIZE_OPT,
        )
        return

    var num_blocks_l1 = ceildiv(num_blocks, BLOCK_SIZE_OPT)
    var d_block_totals_l1 = ctx.enqueue_create_buffer[DType.int32](
        num_blocks_l1
    )
    d_block_totals_l1.enqueue_fill(0)

    ctx.enqueue_function_unchecked[depth_prefix_sum_kernel](
        d_block_totals_ptr,
        d_block_prefix_ptr,
        d_block_totals_l1.unsafe_ptr(),
        UInt(num_blocks),
        grid_dim=num_blocks_l1,
        block_dim=BLOCK_SIZE_OPT,
    )

    var d_block_prefix_l1 = ctx.enqueue_create_buffer[DType.int32](
        num_blocks_l1
    )
    d_block_prefix_l1.enqueue_fill(0)

    _compute_depth_prefix_sum(
        ctx,
        d_block_totals_l1.unsafe_ptr(),
        d_block_prefix_l1.unsafe_ptr(),
        num_blocks_l1,
    )

    ctx.enqueue_function_unchecked[add_depth_offsets_kernel](
        d_block_prefix_ptr,
        d_block_prefix_l1.unsafe_ptr(),
        UInt(num_blocks),
        grid_dim=num_blocks_l1,
        block_dim=BLOCK_SIZE_OPT,
    )


def match_brackets_gpu(
    ctx: DeviceContext,
    d_char_types: UnsafePointer[UInt8, MutAnyOrigin],
    n: Int,
) raises -> Tuple[List[Int32], List[Int32]]:
    """Match brackets using GPU prefix sum.

    Returns:
        Tuple of (depths, pair_pos) lists.
        depths[i] = depth at position i.
        pair_pos[i] = index of matching bracket (-1 if not a bracket).
    """
    if n == 0:
        return (List[Int32](), List[Int32]())

    var num_blocks = ceildiv(n, BLOCK_SIZE_OPT)

    # Phase 1: Compute depth deltas
    var d_depth_deltas = ctx.enqueue_create_buffer[DType.int32](n)
    d_depth_deltas.enqueue_fill(0)

    ctx.enqueue_function_unchecked[compute_depth_delta_kernel](
        d_char_types,
        d_depth_deltas.unsafe_ptr(),
        UInt(n),
        grid_dim=num_blocks,
        block_dim=BLOCK_SIZE_OPT,
    )

    # Phase 2: Inclusive prefix sum for depths — single dispatch (sequential kernel).
    var d_depths = ctx.enqueue_create_buffer[DType.int32](n)
    d_depths.enqueue_fill(0)

    var d_block_totals = ctx.enqueue_create_buffer[DType.int32](1)
    d_block_totals.enqueue_fill(0)

    ctx.enqueue_function_unchecked[depth_prefix_sum_kernel](
        d_depth_deltas.unsafe_ptr(),
        d_depths.unsafe_ptr(),
        d_block_totals.unsafe_ptr(),
        UInt(n),
        grid_dim=1,
        block_dim=1,
    )

    # Phase 3: Adjust opening bracket depths
    ctx.enqueue_function_unchecked[adjust_open_depths_kernel](
        d_char_types,
        d_depths.unsafe_ptr(),
        UInt(n),
        grid_dim=num_blocks,
        block_dim=BLOCK_SIZE_OPT,
    )

    ctx.synchronize()

    # Copy depths back to host
    var h_depths = ctx.enqueue_create_host_buffer[DType.int32](n)
    ctx.enqueue_copy(h_depths, d_depths)

    var h_char_types = ctx.enqueue_create_host_buffer[DType.uint8](n)
    ctx.enqueue_copy(h_char_types, d_char_types)

    ctx.synchronize()

    # Phase 4: CPU pairing (within each depth, pair brackets left-to-right)
    # This is O(n) and simpler than GPU sorting
    var depths = List[Int32](capacity=n)
    depths.resize(n, 0)
    memcpy(dest=depths.unsafe_ptr(), src=h_depths.unsafe_ptr(), count=n)

    var char_types = List[UInt8](capacity=n)
    char_types.resize(n, 0)
    memcpy(dest=char_types.unsafe_ptr(), src=h_char_types.unsafe_ptr(), count=n)

    var pair_pos = List[Int32](capacity=n)
    pair_pos.resize(n, -1)

    # Find max depth
    var max_depth: Int32 = 0
    for i in range(n):
        if depths[i] > max_depth:
            max_depth = depths[i]

    # For each depth, pair brackets (stack-based per depth)
    # Use a stack per depth level
    var stacks = List[List[Int32]]()
    for _ in range(Int(max_depth) + 1):
        stacks.append(List[Int32]())

    for i in range(n):
        var c = char_types[i]
        var d = Int(depths[i])

        if is_open(c):
            if d >= 0 and d <= Int(max_depth):
                stacks[d].append(Int32(i))
        elif is_close(c):
            if d >= 0 and d <= Int(max_depth) and len(stacks[d]) > 0:
                var open_idx = Int(stacks[d].pop())
                pair_pos[open_idx] = Int32(i)
                pair_pos[i] = Int32(open_idx)

    return (depths^, pair_pos^)
