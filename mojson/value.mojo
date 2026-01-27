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

    fn copy(self) -> Self:
        """Create a deep copy of this Value.

        Returns a completely independent copy. Modifications to the
        copy will not affect the original.

        Returns:
            A new Value with the same content.
        """
        var v = Value(Null())
        v._type = self._type
        v._bool = self._bool
        v._int = self._int
        v._float = self._float
        v._string = self._string
        v._raw = self._raw
        v._keys = self._keys.copy()
        v._count = self._count
        return v^

    fn clone(self) -> Self:
        """Alias for copy(). Creates a deep copy of this Value.

        Returns:
            A new Value with the same content.
        """
        return self.copy()

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
            key: The field name to extract.

        Returns:
            The raw JSON value as a string.

        Raises:
            Error if not an object or key not found.
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

    fn array_items(self) raises -> List[Value]:
        """Get all items in a JSON array as a list of Values.

        Returns:
            List of Value objects representing array elements.

        Raises:
            Error if not an array.

        Example:
            var data = loads('[1, "hello", true]')
            for item in data.array_items():
                print(item).
        """
        if not self.is_array():
            raise Error("array_items() can only be called on JSON arrays")

        var result = List[Value]()
        var raw = self._raw

        if self._count == 0:
            return result^

        # Parse each element from raw JSON
        for i in range(self._count):
            var elem_str = _extract_array_element(raw, i)
            var elem = _parse_json_value_to_value(elem_str)
            result.append(elem^)

        return result^

    fn object_items(self) raises -> List[Tuple[String, Value]]:
        """Get all key-value pairs in a JSON object.

        Returns:
            List of (key, value) tuples.

        Raises:
            Error if not an object.

        Example:
            var data = loads('{"a": 1, "b": 2}')
            for pair in data.object_items():
                var key = pair[0]
                var value = pair[1]
                print(key, value).
        """
        if not self.is_object():
            raise Error("object_items() can only be called on JSON objects")

        var result = List[Tuple[String, Value]]()
        var raw = self._raw

        for i in range(len(self._keys)):
            var key = self._keys[i]
            var value_str = _extract_field_value(raw, key)
            var value = _parse_json_value_to_value(value_str)
            result.append((key, value^))

        return result^

    fn __getitem__(self, index: Int) raises -> Value:
        """Get array element by index.

        Args:
            index: Zero-based array index.

        Returns:
            The Value at the given index.

        Example:
            var arr = loads('[1, 2, 3]')
            print(arr[0])  # Prints 1.
        """
        if not self.is_array():
            raise Error("Index access requires a JSON array")
        if index < 0 or index >= self._count:
            raise Error("Array index out of bounds: " + String(index))

        var elem_str = _extract_array_element(self._raw, index)
        return _parse_json_value_to_value(elem_str)

    fn __getitem__(self, key: String) raises -> Value:
        """Get object value by key.

        Args:
            key: Object key.

        Returns:
            The Value for the given key.

        Example:
            var obj = loads('{"name": "Alice"}')
            print(obj["name"])  # Prints "Alice".
        """
        if not self.is_object():
            raise Error("Key access requires a JSON object")

        # Check if key exists
        var found = False
        for i in range(len(self._keys)):
            if self._keys[i] == key:
                found = True
                break

        if not found:
            raise Error("Key not found: " + key)

        var value_str = _extract_field_value(self._raw, key)
        return _parse_json_value_to_value(value_str)

    fn set(mut self, key: String, value: Value) raises:
        """Set or update a value in a JSON object.

        Args:
            key: Object key.
            value: New value to set.

        Example:
            var obj = loads('{"name": "Alice"}')
            obj.set("age", Value(30))
            obj.set("name", Value("Bob"))  # Update existing.
        """
        if not self.is_object():
            raise Error("set() can only be called on JSON objects")

        var value_json = _value_to_json(value)

        # Check if key exists
        var found = False
        for i in range(len(self._keys)):
            if self._keys[i] == key:
                found = True
                break

        if found:
            # Update existing key
            self._raw = _update_object_value(self._raw, key, value_json)
        else:
            # Add new key
            self._keys.append(key)
            self._count += 1
            self._raw = _add_object_key(self._raw, key, value_json)

    fn set(mut self, index: Int, value: Value) raises:
        """Set a value at an array index.

        Args:
            index: Array index (must be valid).
            value: New value to set.

        Example:
            var arr = loads('[1, 2, 3]')
            arr.set(1, Value(20))  # Result is `[1, 20, 3]`.
        """
        if not self.is_array():
            raise Error("set(index) can only be called on JSON arrays")
        if index < 0 or index >= self._count:
            raise Error("Array index out of bounds: " + String(index))

        var value_json = _value_to_json(value)
        self._raw = _update_array_element(self._raw, index, value_json)

    fn append(mut self, value: Value) raises:
        """Append a value to a JSON array.

        Args:
            value: Value to append.

        Example:
            var arr = loads('[1, 2]')
            arr.append(Value(3))  # Result is `[1, 2, 3]`.
        """
        if not self.is_array():
            raise Error("append() can only be called on JSON arrays")

        var value_json = _value_to_json(value)
        self._count += 1
        self._raw = _append_to_array(self._raw, value_json)

    fn at(self, pointer: String) raises -> Value:
        """Navigate to a value using JSON Pointer (RFC 6901).

        JSON Pointer syntax:
            "" (empty) = the whole document.
            "/foo" = member "foo" of object.
            "/foo/0" = first element of array "foo".
            "/a~1b" = member "a/b" (/ escaped as ~1).
            "/m~0n" = member "m~n" (~ escaped as ~0).

        Args:
            pointer: JSON Pointer string (e.g., "/users/0/name").

        Returns:
            The Value at the pointer location.

        Raises:
            Error if pointer is invalid or path doesn't exist.

        Example:
            var data = loads('{"users":[{"name":"Alice"}]}')
            var name = data.at("/users/0/name")  # `Value("Alice")`.
        """
        # Empty pointer = whole document
        if pointer == "":
            return self.copy()

        # Must start with /
        if not pointer.startswith("/"):
            raise Error("JSON Pointer must start with '/' or be empty")

        # Parse pointer into tokens
        var tokens = _parse_json_pointer(pointer)

        # Navigate through the value
        return _navigate_pointer(self, tokens)


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
        raw: Raw JSON object string (e.g., '{"a": 1, "b": "hello"}').
        key: Field name to extract.

    Returns:
        The raw JSON value as a string (e.g., '1' or '"hello"').
    """
    var raw_bytes = raw.as_bytes()
    var in_string = False
    var i = 0
    var n = len(raw_bytes)

    # Skip opening brace and whitespace
    while i < n and (
        raw_bytes[i] == ord("{")
        or raw_bytes[i] == ord(" ")
        or raw_bytes[i] == ord("\t")
        or raw_bytes[i] == ord("\n")
    ):
        i += 1

    # Search for the key
    while i < n:
        # Skip whitespace
        while i < n and (
            raw_bytes[i] == ord(" ")
            or raw_bytes[i] == ord("\t")
            or raw_bytes[i] == ord("\n")
        ):
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
            while i < n and (
                raw_bytes[i] == ord(" ")
                or raw_bytes[i] == ord("\t")
                or raw_bytes[i] == ord("\n")
                or raw_bytes[i] == ord(":")
            ):
                i += 1

            # If this is our key, extract the value
            if found_key == key:
                return _extract_json_value(raw, i)
            else:
                # Skip this value
                _ = _extract_json_value(raw, i)
                # Find next comma or end
                while (
                    i < n
                    and raw_bytes[i] != ord(",")
                    and raw_bytes[i] != ord("}")
                ):
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
    while i < n and (
        raw_bytes[i] == ord(" ")
        or raw_bytes[i] == ord("\t")
        or raw_bytes[i] == ord("\n")
    ):
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
                return String(raw[value_start : i + 1])
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
        while (
            i < n
            and raw_bytes[i] != ord(",")
            and raw_bytes[i] != ord("}")
            and raw_bytes[i] != ord("]")
            and raw_bytes[i] != ord(" ")
            and raw_bytes[i] != ord("\t")
            and raw_bytes[i] != ord("\n")
        ):
            i += 1
        return String(raw[value_start:i])


fn _parse_json_pointer(pointer: String) raises -> List[String]:
    """Parse a JSON Pointer string into tokens.

    Handles RFC 6901 escape sequences:
        ~0 -> ~.
        ~1 -> /.
    """
    var tokens = List[String]()
    var pointer_bytes = pointer.as_bytes()
    var n = len(pointer_bytes)
    var i = 1  # Skip leading /

    while i < n:
        var token = String()
        while i < n and pointer_bytes[i] != ord("/"):
            if pointer_bytes[i] == ord("~"):
                if i + 1 < n:
                    if pointer_bytes[i + 1] == ord("0"):
                        token += "~"
                        i += 2
                        continue
                    elif pointer_bytes[i + 1] == ord("1"):
                        token += "/"
                        i += 2
                        continue
                raise Error("Invalid escape sequence in JSON Pointer")
            token += chr(Int(pointer_bytes[i]))
            i += 1
        tokens.append(token^)
        i += 1  # Skip /

    return tokens^


fn _navigate_pointer(v: Value, tokens: List[String]) raises -> Value:
    """Navigate through a Value using parsed pointer tokens."""
    if len(tokens) == 0:
        return v.copy()

    var current_raw = v.raw_json() if v.is_array() or v.is_object() else ""
    var token = tokens[0]

    if v.is_object():
        # Navigate to object member
        var value_str = _extract_field_value(current_raw, token)
        var child = _parse_json_value_to_value(value_str)

        if len(tokens) == 1:
            return child^

        # Continue navigation
        var remaining = List[String]()
        for i in range(1, len(tokens)):
            remaining.append(tokens[i])
        return _navigate_pointer(child, remaining^)

    elif v.is_array():
        # Navigate to array element by index
        var index: Int
        try:
            index = atol(token)
        except:
            raise Error("Array index must be a number: " + token)

        if index < 0:
            raise Error("Array index cannot be negative: " + token)

        var value_str = _extract_array_element(current_raw, index)
        var child = _parse_json_value_to_value(value_str)

        if len(tokens) == 1:
            return child^

        # Continue navigation
        var remaining = List[String]()
        for i in range(1, len(tokens)):
            remaining.append(tokens[i])
        return _navigate_pointer(child, remaining^)

    else:
        raise Error(
            "Cannot navigate into primitive value with pointer: /" + token
        )


fn _extract_array_element(raw: String, index: Int) raises -> String:
    """Extract an array element by index from raw JSON array string."""
    var raw_bytes = raw.as_bytes()
    var n = len(raw_bytes)
    var i = 0
    var current_index = 0
    var depth = 0

    # Skip opening bracket and whitespace
    while i < n and (
        raw_bytes[i] == ord("[")
        or raw_bytes[i] == ord(" ")
        or raw_bytes[i] == ord("\t")
        or raw_bytes[i] == ord("\n")
        or raw_bytes[i] == ord("\r")
    ):
        if raw_bytes[i] == ord("["):
            depth = 1
        i += 1

    if depth == 0:
        raise Error("Invalid JSON array")

    # Find the element at index
    while i < n:
        # Skip whitespace
        while i < n and (
            raw_bytes[i] == ord(" ")
            or raw_bytes[i] == ord("\t")
            or raw_bytes[i] == ord("\n")
            or raw_bytes[i] == ord("\r")
        ):
            i += 1

        if i >= n:
            break

        # Check for empty array or end
        if raw_bytes[i] == ord("]"):
            break

        # If this is the index we want, extract the value
        if current_index == index:
            return _extract_json_value(raw, i)

        # Skip this element
        _ = _extract_json_value(raw, i)

        # Find the end of this value and skip to next
        var element_depth = 0
        var in_string = False
        var escaped = False

        while i < n:
            var c = raw_bytes[i]
            if escaped:
                escaped = False
                i += 1
                continue
            if c == ord("\\") and in_string:
                escaped = True
                i += 1
                continue
            if c == ord('"'):
                in_string = not in_string
                i += 1
                continue
            if in_string:
                i += 1
                continue
            if c == ord("[") or c == ord("{"):
                element_depth += 1
            elif c == ord("]") or c == ord("}"):
                if element_depth > 0:
                    element_depth -= 1
                else:
                    # End of array
                    break
            elif c == ord(",") and element_depth == 0:
                i += 1  # Skip comma
                current_index += 1
                break
            i += 1

        if i >= n or raw_bytes[i] == ord("]"):
            break

    raise Error("Array index out of bounds: " + String(index))


fn _parse_json_value_to_value(json_str: String) raises -> Value:
    """Parse a raw JSON value string into a Value."""
    var s = json_str
    var s_bytes = s.as_bytes()
    var n = len(s_bytes)

    if n == 0:
        raise Error("Empty JSON value")

    # Skip leading whitespace
    var i = 0
    while i < n and (
        s_bytes[i] == ord(" ")
        or s_bytes[i] == ord("\t")
        or s_bytes[i] == ord("\n")
        or s_bytes[i] == ord("\r")
    ):
        i += 1

    if i >= n:
        raise Error("Empty JSON value")

    var first_char = s_bytes[i]

    # null
    if first_char == ord("n"):
        return Value(Null())

    # true
    if first_char == ord("t"):
        return Value(True)

    # false
    if first_char == ord("f"):
        return Value(False)

    # string
    if first_char == ord('"'):
        # Find end of string
        var start_idx = i + 1
        var end_idx = start_idx
        var has_escapes = False
        while end_idx < n:
            var c = s_bytes[end_idx]
            if c == ord("\\"):
                has_escapes = True
                end_idx += 2  # Skip escape sequence
                continue
            if c == ord('"'):
                break
            end_idx += 1

        # Fast path: no escapes
        if not has_escapes:
            return Value(String(s[start_idx:end_idx]))

        # Slow path: handle escapes including \uXXXX
        from .unicode import unescape_json_string

        var bytes_list = List[UInt8](capacity=n)
        for j in range(n):
            bytes_list.append(s_bytes[j])
        var unescaped = unescape_json_string(bytes_list, start_idx, end_idx)
        return Value(String(unsafe_from_utf8=unescaped^))

    # number
    if first_char == ord("-") or (
        first_char >= ord("0") and first_char <= ord("9")
    ):
        var num_str = String()
        var is_float = False
        while i < n:
            var c = s_bytes[i]
            if (
                c == ord("-")
                or c == ord("+")
                or (c >= ord("0") and c <= ord("9"))
            ):
                num_str += chr(Int(c))
            elif c == ord(".") or c == ord("e") or c == ord("E"):
                num_str += chr(Int(c))
                is_float = True
            else:
                break
            i += 1
        if is_float:
            return Value(atof(num_str))
        else:
            return Value(atol(num_str))

    # array
    if first_char == ord("["):
        var count = _count_array_elements(s)
        return make_array_value(s, count)

    # object
    if first_char == ord("{"):
        var keys = _extract_object_keys(s)
        return make_object_value(s, keys^)

    raise Error("Invalid JSON value: " + s)


fn _count_array_elements(raw: String) -> Int:
    """Count elements in a JSON array."""
    var raw_bytes = raw.as_bytes()
    var n = len(raw_bytes)
    var count = 0
    var depth = 0
    var in_string = False
    var escaped = False

    for i in range(n):
        var c = raw_bytes[i]
        if escaped:
            escaped = False
            continue
        if c == ord("\\"):
            escaped = True
            continue
        if c == ord('"'):
            in_string = not in_string
            continue
        if in_string:
            continue
        if c == ord("[") or c == ord("{"):
            depth += 1
        elif c == ord("]") or c == ord("}"):
            depth -= 1
        elif c == ord(",") and depth == 1:
            count += 1

    # If array has content, add 1 for the last element
    # Check if array is not empty
    var has_content = False
    depth = 0
    in_string = False
    for i in range(n):
        var c = raw_bytes[i]
        if c == ord("["):
            depth += 1
        elif c == ord("]"):
            depth -= 1
        elif c == ord('"'):
            if depth == 1 and not in_string:
                # Starting a string at depth 1 means content exists
                has_content = True
            in_string = not in_string
        elif (
            depth == 1
            and not in_string
            and c != ord(" ")
            and c != ord("\t")
            and c != ord("\n")
            and c != ord("\r")
        ):
            has_content = True

    if has_content:
        count += 1

    return count


fn _extract_object_keys(raw: String) -> List[String]:
    """Extract all keys from a JSON object."""
    var keys = List[String]()
    var raw_bytes = raw.as_bytes()
    var n = len(raw_bytes)
    var depth = 0
    var in_string = False
    var escaped = False
    var key_start = -1
    var expect_key = True

    for i in range(n):
        var c = raw_bytes[i]
        if escaped:
            escaped = False
            continue
        if c == ord("\\"):
            escaped = True
            continue
        if c == ord('"'):
            if not in_string:
                in_string = True
                if depth == 1 and expect_key:
                    key_start = i + 1
            else:
                in_string = False
                if key_start >= 0 and depth == 1:
                    _ = i - key_start  # key_len computed for reference
                    keys.append(String(raw[key_start:i]))
                    key_start = -1
            continue
        if in_string:
            continue
        if c == ord("{") or c == ord("["):
            depth += 1
        elif c == ord("}") or c == ord("]"):
            depth -= 1
        elif c == ord(":") and depth == 1:
            expect_key = False
        elif c == ord(",") and depth == 1:
            expect_key = True

    return keys^


fn _value_to_json(v: Value) -> String:
    """Convert a Value to its JSON string representation."""
    if v.is_null():
        return "null"
    elif v.is_bool():
        return "true" if v.bool_value() else "false"
    elif v.is_int():
        return String(v.int_value())
    elif v.is_float():
        return String(v.float_value())
    elif v.is_string():
        # Need to escape the string
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


fn _update_object_value(raw: String, key: String, new_value: String) -> String:
    """Update a value in a JSON object."""
    var raw_bytes = raw.as_bytes()
    var n = len(raw_bytes)
    var i = 0

    # Skip opening brace
    while i < n and raw_bytes[i] != ord("{"):
        i += 1
    i += 1
    var depth = 1

    while i < n:
        while i < n and (
            raw_bytes[i] == ord(" ")
            or raw_bytes[i] == ord("\t")
            or raw_bytes[i] == ord("\n")
        ):
            i += 1

        if i >= n:
            break

        # Look for key
        if raw_bytes[i] == ord('"') and depth == 1:
            var key_start = i + 1
            i += 1
            while i < n and raw_bytes[i] != ord('"'):
                if raw_bytes[i] == ord("\\"):
                    i += 2
                else:
                    i += 1

            var found_key = raw[key_start:i]
            i += 1  # Skip closing quote

            # Skip to colon
            while i < n and raw_bytes[i] != ord(":"):
                i += 1
            i += 1  # Skip colon

            # Skip whitespace
            while i < n and (
                raw_bytes[i] == ord(" ")
                or raw_bytes[i] == ord("\t")
                or raw_bytes[i] == ord("\n")
            ):
                i += 1

            if found_key == key:
                # Found the key, replace its value
                var value_start = i
                # Find end of value
                var value_end = _find_value_end_str(raw, i)
                # Build new string
                return raw[:value_start] + new_value + raw[value_end:]

        i += 1

    return raw  # Key not found, return unchanged


fn _find_value_end_str(raw: String, start: Int) -> Int:
    """Find the end of a JSON value starting at start."""
    var raw_bytes = raw.as_bytes()
    var n = len(raw_bytes)
    var i = start
    var depth = 0
    var in_string = False
    var escaped = False

    while i < n:
        var c = raw_bytes[i]

        if escaped:
            escaped = False
            i += 1
            continue

        if c == ord("\\") and in_string:
            escaped = True
            i += 1
            continue

        if c == ord('"'):
            in_string = not in_string
            i += 1
            continue

        if in_string:
            i += 1
            continue

        if c == ord("{") or c == ord("["):
            depth += 1
        elif c == ord("}") or c == ord("]"):
            if depth > 0:
                depth -= 1
            else:
                return i
        elif c == ord(",") and depth == 0:
            return i

        i += 1

    return i


fn _add_object_key(raw: String, key: String, value: String) -> String:
    """Add a new key-value pair to a JSON object."""
    var raw_bytes = raw.as_bytes()
    var n = len(raw_bytes)

    # Find the closing brace
    var close_pos = n - 1
    while close_pos >= 0 and raw_bytes[close_pos] != ord("}"):
        close_pos -= 1

    if close_pos < 0:
        return raw  # Invalid object

    # Check if object is empty (just {})
    var is_empty = True
    for i in range(1, close_pos):
        var c = raw_bytes[i]
        if (
            c != ord(" ")
            and c != ord("\t")
            and c != ord("\n")
            and c != ord("\r")
        ):
            is_empty = False
            break

    if is_empty:
        return '{"' + key + '":' + value + "}"
    else:
        return raw[:close_pos] + ',"' + key + '":' + value + "}"


fn _update_array_element(raw: String, index: Int, new_value: String) -> String:
    """Update an element in a JSON array."""
    var raw_bytes = raw.as_bytes()
    var n = len(raw_bytes)
    var current_index = 0
    var i = 0

    # Skip opening bracket
    while i < n and raw_bytes[i] != ord("["):
        i += 1
    i += 1

    # Skip whitespace
    while i < n and (
        raw_bytes[i] == ord(" ")
        or raw_bytes[i] == ord("\t")
        or raw_bytes[i] == ord("\n")
        or raw_bytes[i] == ord("\r")
    ):
        i += 1

    while i < n:
        if current_index == index:
            # Found the element to replace
            var value_start = i
            var value_end = _find_value_end_str(raw, i)
            return raw[:value_start] + new_value + raw[value_end:]

        # Skip this element
        var elem_end = _find_value_end_str(raw, i)
        i = elem_end

        # Skip comma and whitespace
        while i < n and (
            raw_bytes[i] == ord(",")
            or raw_bytes[i] == ord(" ")
            or raw_bytes[i] == ord("\t")
            or raw_bytes[i] == ord("\n")
            or raw_bytes[i] == ord("\r")
        ):
            if raw_bytes[i] == ord(","):
                current_index += 1
            i += 1

        if i >= n or raw_bytes[i] == ord("]"):
            break

    return raw  # Index not found


fn _append_to_array(raw: String, value: String) -> String:
    """Append a value to a JSON array."""
    var raw_bytes = raw.as_bytes()
    var n = len(raw_bytes)

    # Find the closing bracket
    var close_pos = n - 1
    while close_pos >= 0 and raw_bytes[close_pos] != ord("]"):
        close_pos -= 1

    if close_pos < 0:
        return raw  # Invalid array

    # Check if array is empty (just [])
    var is_empty = True
    for i in range(1, close_pos):
        var c = raw_bytes[i]
        if (
            c != ord(" ")
            and c != ord("\t")
            and c != ord("\n")
            and c != ord("\r")
        ):
            is_empty = False
            break

    if is_empty:
        return "[" + value + "]"
    else:
        return raw[:close_pos] + "," + value + "]"
