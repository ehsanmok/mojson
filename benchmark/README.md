# mojson Benchmarks

Comprehensive benchmarks comparing mojson against reference implementations (cuJSON for GPU, simdjson for CPU).

## Quick Start

```bash
# GPU benchmark (mojson vs cuJSON) - apples-to-apples comparison
pixi run bench-gpu-cujson benchmark/datasets/twitter_large_record.json

# GPU benchmark (mojson only with timing breakdown)
pixi run bench-gpu benchmark/datasets/twitter_large_record.json

# CPU benchmark (mojson vs simdjson)
pixi run bench-cpu benchmark/datasets/twitter.json
```

## Setup

### 1. Clone with Submodules

```bash
git clone --recursive https://github.com/user/mojson.git
cd mojson

# Or if already cloned:
git submodule update --init --recursive
```

### 2. Install Dependencies

```bash
pixi install  # Installs Mojo, builds simdjson FFI wrapper
```

### 3. Build cuJSON (for GPU comparison benchmarks)

```bash
pixi run build-cujson
```

This builds `benchmark/cuJSON/build/cujson_benchmark` from the pinned submodule at commit `2ac7d3dcd7ad1ff64ebdb14022bf94c59b3b4953`.

## Benchmark Results

### GPU: mojson vs cuJSON (NVIDIA B200)

**Dataset:** 804MB `twitter_large_record.json`

| Parser | Time | Throughput | Speedup |
|--------|------|------------|---------|
| cuJSON (CUDA C++) | 182 ms | 4.6 GB/s | baseline |
| **mojson GPU** | **103 ms** | **8.2 GB/s** | **1.8x** |

### CPU: mojson (simdjson FFI)

**Dataset:** 804MB `twitter_large_record.json`

| Platform | Time | Throughput |
|----------|------|------------|
| Apple M3 Pro | 530 ms | 1.5 GB/s |
| Intel Xeon 6972P | 2747 ms | 0.3 GB/s |

## Important: GPU Benchmarks Require Large Files

**GPU benchmarks are only meaningful for files >100MB.** For smaller files, GPU launch overhead dominates and results are misleading. Always use large datasets (e.g., `twitter_large_record.json`) for GPU performance evaluation.

## Note: Pixi Tasks Build Binaries Automatically

The pixi benchmark tasks automatically build binaries with `mojo build` before running (via `depends-on`). This avoids JIT compilation overhead that would skew results.

```bash
# Pixi tasks handle the build automatically
pixi run bench-gpu benchmark/datasets/twitter_large_record.json

# First run may have GPU initialization overhead - subsequent runs are faster
```

## Benchmarking Methodology

### What We Measure

mojson reports three metrics to provide a complete picture:

| Metric | What It Includes | Use Case |
|--------|------------------|----------|
| **Pinned memory path** | H2D + GPU kernels + stream compaction + D2H + bracket matching | Direct comparison with cuJSON |
| **Raw GPU parse** | Pinned path + pageable→pinned memcpy | End-to-end from file buffer |
| **Full `loads[target='gpu']`** | Everything + Value tree construction | Real-world application performance |

### Apples-to-Apples Comparison with cuJSON

