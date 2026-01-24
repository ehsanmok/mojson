# API Reference

## Core Functions

### Parsing

```mojo
from mojson import loads, load

# Parse JSON string (CPU - default)
var data = loads('{"name": "Alice", "age": 30}')

# Parse JSON string (GPU - for large files >100MB)
var data = loads[target="gpu"](large_json_string)

# Parse from file
with open("data.json", "r") as f:
    var data = load(f)              # CPU
    var data = load[target="gpu"](f)  # GPU
```

### Serialization

```mojo
from mojson import dumps, dump

# Serialize to string
var json_str = dumps(data)

# Pretty print with indentation
var pretty = dumps(data, indent="  ")

# Write to file
with open("output.json", "w") as f:
    dump(data, f)
```

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

var null_val = Value(Null())        # or Value(None)
var bool_val = Value(True)
var int_val = Value(42)
var float_val = Value(3.14)
var str_val = Value("hello")
```

## Struct Serialization

For type-safe serialization of custom structs.

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
    #   Near: ..."invalid": }...
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
from mojson import parse_ndjson, parse_ndjson_lazy, dumps_ndjson

# Parse all lines at once
var values = parse_ndjson(ndjson_string)

# Lazy iteration (memory efficient)
var iter = parse_ndjson_lazy(ndjson_string)
while iter.has_next():
    var value = iter.next()

# Serialize to NDJSON
var ndjson = dumps_ndjson(values)
```

## Lazy/On-Demand Parsing

```mojo
from mojson import loads_lazy

# Create lazy value (no parsing yet)
var lazy = loads_lazy(huge_json_string)

# Only parses the path to this value
var name = lazy.get("/users/0/name")
var age = lazy.get_int("/users/0/age")

# Chain lazy access
var user = lazy["users"][0]
var parsed = user.parse()  # Full parse when needed
```

## Streaming Parsing

For files larger than memory:

```mojo
from mojson import stream_ndjson, stream_json_array

# Stream NDJSON file
var parser = stream_ndjson("logs.ndjson")
while parser.has_next():
    var entry = parser.next()
    process(entry)
parser.close()

# Stream JSON array file
var parser = stream_json_array("users.json")  # [{"name":"Alice"},...]
while parser.has_next():
    var user = parser.next()
parser.close()
```

## Parser Configuration

```mojo
from mojson import loads_with_config, ParserConfig

# Allow comments and trailing commas
var config = ParserConfig(
    allow_comments=True,      # Allow // and /* */
    allow_trailing_comma=True,  # Allow [1, 2,]
    max_depth=100             # Limit nesting depth
)
var data = loads_with_config(json_with_comments, config)

# Preset configs
var strict = ParserConfig.default()
var lenient = ParserConfig.lenient()
```

## Serializer Configuration

```mojo
from mojson import dumps_with_config, SerializerConfig

var config = SerializerConfig(
    indent="  ",              # Pretty print
    escape_unicode=True,      # Escape non-ASCII as \uXXXX
    escape_forward_slash=True # Escape / as \/ (HTML safe)
)
var json = dumps_with_config(value, config)

# Preset configs
var compact = SerializerConfig.default()
var pretty = SerializerConfig.pretty("  ")
```

## JSON Patch (RFC 6902)

```mojo
from mojson import apply_patch, loads

var doc = loads('{"name":"Alice","age":30}')
var patch = loads('[
    {"op":"replace","path":"/name","value":"Bob"},
    {"op":"add","path":"/active","value":true},
    {"op":"remove","path":"/age"}
]')

var result = apply_patch(doc, patch)
# {"name":"Bob","active":true}
```

Supported operations: `add`, `remove`, `replace`, `move`, `copy`, `test`

## JSON Merge Patch (RFC 7396)

```mojo
from mojson import merge_patch, create_merge_patch, loads

# Apply merge patch
var target = loads('{"a":1,"b":2}')
var patch = loads('{"b":null,"c":3}')  # null removes keys
var result = merge_patch(target, patch)
# {"a":1,"c":3}

# Create merge patch
var source = loads('{"a":1,"b":2}')
var target = loads('{"a":1,"c":3}')
var patch = create_merge_patch(source, target)
# {"b":null,"c":3}
```

## JSONPath Queries

```mojo
from mojson import jsonpath_query, jsonpath_one, loads

var doc = loads('{"users":[{"name":"Alice","age":30},{"name":"Bob","age":25}]}')

# Get all names
var names = jsonpath_query(doc, "$.users[*].name")
# [Value("Alice"), Value("Bob")]

# Get single value
var first = jsonpath_one(doc, "$.users[0].name")
# Value("Alice")

# Filter by condition
var young = jsonpath_query(doc, "$.users[?@.age<30]")
# [{"name":"Bob","age":25}]
```

Supported syntax: `$`, `.key`, `[n]`, `[*]`, `..`, `[start:end]`, `[?expr]`

## JSON Schema Validation

```mojo
from mojson import validate, is_valid, loads

var schema = loads('{
    "type": "object",
    "required": ["name", "age"],
    "properties": {
        "name": {"type": "string", "minLength": 1},
        "age": {"type": "integer", "minimum": 0}
    }
}')

var doc = loads('{"name":"Alice","age":30}')

# Quick check
if is_valid(doc, schema):
    print("Valid!")

# Detailed errors
var result = validate(doc, schema)
if not result.valid:
    for i in range(len(result.errors)):
        print(result.errors[i].path, ":", result.errors[i].message)
```

Supported keywords: `type`, `enum`, `const`, `minimum/maximum`, `minLength/maxLength`, 
`minItems/maxItems`, `items`, `required`, `properties`, `additionalProperties`, 
`allOf`, `anyOf`, `oneOf`, `not`

See [Performance](./performance.md) for detailed benchmarks and optimization tips.
