# mojson - JSON serialization

from .value import Value


fn to_string(v: Value) -> String:
    """Convert a Value to a JSON string."""
    if v.is_null():
        return "null"
    elif v.is_bool():
        return "true" if v.bool_value() else "false"
    elif v.is_int():
        return String(v.int_value())
    elif v.is_float():
        return String(v.float_value())
    elif v.is_string():
        # Escape special characters
        var result = String('"')
        var s = v.string_value()
        var s_bytes = s.as_bytes()
        for i in range(len(s_bytes)):
            var c = s_bytes[i]
            if c == ord('"'):
                result += '\\"'
            elif c == ord("\\"):
                result += "\\\\"
            elif c == ord("\n"):
                result += "\\n"
            elif c == ord("\r"):
                result += "\\r"
            elif c == ord("\t"):
                result += "\\t"
            else:
                result += chr(Int(c))
        result += '"'
        return result^
    elif v.is_array() or v.is_object():
        return v.raw_json()
    return "null"


fn dumps(v: Value) -> String:
    """Serialize a Value to JSON string (like Python's json.dumps).

    Args:
        v: Value to serialize

    Returns:
        JSON string representation

    Example:
        var data = loads('{"name": "Alice"}')
        print(dumps(data))  # {"name": "Alice"}
    """
    return to_string(v)


fn dump(v: Value, mut f: FileHandle) raises:
    """Serialize a Value and write to file (like Python's json.dump).

    Args:
        v: Value to serialize
        f: FileHandle to write JSON to

    Example:
        var data = loads('{"name": "Alice"}')
        with open("output.json", "w") as f:
            dump(data, f)
    """
    f.write(dumps(v))


# Helper functions for building JSON strings from basic types
fn to_json_string(s: String) -> String:
    """Convert a String to JSON string format (with quotes and escaping)."""
    var result = String('"')
    var s_bytes = s.as_bytes()
    for i in range(len(s_bytes)):
        var c = s_bytes[i]
        if c == ord('"'):
            result += '\\"'
        elif c == ord("\\"):
            result += "\\\\"
        elif c == ord("\n"):
            result += "\\n"
        elif c == ord("\r"):
            result += "\\r"
        elif c == ord("\t"):
            result += "\\t"
        else:
            result += chr(Int(c))
    result += '"'
    return result^


fn to_json_value(val: String) -> String:
    """Convert String to JSON."""
    return to_json_string(val)


fn to_json_value(val: Int) -> String:
    """Convert Int to JSON."""
    return String(val)


fn to_json_value(val: Int64) -> String:
    """Convert Int64 to JSON."""
    return String(val)


fn to_json_value(val: Float64) -> String:
    """Convert Float64 to JSON."""
    return String(val)


fn to_json_value(val: Bool) -> String:
    """Convert Bool to JSON."""
    return "true" if val else "false"


trait Serializable:
    """Trait for types that can be serialized to JSON.
    
    Implement this trait to enable automatic serialization with serialize().
    
    Example:
        struct Person(Serializable):
            var name: String
            var age: Int
            
            fn to_json(self) -> String:
                return '{"name":' + to_json_value(self.name) + 
                       ',"age":' + to_json_value(self.age) + '}'
        
        var json = serialize(Person("Alice", 30))  # {"name":"Alice","age":30}
    """
    fn to_json(self) -> String:
        """Serialize this object to a JSON string."""
        ...


fn serialize[T: Serializable](obj: T) -> String:
    """Serialize an object to JSON string.
    
    The object must implement the Serializable trait with a to_json() method.
    
    Parameters:
        T: Type that implements Serializable
    
    Args:
        obj: Object to serialize
    
    Returns:
        JSON string representation
    
    Example:
        var person = Person("Alice", 30)
        var json = serialize(person)  # {"name":"Alice","age":30}
    """
    return obj.to_json()
