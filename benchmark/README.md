# mojson Benchmarks

Benchmarks comparing mojson against reference implementations.

## Setup

### 1. Install dependencies

```bash
pixi install  # Installs Mojo, simdjson, and auto-builds FFI
```

### 2. (Optional) Download cuJSON for NVIDIA GPU comparison

cuJSON is only needed if you want to compare mojson against cuJSON on NVIDIA GPUs:

```bash
cd benchmark
git clone https://github.com/AutomataLab/cuJSON.git
```

Then build it:

```bash
pixi run build-cujson
```

This builds `benchmark/cuJSON/build/cujson_benchmark`.

## Running Benchmarks

```bash
# CPU benchmark (mojson vs simdjson)
pixi run bench-cpu

# GPU benchmark (mojson only)
pixi run bench-gpu

# GPU benchmark (mojson vs cuJSON) - requires cuJSON download (see above)
pixi run bench-gpu-cujson

# With custom dataset path
pixi run bench-cpu benchmark/datasets/citm_catalog.json
pixi run bench-gpu benchmark/datasets/twitter_large_record.json
```

## Results (NVIDIA H100, 804MB twitter_large_record.json)

### GPU: mojson vs cuJSON

| Parser | Time | Throughput | Speedup |
|--------|------|------------|---------|
| cuJSON (CUDA C++) | 182 ms | 4.6 GB/s | baseline |
| **mojson GPU** | **99 ms** | **8.5 GB/s** | **1.85x** |

### CPU: mojson vs simdjson

| Parser | Time | Throughput |
|--------|------|------------|
| simdjson native | 0.14 ms | 4.3 GB/s |
| mojson CPU (FFI) | 0.18 ms | 3.5 GB/s |

## Reproducibility

### cuJSON Version

For reproducible comparisons, use commit `2ac7d3dcd7ad1ff64ebdb14022bf94c59b3b4953`:

```bash
cd benchmark
git clone https://github.com/AutomataLab/cuJSON.git
cd cuJSON && git checkout 2ac7d3dcd7ad1ff64ebdb14022bf94c59b3b4953
```

### Build Configuration

cuJSON is built with:
```bash
nvcc -O3 -w -std=c++17 -arch=sm_100 -o benchmark/cuJSON/build/cujson_benchmark \
  benchmark/cuJSON/paper_reproduced/src/cuJSON-standardjson.cu
```

Adjust `-arch=sm_XX` for your GPU (e.g., `sm_80` for A100, `sm_89` for RTX 4090).

## Datasets

### Included (small, for quick tests)

| File | Size | Source |
|------|------|--------|
| `twitter.json` | 632 KB | simdjson |
| `citm_catalog.json` | 1.6 MB | simdjson |

### Download (large, for GPU benchmarks)

Use pixi tasks (gdown is included in dev dependencies):

```bash
pixi run download-twitter-large   # 804MB - primary benchmark file
pixi run download-walmart-large   # 950MB
pixi run download-wiki-large      # 1.1GB
```

Datasets from [cuJSON Google Drive](https://drive.google.com/drive/folders/1PkDEy0zWOkVREfL7VuINI-m9wJe45P2Q).

## Benchmark Methodology

See the main [README.md](../README.md#benchmarking-methodology) for detailed methodology explaining what each benchmark measures and how mojson achieves its speedup.