[cuJSON](https://github.com/AutomataLab/cuJSON) is the state-of-the-art GPU JSON parser from the academic literature. Our benchmark uses the exact same scope as cuJSON's benchmark to ensure fair comparison.

#### What Both Benchmarks Measure

| Step | cuJSON | mojson |
|------|--------|--------|
| **Input memory** | Pinned (cudaMallocHost) | Pinned (HostBuffer) |
| **H2D transfer** | ✓ (copy to GPU) | ✓ (copy to GPU) |
| **GPU processing** | Validation + Tokenization + Parser | Quote detection + Prefix sums + Bitmap + Stream compaction |
| **Bracket matching** | GPU (Parser kernel) | CPU (stack algorithm) |
| **D2H transfer** | ✓ (465MB structural data) | ✓ (4MB position indices) |
| **Output** | Structural positions + bracket pairs | Structural positions + bracket pairs |

Both parsers produce the same output: an array of structural character positions and their corresponding bracket pair mappings. This is what's needed for downstream JSON tree construction.

#### Detailed Timing Breakdown (804MB file)

```
cuJSON (182ms total):                mojson pinned (103ms total):
├─ H2D transfer:     15.2 ms         ├─ H2D transfer:      ~15 ms
├─ Validation:        1.5 ms         ├─ GPU kernels:       ~25 ms
├─ Tokenization:      5.5 ms         │  ├─ Quote detection
├─ Parser (GPU):      1.4 ms         │  ├─ Prefix sums
└─ D2H transfer:    158.6 ms         │  └─ Structural bitmap
                                      ├─ Stream compaction: ~45 ms (GPU)
                                      ├─ D2H transfer:      ~10 ms (4MB)
                                      └─ Bracket matching:  ~10 ms (CPU)
────────────────────────────         ────────────────────────────────
Throughput: 4.6 GB/s                 Throughput: 8.2 GB/s
```

### Why mojson is Faster

The **1.8x speedup** comes primarily from **GPU stream compaction**:

- **cuJSON approach:** Transfer all structural character data back to CPU
  - Structural chars = ~58% of input = 465MB for 804MB file
  - D2H transfer time: ~160ms

- **mojson approach:** Use GPU stream compaction to extract only positions
  - Position array = ~1M positions × 4 bytes = 4MB
  - D2H transfer time: ~10ms

**Speedup:** 16x reduction in D2H transfer size → 3.2x faster D2H → 1.8x overall speedup

### What About the "Raw GPU Parse" Metric?

The "Raw GPU parse" metric (215ms, 3.9 GB/s) includes the overhead of copying from pageable memory to pinned memory:

| Metric | Time | Throughput | Notes |
|--------|------|------------|-------|
| cuJSON (from pinned) | 182 ms | 4.6 GB/s | Assumes input is already pinned |
| mojson pinned | 103 ms | 8.2 GB/s | Same assumption (fair comparison) |
| mojson raw (from pageable) | 223 ms | 3.8 GB/s | Realistic scenario with memcpy overhead |

The pageable→pinned copy takes ~120ms for 804MB. In practice, you can avoid this by:
1. Using `HostBuffer` for initial file reads
2. Memory-mapping files directly into pinned memory
3. Receiving data from network buffers already in pinned memory

### End-to-End Performance

For real applications using the full `loads[target='gpu']()` API:

| Pipeline Stage | Time (804MB) |
|----------------|--------------|
| Raw GPU parse | 223 ms |
| Value tree construction (CPU) | ~430 ms |
| **Total** | **~650 ms** |
| **Throughput** | **~1.3 GB/s** |

The Value tree construction is currently CPU-bound. This is the full application-level performance including the complete `Value` object tree in memory.

## Running Benchmarks

### GPU Benchmarks

```bash
# Compare mojson GPU vs cuJSON (recommended)
pixi run bench-gpu-cujson benchmark/datasets/twitter_large_record.json

# mojson GPU only (with detailed timing breakdown)
pixi run bench-gpu benchmark/datasets/twitter_large_record.json

# Try different datasets
pixi run bench-gpu-cujson benchmark/datasets/walmart_large_record.json
```

### CPU Benchmarks

```bash
# Compare mojson CPU vs native simdjson
pixi run bench-cpu benchmark/datasets/twitter.json

# Try different datasets
pixi run bench-cpu benchmark/datasets/citm_catalog.json
```

## Datasets

### Included (small, for quick tests)

Committed to the repository in `benchmark/datasets/`:

| File | Size | Source |
|------|------|--------|
| `twitter.json` | 632 KB | [simdjson](https://github.com/simdjson/simdjson) |
| `citm_catalog.json` | 1.6 MB | [simdjson](https://github.com/simdjson/simdjson) |

### Large Datasets (download required)

For GPU benchmarks, download large files from [cuJSON's Google Drive](https://drive.google.com/drive/folders/1PkDEy0zWOkVREfL7VuINI-m9wJe45P2Q):

Use pixi tasks (gdown is included in dev dependencies):

```bash
cd benchmark/datasets

# twitter_large_record.json (804MB) - PRIMARY BENCHMARK FILE
gdown 1mdF4HT7s0Jp4XZ0nOxY7lQpcwRZzCjE1 -O twitter_large_record.json

# walmart_large_record.json (950MB)
gdown 10vicgS7dPa4aL5PwEjqAvpAKCXYLblMt -O walmart_large_record.json

# wiki_large_record.json (1.1GB)
gdown 1bXdzhfWSdrnpg9WKOeV-oanYIT2j4yLE -O wiki_large_record.json
```

Install `gdown` if needed: `pip install gdown`

## Reproducibility

### cuJSON Version

cuJSON is pinned as a git submodule to ensure reproducible benchmarks:

```
benchmark/cuJSON @ 2ac7d3dcd7ad1ff64ebdb14022bf94c59b3b4953
Repository: https://github.com/AutomataLab/cuJSON
```

To verify the exact commit:

```bash
cd benchmark/cuJSON
git rev-parse HEAD  # Should output: 2ac7d3dcd7ad1ff64ebdb14022bf94c59b3b4953
```

### Build Configuration

cuJSON is built with:

```bash
nvcc -O3 -w -std=c++17 -arch=sm_100 -o benchmark/cuJSON/build/cujson_benchmark \
  benchmark/cuJSON/paper_reproduced/src/cuJSON-standardjson.cu
```

**Note:** Adjust `-arch=sm_XX` for your GPU:
- `sm_100` for NVIDIA B200 (Blackwell)
- `sm_90` for NVIDIA H100 (Hopper)
- `sm_80` for NVIDIA A100 (Ampere)
- `sm_89` for RTX 4090 (Ada Lovelace)

### simdjson Version

simdjson is included as a git submodule at `src/cpu/simdjson_ffi/simdjson/`. The FFI wrapper is automatically built during `pixi install`.

## Hardware Requirements

### For GPU Benchmarks
- NVIDIA GPU with CUDA support (tested on B200, H100, A100)
- CUDA toolkit (latest version)
- At least 2GB GPU memory (for 804MB benchmark)

### For CPU Benchmarks
- Any modern CPU with AVX2 or better (simdjson requirement)
- 2GB+ RAM recommended

## Benchmark Code Structure

```
benchmark/
├── mojo/
│   ├── bench_cpu.mojo          # CPU: mojson vs simdjson
│   └── bench_gpu.mojo          # GPU: mojson detailed timing
├── cuJSON/                      # cuJSON submodule (pinned version)
│   └── build/
│       └── cujson_benchmark    # Built by pixi run build-cujson
├── datasets/
│   ├── twitter.json            # Small (632KB, committed)
│   ├── citm_catalog.json       # Small (1.6MB, committed)
│   └── *.json                  # Large files (download separately)
└── README.md                    # This file
```

## Performance Tips

### For Best GPU Performance

1. **Use pinned memory:** Pre-allocate with `HostBuffer` for H2D transfers
2. **Large files only:** GPU overhead dominates for files <1MB
3. **Warm-up runs:** First GPU kernel launch has one-time initialization overhead
4. **Batch processing:** Reuse `DeviceContext` across multiple parses

### For Best CPU Performance

1. **Small files:** CPU is faster than GPU for files <1MB
2. **Memory-mapped files:** For very large files, use memory mapping
3. **Batch processing:** Parse multiple files in parallel with threading

## Troubleshooting

### "CUDA out of memory"
- Reduce file size or use CPU backend
- Close other GPU applications
- Check available GPU memory with `nvidia-smi`

### "cuJSON benchmark not found"
- Run `pixi run build-cujson` first
- Check that CUDA toolkit is installed

### "Failed to create DeviceContext"
- Verify GPU is available: `nvidia-smi`
- Check CUDA installation
- Ensure Mojo has GPU support (nightly build)

## Further Reading

- [Performance Deep Dive](../docs/performance.md) - Detailed optimization explanations
- [Architecture Overview](../docs/architecture.md) - System design and pipeline details
- [cuJSON Paper](https://arxiv.org/abs/2109.07569) - Academic reference for GPU JSON parsing
