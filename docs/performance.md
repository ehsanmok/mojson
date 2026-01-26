# Performance Deep Dive

This document explains why mojson is faster than existing parsers and the key optimizations that make it possible.

## GPU: 2x Faster than cuJSON

On NVIDIA B200 with 804MB `twitter_large_record.json`:

| Parser | Throughput | Time | Speedup |
|--------|------------|------|---------|
| cuJSON (CUDA C++) | 3.6 GB/s | 236 ms | baseline |
| **mojson GPU** | **7.0 GB/s** | **121 ms** | **2.0x** |

*Based on warmed-up runs. Pinned memory path (comparable scope to cuJSON).*

## Key Optimizations

| Optimization | Impact | Description |
|--------------|--------|-------------|
| **GPU Stream Compaction** | 🔥 **Main speedup** | Reduces D2H transfer from ~160ms to minimal overhead |
| **Pinned Memory** | H2D: ~15ms | Uses `HostBuffer` for fast host-to-device transfer |
| **Hierarchical Prefix Sums** | GPU: efficient | Parallel scans using block primitives |
| **Fused Kernels** | Lower overhead | Single-pass quote detection + structural bitmap |

## Why mojson is Faster: The Stream Compaction Advantage

### The Problem with cuJSON

cuJSON transfers **all structural character data** back to CPU:

- Input: 804MB JSON file
- Structural chars: ~58% of input = **465MB transfer**
- D2H time: **~160ms** (bottleneck)

### mojson's Solution

mojson uses **GPU stream compaction** to extract only position indices:

- Input: 804MB JSON file
- Position array: ~1 million positions × 4 bytes = **4MB transfer**
- D2H time: **minimal** (116x smaller data transfer)

This is the primary reason for the 2x overall speedup.

## Detailed Timing Breakdown

### cuJSON Pipeline (~236ms total)

```
cuJSON breakdown (average):
├─ H2D transfer:       ~15 ms   (804MB → GPU)
├─ Validation:          ~2 ms   (GPU)
├─ Tokenization:        ~6 ms   (GPU)
├─ Parser:              ~2 ms   (GPU)
└─ D2H transfer:      ~160 ms   (465MB → CPU, bottleneck)
────────────────────────────────
TOTAL:                ~236 ms
Throughput:           3.6 GB/s
```

### mojson GPU Pipeline (~121ms total)

```
mojson pinned breakdown (average):
├─ H2D transfer:       ~15 ms   (804MB → GPU, pinned memory)
├─ GPU kernels:        ~30 ms   (quote detection + prefix sums + bitmap)
├─ Stream compact:     ~50 ms   (GPU position extraction)
├─ D2H transfer:       ~15 ms   (4MB positions → CPU)
└─ Bracket matching:   ~11 ms   (CPU)
────────────────────────────────
TOTAL:                ~121 ms
Throughput:           7.0 GB/s
```

## Architecture Comparison

| Aspect | cuJSON | mojson |
|--------|--------|--------|
| **Input memory** | Pinned (cudaMallocHost) | Pinned (HostBuffer) |
| **H2D transfer** | ✓ (15ms) | ✓ (15ms) |
| **GPU kernels** | Validation + Tokenization | Quote detection + Prefix sums + Bitmap |
| **Position extraction** | ❌ (transfers all data) | ✅ **GPU stream compaction** |
| **D2H transfer** | 465MB (~160ms) | 4MB (~15ms) |
| **Bracket matching** | GPU (Parser kernel) | CPU (stack algorithm) |

## Performance Metrics Explained

mojson reports three timing metrics:

| Metric | What It Includes | Use Case |
|--------|------------------|----------|
| **Pinned memory path** | H2D + GPU kernels + stream compaction + D2H + bracket matching | Direct comparison with cuJSON |
| **Raw GPU parse** | Pinned path + pageable→pinned memcpy | End-to-end from file buffer |
| **Full `loads[target='gpu']`** | Everything + Value tree construction | Real-world application performance |

### Why Three Metrics?

1. **Pinned memory path (121ms, 7.0 GB/s):** Apples-to-apples comparison with cuJSON, which assumes pinned input
2. **Raw GPU parse (~230ms, 3.7 GB/s):** Includes realistic pageable→pinned copy overhead (~110ms for 804MB)
3. **Full pipeline (~890ms, 1.0 GB/s):** Includes CPU-bound Value tree construction (~770ms)

## Benchmark Results

### GPU Performance (NVIDIA B200)

