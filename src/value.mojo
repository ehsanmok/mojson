# mojson - Value type for JSON values

from collections import List


struct Null(Stringable, Writable):
    """Represents JSON null."""

    fn __init__(out self):
        pass

    fn __str__(self) -> String:
        return "null"

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("null")


struct Value(Copyable, Movable, Stringable, Writable):
    """A JSON value that can hold null, bool, int, float, string, array, or object.
    """

    var _type: Int  # 0=null, 1=bool, 2=int, 3=float, 4=string, 5=array, 6=object
    var _bool: Bool
    var _int: Int64
    var _float: Float64
    var _string: String
    var _raw: String  # Raw JSON for arrays/objects
    var _keys: List[String]  # Object keys
    var _count: Int  # Array/object element count

    fn __init__(out self, null: Null):
        self._type = 0
        self._bool = False
        self._int = 0
        self._float = 0.0
        self._string = String()
        self._raw = String()
        self._keys = List[String]()
        self._count = 0

    fn __init__(out self, none: NoneType):
        self._type = 0
        self._bool = False
        self._int = 0
        self._float = 0.0
        self._string = String()
        self._raw = String()
        self._keys = List[String]()
        self._count = 0

    fn __init__(out self, b: Bool):
        self._type = 1
        self._bool = b
        self._int = 0
        self._float = 0.0
        self._string = String()
        self._raw = String()
        self._keys = List[String]()
        self._count = 0

    fn __init__(out self, i: Int):
        self._type = 2
        self._bool = False
        self._int = Int64(i)
        self._float = 0.0
        self._string = String()
        self._raw = String()
        self._keys = List[String]()
        self._count = 0

    fn __init__(out self, i: Int64):
        self._type = 2
        self._bool = False
        self._int = i
        self._float = 0.0
        self._string = String()
        self._raw = String()
        self._keys = List[String]()
        self._count = 0

    fn __init__(out self, f: Float64):
        self._type = 3
        self._bool = False
        self._int = 0
        self._float = f
        self._string = String()
        self._raw = String()
        self._keys = List[String]()
        self._count = 0

    fn __init__(out self, s: String):
        self._type = 4
        self._bool = False
        self._int = 0
        self._float = 0.0
        self._string = s
        self._raw = String()
        self._keys = List[String]()
        self._count = 0

    # Type checking
    fn is_null(self) -> Bool:
        return self._type == 0

    fn is_bool(self) -> Bool:
        return self._type == 1

    fn is_int(self) -> Bool:
        return self._type == 2

    fn is_float(self) -> Bool:
        return self._type == 3

    fn is_string(self) -> Bool:
        return self._type == 4

    fn is_array(self) -> Bool:
        return self._type == 5

    fn is_object(self) -> Bool:
        return self._type == 6

    fn is_number(self) -> Bool:
        return self._type == 2 or self._type == 3

    # Value extraction
    fn bool_value(self) -> Bool:
        return self._bool

    fn int_value(self) -> Int64:
        return self._int

    fn float_value(self) -> Float64:
        return self._float

    fn string_value(self) -> String:
        return self._string

    fn raw_json(self) -> String:
        return self._raw

    fn array_count(self) -> Int:
        return self._count

    fn object_keys(self) -> List[String]:
        return self._keys.copy()

    fn object_count(self) -> Int:
        return self._count

    # Stringable
    fn __str__(self) -> String:
        if self._type == 0:
            return "null"
        elif self._type == 1:
            return "true" if self._bool else "false"
        elif self._type == 2:
            return String(self._int)
        elif self._type == 3:
            return String(self._float)
        elif self._type == 4:
            return '"' + self._string + '"'
        elif self._type == 5 or self._type == 6:
            return self._raw
        return "unknown"

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.__str__())

    # Equality
    fn __eq__(self, other: Value) -> Bool:
        if self._type != other._type:
            return False
        if self._type == 0:
            return True
        elif self._type == 1:
            return self._bool == other._bool
        elif self._type == 2:
            return self._int == other._int
        elif self._type == 3:
            return self._float == other._float
        elif self._type == 4:
            return self._string == other._string
        elif self._type == 5 or self._type == 6:
            return self._raw == other._raw
        return False

    fn __ne__(self, other: Value) -> Bool:
        return not self.__eq__(other)
    
    fn get(self, key: String) raises -> String:
        """Get a field value from a JSON object as a string.
        
        This is a helper for deserialization. For objects, it parses
        the raw JSON to extract the field value.
        
        Args:
            key: The field name to extract
        
        Returns:
            The raw JSON value as a string
        
        Raises:
            Error if not an object or key not found
        """
        if not self.is_object():
            raise Error("get() can only be called on JSON objects")
        
        # Check if key exists
        var found = False
        for i in range(len(self._keys)):
            if self._keys[i] == key:
                found = True
                break
        
        if not found:
            raise Error("Key '" + key + "' not found in JSON object")
        
        # Parse the raw JSON to extract the value
        return _extract_field_value(self._raw, key)


