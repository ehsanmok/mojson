# High-Performance JSON library for Mojo🔥

- **Python-like API** — `loads`, `dumps`, `load`, `dump`
- **GPU accelerated** — 2-4x faster than cuJSON on large files
- **Cross-platform** — NVIDIA, AMD, and Apple Silicon GPUs
- **Streaming & lazy parsing** — Handle files larger than memory
- **JSONPath & Schema** — Query and validate JSON documents
- **RFC compliant** — JSON Patch, Merge Patch, JSON Pointer

## Quick Start

```bash
git clone --recursive https://github.com/user/mojson.git && cd mojson
pixi install
pixi run tests-cpu
```

```mojo
from mojson import loads, dumps, load, dump

# Parse & serialize strings
var data = loads('{"name": "Alice", "scores": [95, 87, 92]}')
print(data["name"].string_value())  # Alice
print(data["scores"][0].int_value())  # 95
print(dumps(data, indent="  "))  # Pretty print

# Read/write files
with open("data.json", "r") as f:
    var data = load(f)
with open("output.json", "w") as f:
    dump(data, f)

# GPU parsing for large files (>100MB)
var big = loads[target="gpu"](huge_json_string)
```

## Requirements

- [Mojo/MAX SDK](https://docs.modular.com/max/packages)
- [pixi](https://pixi.sh) package manager

**GPU (optional):** NVIDIA CUDA 7.0+, AMD ROCm 6+, or Apple Silicon. See [GPU requirements](https://docs.modular.com/max/packages#gpu-compatibility).

## Performance

| Platform | Throughput | vs cuJSON |
|----------|------------|-----------|
| AMD MI355X | 15 GB/s | **4x faster** |
| NVIDIA B200 | 7 GB/s | **2x faster** |
| Apple M3 Pro | 3.3 GB/s | — |
| CPU (simdjson) | 1.7 GB/s | — |

*Benchmarks on 804MB JSON file. GPU recommended for files >100MB.*

```bash
pixi run bench-gpu benchmark/datasets/twitter.json
pixi run bench-gpu-all  # All datasets, 3 runs each
```

## API

```mojo
# Parsing
loads(json_string)                  # CPU (default)
loads[target="gpu"](json_string)    # GPU
load(file_handle)                   # From file

# Serialization  
dumps(value)                        # Compact
dumps(value, indent="  ")           # Pretty print

# Value access & mutation
value["key"], value[0]              # Access by key/index
value.at("/users/0/name")           # JSON Pointer (RFC 6901)
value.set("key", val)               # Set field/element
value.append(val)                   # Append to array

# NDJSON & Streaming
parse_ndjson(s), dumps_ndjson(lst)  # Newline-delimited JSON
stream_ndjson("file.ndjson")        # Stream large files
stream_json_array("file.json")      # Stream JSON arrays

# Lazy/On-demand parsing
var lazy = loads_lazy(huge_json)
lazy.get("/users/0/name")           # Parse only what you need

# JSONPath queries
jsonpath_query(doc, "$.users[*].name")  # Get all names
jsonpath_query(doc, "$[?@.age>21]")     # Filter by condition

# JSON Schema validation
validate(doc, schema)               # Full validation result
is_valid(doc, schema)               # Quick boolean check

# JSON Patch (RFC 6902)
apply_patch(doc, patch)             # Apply patch operations
merge_patch(target, patch)          # Merge patch (RFC 7396)
```

Full API: [docs/api.md](./docs/api.md)

## Examples

```bash
pixi run mojo -I . examples/01_basic_parsing.mojo
```

| Example | Description |
|---------|-------------|
| [01_basic_parsing](./examples/01_basic_parsing.mojo) | Parse, serialize, type handling |
| [02_file_operations](./examples/02_file_operations.mojo) | Read/write JSON files |
| [03_value_types](./examples/03_value_types.mojo) | Type checking, value extraction |
| [04_gpu_parsing](./examples/04_gpu_parsing.mojo) | GPU-accelerated parsing |
| [05_error_handling](./examples/05_error_handling.mojo) | Error handling patterns |
| [06_struct_serde](./examples/06_struct_serde.mojo) | Struct serialization |

## Documentation

- [API Reference](./docs/api.md) — Complete function reference
- [Architecture](./docs/architecture.md) — CPU/GPU backend design
- [Performance](./docs/performance.md) — Optimization deep dive
- [Benchmarks](./benchmark/README.md) — Reproducible benchmarks

## License

[MIT](./LICENSE)
