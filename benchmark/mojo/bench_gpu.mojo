# json GPU Benchmark
# Uses cuJSON dataset: https://github.com/AutomataLab/cuJSON
#
# Usage:
#   mojo -I . benchmark/mojo/bench_gpu.mojo [json_file] [--debug-timing]

from std.benchmark import (
    Bench,
    BenchConfig,
    Bencher,
    BenchId,
    ThroughputMeasure,
    BenchMetric,
    Unit,
)
from std.pathlib import Path
from std.sys import argv
from std.memory import memcpy
from std.collections import List

from json import loads
from json.gpu import parse_json_gpu, parse_json_gpu_from_pinned
from json.types import JSONInput
from std.gpu.host import DeviceContext


def main() raises:
    # Parse argv: one optional positional path + optional --debug-timing flag.
    # Either order is accepted:
    #   bench_gpu <path>
    #   bench_gpu --debug-timing
    #   bench_gpu --debug-timing <path>
    #   bench_gpu <path> --debug-timing
    var args = argv()
    var path: String = "benchmark/datasets/twitter.json"
    var verbose = False
    for i in range(1, len(args)):
        var a = String(args[i])
        if a == "--debug-timing":
            verbose = True
        else:
            path = a

    print()
    print("=" * 72)
    print("json GPU Benchmark")
    print("=" * 72)
    print()

    # Load JSON file
    var content = Path(path).read_text()
    var size = content.byte_length()
    var size_mb = Float64(size) / 1024.0 / 1024.0

    print("File:", path)
    print("Size:", size, "bytes (", size_mb, "MB )")
    print()

    # Warmup GPU
    print("Warming up GPU...")
    for _ in range(2):
        var result = loads[target="gpu"](content)
        _ = result.is_object()
    print()

    var data = content.as_bytes()
    var n = len(data)

    # Long-lived context + pinned buffer reused across every iteration of
    # every benchmark below. The pinned allocation itself is slow (~100 ms
    # on a B200) so doing it once outside the Bencher is important.
    var ctx = DeviceContext()
    var h_input = ctx.enqueue_create_host_buffer[DType.uint8](n)
    memcpy(dest=h_input.unsafe_ptr(), src=data.unsafe_ptr(), count=n)
    ctx.synchronize()

    # Configure max_iters based on file size so the large-file runs finish
    # in a reasonable wall time.
    var max_iters = 100
    if size_mb > 100:
        max_iters = 10
    elif size_mb > 10:
        max_iters = 20

    var bench = Bench(BenchConfig(max_iters=max_iters))
    var measures = List[ThroughputMeasure]()
    measures.append(ThroughputMeasure(BenchMetric.bytes, size))

    # -----------------------------------------------------------------
    # 1. Raw: new JSONInput buffer + CPU memcpy + H2D + GPU kernels + CPU
    # post-processing, wall-clock (matches `parse_json_gpu` public API).
    # -----------------------------------------------------------------
    @parameter
    @always_inline
    def bench_raw(mut b: Bencher) raises capturing:
        @parameter
        @always_inline
        def call_fn() raises:
            var bytes = List[UInt8](capacity=n)
            bytes.resize(n, 0)
            memcpy(dest=bytes.unsafe_ptr(), src=data.unsafe_ptr(), count=n)
            var input_obj = JSONInput(bytes^)
            var result = parse_json_gpu(input_obj^, verbose=verbose)
            _ = len(result.structural)

        b.iter[call_fn]()

    bench.bench_function[bench_raw](
        BenchId("json_gpu", "parse_json_gpu (raw, wall-clock)"), measures
    )

    # -----------------------------------------------------------------
    # 2. Pinned: reuses the already-loaded pinned buffer so we skip the
    # host-side memcpy, wall-clock (matches `parse_json_gpu_from_pinned`).
    # -----------------------------------------------------------------
    @parameter
    @always_inline
    def bench_pinned(mut b: Bencher) raises capturing:
        @parameter
        @always_inline
        def call_fn() raises:
            var result = parse_json_gpu_from_pinned(
                ctx, h_input, n, verbose=verbose
            )
            _ = len(result.structural)

        b.iter[call_fn]()

    bench.bench_function[bench_pinned](
        BenchId(
            "json_gpu", "parse_json_gpu_from_pinned (pinned, wall-clock)"
        ),
        measures,
    )

    # -----------------------------------------------------------------
    # 3. Pinned, device-only: same call wrapped in iter_custom so the
    # Bencher uses DeviceContext.execution_time (CUDA events) instead of
    # host wall-clock. Separates pure GPU queue time from the CPU post-
    # processing (bracket matching, Value construction inside the call).
    # -----------------------------------------------------------------
    @parameter
    @always_inline
    def bench_pinned_device(mut b: Bencher) raises capturing:
        @parameter
        @always_inline
        def launch(launch_ctx: DeviceContext) raises:
            var result = parse_json_gpu_from_pinned(
                launch_ctx, h_input, n, verbose=verbose
            )
            _ = len(result.structural)

        b.iter_custom[launch](ctx)

    bench.bench_function[bench_pinned_device](
        BenchId("json_gpu", "parse_json_gpu_from_pinned (device-only)"),
        measures,
    )

    # -----------------------------------------------------------------
    # 4. Full public loads[target="gpu"] path (includes Value tree build).
    # -----------------------------------------------------------------
    @parameter
    @always_inline
    def bench_gpu_loads(mut b: Bencher) raises capturing:
        @parameter
        @always_inline
        def call_fn() raises:
            var v = loads[target="gpu"](content)
            _ = v.is_object()

        b.iter[call_fn]()

    bench.bench_function[bench_gpu_loads](
        BenchId("json_gpu", "loads[target='gpu']"), measures
    )

    print(bench)