fn make_array_value(raw: String, count: Int) -> Value:
    """Create an array Value from raw JSON."""
    var v = Value(Null())
    v._type = 5
    v._raw = raw
    v._count = count
    return v^


fn make_object_value(raw: String, var keys: List[String]) -> Value:
    """Create an object Value from raw JSON and keys."""
    var v = Value(Null())
    v._type = 6
    v._raw = raw
    v._count = len(keys)
    v._keys = keys^
    return v^


fn _extract_field_value(raw: String, key: String) raises -> String:
    """Extract a field's value from raw JSON object string.
    
    Args:
        raw: Raw JSON object string (e.g., '{"a": 1, "b": "hello"}')
        key: Field name to extract
    
    Returns:
        The raw JSON value as a string (e.g., '1' or '"hello"')
    """
    var raw_bytes = raw.as_bytes()
    var in_string = False
    var escaped = False
    var depth = 0
    var i = 0
    var n = len(raw_bytes)
    
    # Skip opening brace and whitespace
    while i < n and (raw_bytes[i] == ord("{") or raw_bytes[i] == ord(" ") or raw_bytes[i] == ord("\t") or raw_bytes[i] == ord("\n")):
        if raw_bytes[i] == ord("{"):
            depth = 1
        i += 1
    
    # Search for the key
    while i < n:
        # Skip whitespace
        while i < n and (raw_bytes[i] == ord(" ") or raw_bytes[i] == ord("\t") or raw_bytes[i] == ord("\n")):
            i += 1
        
        if i >= n:
            break
        
        # Check if we're at a key (starts with ")
        if raw_bytes[i] == ord('"') and not in_string:
            i += 1  # Skip opening quote
            var key_start = i
            
            # Read the key
            while i < n and raw_bytes[i] != ord('"'):
                if raw_bytes[i] == ord("\\"):
                    i += 2  # Skip escaped character
                else:
                    i += 1
            
            var found_key = raw[key_start:i]
            i += 1  # Skip closing quote
            
            # Skip whitespace and colon
            while i < n and (raw_bytes[i] == ord(" ") or raw_bytes[i] == ord("\t") or raw_bytes[i] == ord("\n") or raw_bytes[i] == ord(":")):
                i += 1
            
            # If this is our key, extract the value
            if found_key == key:
                return _extract_json_value(raw, i)
            else:
                # Skip this value
                _ = _extract_json_value(raw, i)
                # Find next comma or end
                while i < n and raw_bytes[i] != ord(",") and raw_bytes[i] != ord("}"):
                    i += 1
                if i < n and raw_bytes[i] == ord(","):
                    i += 1
        else:
            i += 1
    
    raise Error("Key not found in JSON object")


fn _extract_json_value(raw: String, start: Int) raises -> String:
    """Extract a single JSON value starting at position start."""
    var raw_bytes = raw.as_bytes()
    var i = start
    var n = len(raw_bytes)
    
    # Skip leading whitespace
    while i < n and (raw_bytes[i] == ord(" ") or raw_bytes[i] == ord("\t") or raw_bytes[i] == ord("\n")):
        i += 1
    
    if i >= n:
        raise Error("Unexpected end of JSON")
    
    var first_char = raw_bytes[i]
    
    # String value
    if first_char == ord('"'):
        var value_start = i
        i += 1
        while i < n:
            if raw_bytes[i] == ord("\\"):
                i += 2  # Skip escaped character
            elif raw_bytes[i] == ord('"'):
                return String(raw[value_start:i+1])
            else:
                i += 1
        raise Error("Unterminated string")
    
    # Object or array
    elif first_char == ord("{") or first_char == ord("["):
        var close_char = ord("}") if first_char == ord("{") else ord("]")
        var depth = 1
        var value_start = i
        i += 1
        var in_string = False
        
        while i < n and depth > 0:
            if raw_bytes[i] == ord("\\") and in_string:
                i += 2
                continue
            elif raw_bytes[i] == ord('"'):
                in_string = not in_string
            elif not in_string:
                if raw_bytes[i] == first_char:
                    depth += 1
                elif raw_bytes[i] == close_char:
                    depth -= 1
            i += 1
        
        return String(raw[value_start:i])
    
    # null, true, false, or number
    else:
        var value_start = i
        while i < n and raw_bytes[i] != ord(",") and raw_bytes[i] != ord("}") and raw_bytes[i] != ord("]") and raw_bytes[i] != ord(" ") and raw_bytes[i] != ord("\t") and raw_bytes[i] != ord("\n"):
            i += 1
        return String(raw[value_start:i])