**Important:** GPU benchmarks are only meaningful for large files (>100MB). For smaller files, GPU launch overhead dominates and results are not representative of actual performance.

| Dataset | Size | Pinned Path | Speedup vs cuJSON |
|---------|------|-------------|-------------------|
| twitter_large_record.json | 804 MB | 7.0 GB/s | **2.0x** |

GPU parallelism shines with large files where the overhead is amortized.

## CPU Performance

mojson CPU backend uses simdjson via FFI:

| Dataset | Size | Throughput | Time |
|---------|------|------------|------|
| twitter.json | 617 KB | 1.6 GB/s | 0.39 ms |
| citm_catalog.json | 1.7 MB | 1.7 GB/s | 1.0 ms |

**Performance:** ~20% overhead from FFI + tree construction compared to native simdjson.

## When to Use GPU vs CPU

| File Size | Recommended Backend | Reason |
|-----------|---------------------|--------|
| < 1 MB | **CPU (simdjson)** | GPU launch overhead dominates |
| 1-100 MB | **CPU or GPU** | Comparable performance |
| > 100 MB | **GPU** | 2x faster than cuJSON, 3-5x faster than CPU |

## Optimization Techniques

### 1. GPU Stream Compaction

**Problem:** After identifying structural characters on GPU, we need their positions on CPU for bracket matching.

**Naive approach:** Transfer entire structural character bitmap (58% of input size)

**Optimized approach:**
1. Create position bitmap on GPU
2. Use parallel prefix sum to compute output positions
3. Compact positions into dense array on GPU
4. Transfer only compact position array to CPU

**Result:** 116x reduction in D2H transfer size (465MB → 4MB)

### 2. Pinned Memory

Using `HostBuffer` (pinned memory) for H2D transfers:

- Pinned: ~15ms for 804MB
- Pageable: ~110ms for 804MB
- **Speedup:** 7.3x faster

### 3. Hierarchical Prefix Sums

For computing in-string regions, we use block-level prefix sums:

1. Each block computes local prefix sum using `block.prefix_sum`
2. Last value from each block propagates to next block
3. Single-pass algorithm, minimal synchronization

### 4. Fused Kernels

Combine multiple operations in single kernel launches:

- Quote detection + escape handling
- Structural character extraction + bitmap creation
- Reduces kernel launch overhead

### 5. Minimize Memory Allocations

- Pre-allocate GPU buffers based on input size
- Reuse `DeviceContext` across operations
- Use `String(unsafe_from_utf8=bytes^)` for bulk string construction

### 6. Hybrid GPU/CPU Pipeline

- **GPU:** Parallel bitmap operations (where GPU excels)
- **CPU:** Sequential bracket matching (where CPU is sufficient)
- **Key insight:** Don't force everything on GPU; use the right tool for each step

## Performance Variance

GPU performance can vary between runs due to:

- **Cold-start overhead:** First GPU run ~200ms slower (GPU initialization)
- **Thermal throttling:** GPU frequency varies with temperature
- **Scheduling:** CUDA stream scheduling can introduce variance

**Solution:** Always measure with warm-up runs and report averages.

## Future Optimizations

Potential improvements for even better performance:

1. **GPU bracket matching:** Could eliminate CPU bottleneck (~11ms)
2. **Multi-GPU support:** For files > 1GB
3. **Streaming parser:** Process chunks as they arrive
4. **Zero-copy Value tree:** Build tree directly on GPU memory

## Benchmark Reproducibility

All benchmarks are reproducible using pinned git submodules:

```bash
# Clone with exact versions
git clone --recursive https://github.com/ehsanmok/mojson.git

# Build comparison benchmarks
pixi run build-cujson

# Run benchmarks
pixi run bench-gpu-cujson benchmark/datasets/twitter_large_record.json
```

See [benchmark/readme.md](../benchmark/readme.md) for complete setup instructions.

## Hardware Requirements

- **GPU:** NVIDIA GPU with CUDA support (tested on B200, H100, A100) or Apple Silicon
- **CUDA:** Latest CUDA toolkit (for NVIDIA)
- **Memory:** At least 2x your largest JSON file size (for GPU buffers)

## References

- [simdjson](https://github.com/simdjson/simdjson) - CPU JSON parser
- [cuJSON](https://github.com/AutomataLab/cuJSON) - GPU JSON parser (baseline comparison)
- [GPU stream compaction](https://research.nvidia.com/publication/2016-03_single-pass-parallel-prefix-scan-decoupled-look-back) - Decoupled look-back algorithm
