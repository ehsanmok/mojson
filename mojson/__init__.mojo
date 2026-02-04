"""High-performance JSON library for Mojo.

The entire API is built around 4 functions: `loads`, `dumps`, `load`, `dump`.

## loads() - Parse Strings

```mojo
from mojson import loads, ParserConfig

# Basic parsing (uses fast pure Mojo backend by default)
var data = loads('{"name": "Alice", "age": 30}')

# Use simdjson FFI backend (for compatibility)
var data = loads[target="cpu-simdjson"]('{"name": "Alice"}')

# GPU acceleration (for large files >100MB)
var data = loads[target="gpu"](large_json_string)

# With parser configuration
var config = ParserConfig(allow_comments=True, allow_trailing_comma=True)
var data = loads('{"a": 1,} // comment', config)

# NDJSON (newline-delimited JSON) -> List[Value]
var values = loads[format="ndjson"]('{"a":1}\n{"a":2}\n{"a":3}')

# Lazy parsing (parse on demand)
var lazy = loads[lazy=True](huge_json_string)
var name = lazy.get("/users/0/name")  # Only parses this path
```

## dumps() - Serialize Strings

```mojo
from mojson import dumps, SerializerConfig

# Compact output
var json = dumps(data)

# Pretty print
var pretty = dumps(data, indent="  ")

# With serializer configuration
var config = SerializerConfig(escape_unicode=True, escape_forward_slash=True)
var json = dumps(data, config)

# NDJSON output
var ndjson = dumps[format="ndjson"](list_of_values)
```

## load() - Parse Files

```mojo
from mojson import load

# Load JSON file
var data = load("config.json")

# Load NDJSON file (auto-detected from .ndjson extension)
var events = load("events.ndjson")  # Returns Value (array)

# GPU acceleration for large files
var big = load[target="gpu"]("large.json")

# Streaming (for files larger than memory, CPU only)
var parser = load[streaming=True]("huge.ndjson")
while parser.has_next():
    var item = parser.next()
    process(item)
parser.close()
```

## dump() - Write Files

```mojo
from mojson import dump

# Basic file writing
var f = open("output.json", "w")
dump(data, f)
f.close()

# Pretty print to file
var f = open("output.json", "w")
dump(data, f, indent="  ")
f.close()
```

## Feature Matrix

| Feature | CPU | GPU | Notes |
|---------|-----|-----|-------|
| `loads(s)` | default | `target="gpu"` | |
| `load(path)` | default | `target="gpu"` | Auto-detects .ndjson |
| `loads[format="ndjson"]` | default | `target="gpu"` | |
| `loads[lazy=True]` | yes | no | CPU only |
| `load[streaming=True]` | yes | no | CPU only |
| `dumps` / `dump` | yes | no | CPU only |

## Value Type

The `Value` struct represents any JSON value.

### Type Checking

```mojo
v.is_null()    # true if null
v.is_bool()    # true if boolean
v.is_int()     # true if integer
v.is_float()   # true if float
v.is_string()  # true if string
v.is_array()   # true if array
v.is_object()  # true if object
v.is_number()  # true if int or float
```

### Value Extraction

```mojo
v.bool_value()    # -> Bool
v.int_value()     # -> Int64
v.float_value()   # -> Float64
v.string_value()  # -> String
v.raw_json()      # -> String (for arrays/objects)
```

### Access & Iteration

```mojo
# Object access
var name = obj["name"]              # -> Value
var items = obj.object_items()      # -> List[Tuple[String, Value]]
var keys = obj.object_keys()        # -> List[String]

# Array access
var first = arr[0]                  # -> Value
var items = arr.array_items()       # -> List[Value]
var count = arr.array_count()       # -> Int

# JSON Pointer (RFC 6901)
var nested = data.at("/users/0/name")
```

### Mutation

```mojo
# Object mutation
obj.set("key", Value("value"))      # Add or update key
obj.set("count", Value(42))

# Array mutation
arr.set(0, Value("new first"))      # Update by index
arr.append(Value("new item"))       # Append to end
```

### Creating Values

```mojo
from mojson import Value, Null

var null_val = Value(Null())
var bool_val = Value(True)
var int_val = Value(42)
var float_val = Value(3.14)
var str_val = Value("hello")
```

## Struct Serialization

### Serializable Trait

```mojo
from mojson import Serializable, serialize, to_json_value

struct Person(Serializable):
    var name: String
    var age: Int

    fn to_json(self) -> String:
        return '{"name":' + to_json_value(self.name) +
               ',"age":' + to_json_value(self.age) + '}'

var json = serialize(Person("Alice", 30))  # {"name":"Alice","age":30}
```

### Deserializable Trait

```mojo
from mojson import Deserializable, deserialize, get_string, get_int

struct Person(Deserializable):
    var name: String
    var age: Int

    @staticmethod
    fn from_json(json: Value) raises -> Self:
        return Self(
            name=get_string(json, "name"),
            age=get_int(json, "age")
        )

var person = deserialize[Person]('{"name":"Alice","age":30}')
```

### Helper Functions

| Function | Description |
|----------|-------------|
| `to_json_value(s: String)` | Escape and quote string for JSON |
| `to_json_value(i: Int)` | Convert int to JSON |
| `to_json_value(f: Float64)` | Convert float to JSON |
| `to_json_value(b: Bool)` | Convert bool to JSON |
| `get_string(v, key)` | Extract string field |
| `get_int(v, key)` | Extract int field |
| `get_float(v, key)` | Extract float field |
| `get_bool(v, key)` | Extract bool field |

## Error Handling

Parse errors include line/column information:

```mojo
try:
    var data = loads('{"invalid": }')
except e:
    print(e)
    # JSON parse error at line 1, column 13: Invalid JSON syntax
```

## GPU Parsing

GPU parsing is recommended for files >100MB:

```mojo
# GPU accelerated (requires compatible GPU)
var data = loads[target="gpu"](large_json)

# Works on: NVIDIA (CUDA 7.0+), AMD (ROCm 6+), Apple Silicon (Metal)
```

## NDJSON (Newline-Delimited JSON)

```mojo
from mojson import loads, dumps

# Parse NDJSON string -> List[Value]
var values = loads[format="ndjson"]('{"a":1}\n{"a":2}\n{"a":3}')

# Serialize List[Value] -> NDJSON string
var ndjson = dumps[format="ndjson"](values)
```

## Lazy/On-Demand Parsing

```mojo
from mojson import loads

# Create lazy value (no parsing yet)
var lazy = loads[lazy=True](huge_json_string)

# Only parses the path to this value
var name = lazy.get("/users/0/name")
var age = lazy.get_int("/users/0/age")
```

## Streaming Parsing

For files larger than memory:

```mojo
from mojson import load

# Stream NDJSON file
var parser = load[streaming=True]("logs.ndjson")
while parser.has_next():
    var entry = parser.next()
    process(entry)
parser.close()
```

## Parser Configuration

```mojo
from mojson import loads, ParserConfig

var config = ParserConfig(
    allow_comments=True,       # Allow // and /* */
    allow_trailing_comma=True, # Allow [1, 2,]
    max_depth=100              # Limit nesting depth
)
var data = loads('{"a": 1,} // comment', config)
```

## Serializer Configuration

```mojo
from mojson import dumps, SerializerConfig

var config = SerializerConfig(
    indent="  ",               # Pretty print
    escape_unicode=True,       # Escape non-ASCII as \\uXXXX
    escape_forward_slash=True  # Escape / as \\/ (HTML safe)
)
var json = dumps(value, config)
```

## JSON Patch (RFC 6902)

```mojo
from mojson import apply_patch, loads

var doc = loads('{"name":"Alice","age":30}')
var patch = loads('[{"op":"replace","path":"/name","value":"Bob"}]')
var result = apply_patch(doc, patch)
# {"name":"Bob","age":30}
```

Supported operations: `add`, `remove`, `replace`, `move`, `copy`, `test`

## JSON Merge Patch (RFC 7396)

```mojo
from mojson import merge_patch, create_merge_patch, loads

var target = loads('{"a":1,"b":2}')
var patch = loads('{"b":null,"c":3}')  # null removes keys
var result = merge_patch(target, patch)
# {"a":1,"c":3}
```

## JSONPath Queries

```mojo
from mojson import jsonpath_query, jsonpath_one, loads

var doc = loads('{"users":[{"name":"Alice"},{"name":"Bob"}]}')
var names = jsonpath_query(doc, "$.users[*].name")
# [Value("Alice"), Value("Bob")]
```

Supported syntax: `$`, `.key`, `[n]`, `[*]`, `..`, `[start:end]`, `[?expr]`

## JSON Schema Validation

```mojo
from mojson import validate, is_valid, loads

var schema = loads('{"type":"object","required":["name"]}')
var doc = loads('{"name":"Alice"}')

if is_valid(doc, schema):
    print("Valid!")
```

Supported keywords: `type`, `enum`, `const`, `minimum/maximum`, `minLength/maxLength`,
`minItems/maxItems`, `items`, `required`, `properties`, `additionalProperties`,
`allOf`, `anyOf`, `oneOf`, `not`
"""

# Core API
from .value import Value, Null
from .parser import loads, load
from .serialize import dumps, dump
from .config import ParserConfig, SerializerConfig

# Value construction helpers
from .value import make_array_value, make_object_value

# Struct serialization
from .serialize import to_json_value, to_json_string, Serializable, serialize
from .deserialize import (
    get_string,
    get_int,
    get_bool,
    get_float,
    Deserializable,
    deserialize,
)

# Advanced features
from .patch import apply_patch, merge_patch, create_merge_patch
from .jsonpath import jsonpath_query, jsonpath_one
from .schema import validate, is_valid, ValidationResult, ValidationError

# Internal types (for advanced use)
from .lazy import LazyValue
from .streaming import StreamingParser, ArrayStreamingParser
