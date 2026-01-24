# mojson - High-performance JSON library for Mojo
# Python-compatible API: loads, dumps, load, dump
#
# Usage:
#   from src import loads, dumps, load, dump, Value
#
#   # String operations
#   var data = loads('{"key": "value"}')           # CPU (default)
#   var data = loads[target="gpu"]('{"key": 1}')   # GPU
#   print(dumps(data))
#
#   # File operations
#   with open("data.json", "r") as f:
#       var data = load(f)                         # CPU (default)
#       var data = load[target="gpu"](f)           # GPU
#
#   with open("output.json", "w") as f:
#       dump(data, f)

from .value import Value, Null, make_array_value, make_object_value
from .parser import loads, load, loads_with_config
from .serialize import (
    dumps,
    dump,
    dumps_with_config,
    to_json_value,
    to_json_string,
    Serializable,
    serialize,
)
from .config import ParserConfig, SerializerConfig
from .deserialize import (
    get_string,
    get_int,
    get_bool,
    get_float,
    Deserializable,
    deserialize,
)
from .ndjson import (
    parse_ndjson,
    parse_ndjson_lazy,
    dumps_ndjson,
    NDJSONIterator,
)
from .lazy import LazyValue, loads_lazy
from .streaming import (
    StreamingParser,
    ArrayStreamingParser,
    stream_ndjson,
    stream_json_array,
)
from .patch import (
    apply_patch,
    merge_patch,
    create_merge_patch,
)
from .jsonpath import (
    jsonpath_query,
    jsonpath_one,
)
from .schema import (
    validate,
    is_valid,
    ValidationResult,
    ValidationError,
)
