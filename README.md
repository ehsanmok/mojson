# mojson - High-Performance JSON for Mojo

Fast JSON parsing library for Mojo with Python-compatible API and GPU acceleration.

* **Cross-platform GPU support:** Powered by Mojo kernels that work across NVIDIA, AMD, and Apple Silicon GPUs.

* **4x** faster than cuJSON on MI355X and **2x** faster than cuJSON on B200 (see [Benchmarks](#benchmarks))

## Requirements

### System Requirements
- **Mojo/MAX SDK**: See [system requirements](https://docs.modular.com/max/packages#system-requirements) for supported platforms (Linux, macOS, Windows WSL)
- **Package Manager**: [pixi](https://pixi.prefix.dev/latest/installation/) for dependency management and task automation

### GPU Acceleration (Optional)
For GPU-accelerated parsing, you need:
- **AMD GPU**: ROCm 6+ compatible device (MI300X, MI355X, etc.)
- **NVIDIA GPU**: CUDA-compatible device (compute capability 7.0+)
- **Apple Silicon**: M-series with Metal support
- See [GPU compatibility](https://docs.modular.com/max/packages#gpu-compatibility) for full requirements

> **Note**: GPU parsing is optional. The library works fully on CPU-only systems using the simdjson backend.

## Installation

```bash
# Clone with submodules
git clone --recursive https://github.com/ehsanmok/mojson.git
cd mojson

# Install dependencies (auto-builds simdjson FFI)
pixi install

# Run tests
pixi run tests-cpu  # CPU tests
pixi run tests-gpu  # GPU tests
```

## API

### Core JSON API

Simple, Pythonic API for working with JSON values:

```mojo
from mojson import loads, dumps, load, dump

# Parse JSON strings
var data = loads('{"name": "Alice", "age": 30}')
print(data["name"].string_value())  # "Alice"
print(dumps(data))                  # {"name":"Alice","age":30}

# GPU-accelerated parsing for large files (>100MB)
var gpu_data = loads[target="gpu"](large_json_string)

# File I/O
with open("data.json", "r") as f:
    var file_data = load(f)

with open("output.json", "w") as f:
    dump(data, f)
```

### Struct Serialization (Optional)

Type-safe serialization/deserialization for your structs:

```mojo
from mojson.serialize import Serializable, serialize, to_json_value
from mojson.deserialize import Deserializable, deserialize, get_string, get_int

@fieldwise_init
struct Person(Serializable, Deserializable):
    var name: String
    var age: Int

    fn to_json(self) -> String:
        return '{"name":' + to_json_value(self.name) + ',"age":' + to_json_value(self.age) + '}'

    @staticmethod
    fn from_json(json: Value) raises -> Self:
        return Self(name=get_string(json, "name"), age=get_int(json, "age"))

# Serialize and deserialize
var person = Person(name="Alice", age=30)
var json_str = serialize(person)            # {"name":"Alice","age":30}
var restored = deserialize[Person](json_str)
print(restored.name)                        # Alice
```

**Core API Reference**

| Function | Description |
|----------|-------------|
| `loads(s)` | Parse JSON string (CPU default) |
| `loads[target="gpu"](s)` | Parse JSON string (GPU accelerated) |
| `dumps(v)` | Serialize Value to JSON string |
| `load(f)` | Parse JSON from FileHandle |
| `dump(v, f)` | Serialize Value to FileHandle |

**Struct Serialization API** (Optional)

| Function/Trait | Description |
|---------------|-------------|
| `serialize(obj)` | Serialize Serializable object to JSON string |
| `deserialize[T](s)` | Deserialize JSON string to type T |
| `Serializable` | Trait requiring `fn to_json(self) -> String` |
| `Deserializable` | Trait requiring `@staticmethod fn from_json(Value) -> Self` |

### Value Type

The `Value` struct represents any JSON value with Python-like accessors:

```mojo
# Type checking
v.is_null() / is_bool() / is_int() / is_float() / is_string() / is_array() / is_object()

# Value extraction
v.bool_value() / int_value() / float_value() / string_value()

# Array/Object access
data["key"]           # Object access
data[0]               # Array access
```


## Examples

See the `examples/` directory for complete working examples:

```bash
pixi run examples  # Run all examples
# Or run individually
pixi run mojo -I . examples/01_basic_parsing.mojo
```

| Example | Description |
|---------|-------------|
| `01_basic_parsing.mojo` | Parse JSON strings, serialize back, handle all JSON types |
| `02_file_operations.mojo` | Read/write JSON files with `load()` and `dump()` |
| `03_value_types.mojo` | Type checking (`is_*`), value extraction (`*_value()`), metadata |
| `04_gpu_parsing.mojo` | GPU-accelerated parsing with `loads[target="gpu"]()` |
| `05_error_handling.mojo` | Try/except error handling, batch processing with recovery |
| `06_struct_serde.mojo` | Struct serialization/deserialization with `Serializable`/`Deserializable` traits |

## Performance

### GPU: AMD MI355X

| Dataset | Size | Pinned Memory Path | Full `loads[target='gpu']` |
|---------|------|-------------------|---------------------------|
| **twitter.json** | 632 KB | **2.7 GB/s** (0.24 ms) | 0.35 GB/s (1.9 ms) |
| **citm_catalog.json** | 1.7 MB | **5.2 GB/s** (0.33 ms) | 0.38 GB/s (4.5 ms) |
| **twitter_large_record.json** | 804 MB | **15.0 GB/s** (56 ms) | 4.9 GB/s (172 ms) |

*Averages from 3 benchmark runs. Pinned memory path is comparable scope to cuJSON.*

### GPU: NVIDIA B200

| Parser | Time (804MB file) | Throughput | Speedup |
|--------|-------------------|------------|---------|
| cuJSON (CUDA C++) | 236 ms | 3.6 GB/s | baseline |
| **mojson GPU** | **121 ms** | **7.0 GB/s** | **2.0x faster** |

**Key optimization:** GPU stream compaction reduces D2H transfer by extracting only position indices instead of transferring all structural character data (465MB → 4MB).

#### Detailed GPU Performance (NVIDIA B200)

| Dataset | Size | Raw GPU Parse | Pinned Memory Path | Full `loads[target='gpu']` |
|---------|------|---------------|-------------------|---------------------------|
| **twitter.json** | 617 KB | 1.7 GB/s | **2.3 GB/s** | 0.23 GB/s |
| **citm_catalog.json** | 1.7 MB | 2.2 GB/s | **3.1 GB/s** | 0.19 GB/s |
| **twitter_large_record.json** | 804 MB | 3.7 GB/s | **7.0 GB/s** | 1.5 GB/s |

**Pinned memory path** = H2D + GPU kernels + stream compaction + D2H + bracket matching

### GPU: Apple Silicon (M3 Pro)

| Metric | Time | Throughput |
|--------|------|------------|
| Raw GPU parse | 270 ms | 3.1 GB/s |
| Pinned memory path | 257 ms | 3.3 GB/s |
| Full `loads[target='gpu']` | 498 ms | 1.7 GB/s |

*Benchmark: 804MB twitter_large_record.json on Apple M3 Pro GPU*

### CPU

| Dataset | Size | Throughput | Time |
|---------|------|------------|------|
| **twitter.json** | 617 KB | **1.62 GB/s** | 0.39 ms |
| **citm_catalog.json** | 1.7 MB | **1.69 GB/s** | 1.02 ms |

Uses [simdjson](https://github.com/simdjson/simdjson) via FFI for maximum compatibility and battle-tested correctness.

### When to Use GPU

- **GPU:** Large files (>100MB) - 1.85x faster than cuJSON for parser output
- **CPU:** Small files (<1MB) - simdjson is faster due to zero GPU launch overhead

## Benchmarks

```bash
# GPU benchmark (single file)
pixi run bench-gpu benchmark/datasets/twitter.json

# GPU benchmark (all datasets, 3 runs each for averaging)
pixi run bench-gpu-all

# CPU benchmark (mojson vs simdjson)
pixi run bench-cpu benchmark/datasets/twitter.json
```

**Download large benchmark files:**

```bash
# twitter_large_record.json (804MB) - primary benchmark file
pixi run download-twitter-large

# Or manually:
cd benchmark/datasets
gdown 1mdF4HT7s0Jp4XZ0nOxY7lQpcwRZzCjE1 -O twitter_large_record.json
```

See [benchmark/README.md](./benchmark/README.md) for full benchmarking methodology, reproducibility details, and dataset sources.

## Documentation

- [Architecture Overview](./docs/architecture.md) - CPU/GPU backend design, pipeline details
- [Performance Deep Dive](./docs/performance.md) - Why mojson is faster, optimization techniques
- [Examples](./examples/README.md) - Complete usage examples

## Project Structure

```
src/
  __init__.mojo          # Public API: loads, dumps, load, dump, Value
  parser.mojo            # Unified CPU/GPU parser
  value.mojo             # Value type
  serialize.mojo         # JSON serialization
  cpu/
    simdjson_ffi.mojo    # simdjson FFI bindings
    simdjson_ffi/        # C++ wrapper (auto-built)
  gpu/
    parser.mojo          # GPU parser
    kernels.mojo         # CUDA-style kernels
    stream_compact.mojo  # GPU stream compaction
examples/                # Usage examples
tests/                   # Unit tests
benchmark/               # Performance benchmarks
docs/                    # Documentation
```

## License

[MIT LICENSE](./LICENSE)
