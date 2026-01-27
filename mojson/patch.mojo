# mojson - JSON Patch (RFC 6902) and JSON Merge Patch (RFC 7396)
#
# JSON Patch: Apply a sequence of operations to a JSON document
# JSON Merge Patch: Merge two JSON documents together

from collections import List
from .value import Value, Null, _parse_json_value_to_value
from .parser import loads
from .serialize import dumps


# =============================================================================
# JSON Patch (RFC 6902)
# =============================================================================


fn apply_patch(document: Value, patch: Value) raises -> Value:
    """Apply a JSON Patch (RFC 6902) to a document.

    The patch is a JSON array of operations. Each operation has:
    - "op": The operation ("add", "remove", "replace", "move", "copy", "test")
    - "path": JSON Pointer to the target location
    - "value": The value (for add, replace, test)
    - "from": Source path (for move, copy)

    Args:
        document: The original JSON document.
        patch: Array of patch operations.

    Returns:
        New document with patches applied.

    Example:
        var doc = loads('{"name":"Alice"}')
        var patch = loads('[{"op":"add","path":"/age","value":30}]')
        var result = apply_patch(doc, patch)
        Result is `{"name":"Alice","age":30}`.
    """
    if not patch.is_array():
        raise Error("JSON Patch must be an array")

    var result = document.copy()
    var ops = patch.array_items()

    for i in range(len(ops)):
        var op = ops[i].copy()
        result = _apply_operation(result, op)

    return result^


fn _apply_operation(document: Value, operation: Value) raises -> Value:
    """Apply a single patch operation."""
    if not operation.is_object():
        raise Error("Patch operation must be an object")

    var op_type = operation["op"].string_value()
    var path = operation["path"].string_value()

    if op_type == "add":
        var value = operation["value"].copy()
        return _patch_add(document, path, value)
    elif op_type == "remove":
        return _patch_remove(document, path)
    elif op_type == "replace":
        var value = operation["value"].copy()
        return _patch_replace(document, path, value)
    elif op_type == "move":
        var from_path = operation["from"].string_value()
        return _patch_move(document, from_path, path)
    elif op_type == "copy":
        var from_path = operation["from"].string_value()
        return _patch_copy(document, from_path, path)
    elif op_type == "test":
        var value = operation["value"].copy()
        _patch_test(document, path, value)
        return document.copy()
    else:
        raise Error("Unknown patch operation: " + op_type)


fn _patch_add(document: Value, path: String, value: Value) raises -> Value:
    """Add a value at the specified path."""
    if path == "":
        return value.copy()

    var result = document.copy()
    var parent_path = _get_parent_path(path)
    var key = _get_last_token(path)

    if parent_path == "":
        # Adding to root
        if result.is_object():
            result.set(key, value)
        elif result.is_array():
            var idx = _parse_array_index(key, result.array_count() + 1)
            if key == "-" or idx == result.array_count():
                result.append(value)
            else:
                result = _array_insert(result, idx, value)
        else:
            raise Error("Cannot add to primitive value")
    else:
        var parent = result.at(parent_path)
        if parent.is_object():
            parent.set(key, value)
            result = _set_at_path(result, parent_path, parent)
        elif parent.is_array():
            var idx = _parse_array_index(key, parent.array_count() + 1)
            if key == "-" or idx == parent.array_count():
                parent.append(value)
            else:
                parent = _array_insert(parent, idx, value)
            result = _set_at_path(result, parent_path, parent)
        else:
            raise Error("Cannot add to primitive value")

    return result^


fn _patch_remove(document: Value, path: String) raises -> Value:
    """Remove the value at the specified path."""
    if path == "":
        raise Error("Cannot remove root document")

    var result = document.copy()
    var parent_path = _get_parent_path(path)
    var key = _get_last_token(path)

    if parent_path == "":
        if result.is_object():
            result = _remove_object_key(result, key)
        elif result.is_array():
            var idx = _parse_array_index(key, result.array_count())
            result = _array_remove(result, idx)
        else:
            raise Error("Cannot remove from primitive value")
    else:
        var parent = result.at(parent_path)
        if parent.is_object():
            parent = _remove_object_key(parent, key)
            result = _set_at_path(result, parent_path, parent)
        elif parent.is_array():
            var idx = _parse_array_index(key, parent.array_count())
            parent = _array_remove(parent, idx)
            result = _set_at_path(result, parent_path, parent)
        else:
            raise Error("Cannot remove from primitive value")

    return result^


fn _patch_replace(document: Value, path: String, value: Value) raises -> Value:
    """Replace the value at the specified path."""
    if path == "":
        return value.copy()

    # Verify path exists
    _ = document.at(path)

    return _set_at_path(document.copy(), path, value)


fn _patch_move(
    document: Value, from_path: String, to_path: String
) raises -> Value:
    """Move a value from one path to another."""
    var value = document.at(from_path).copy()
    var temp = _patch_remove(document, from_path)
    return _patch_add(temp, to_path, value)


fn _patch_copy(
    document: Value, from_path: String, to_path: String
) raises -> Value:
    """Copy a value from one path to another."""
    var value = document.at(from_path).copy()
    return _patch_add(document, to_path, value)


fn _patch_test(document: Value, path: String, value: Value) raises:
    """Test that a value at the path equals the expected value."""
    var actual = document.at(path)
    if not _values_equal(actual, value):
        raise Error("Test failed: value at " + path + " does not match")


# =============================================================================
# JSON Merge Patch (RFC 7396)
# =============================================================================


fn merge_patch(target: Value, patch: Value) raises -> Value:
    """Apply a JSON Merge Patch (RFC 7396) to a document.

    Merge patch rules:
    - If patch is not an object, it replaces target entirely
    - null values in patch remove keys from target
    - Other values are recursively merged

    Args:
        target: The original document.
        patch: The merge patch to apply.

    Returns:
        New document with merge patch applied.

    Example:
        var target = loads('{"a":1,"b":2}')
        var patch = loads('{"b":null,"c":3}')
        var result = merge_patch(target, patch)
        Result is `{"a":1,"c":3}`.
    """
    if not patch.is_object():
        return patch.copy()

    var result: Value
    if target.is_object():
        result = target.copy()
    else:
        result = loads("{}")

    var patch_items = patch.object_items()
    for i in range(len(patch_items)):
        var item = patch_items[i]
        var key = item[0]
        var value = item[1].copy()

        if value.is_null():
            # Remove the key
            result = _remove_object_key(result, key)
        else:
            # Recursively merge
            var target_value: Value
            try:
                target_value = result[key].copy()
            except:
                target_value = Value(Null())

            var merged = merge_patch(target_value, value)
            result.set(key, merged)

    return result^


fn create_merge_patch(source: Value, target: Value) raises -> Value:
    """Create a merge patch that transforms source into target.

    Args:
        source: The original document.
        target: The desired result.

    Returns:
        A merge patch that when applied to source produces target.

    Example:
        var source = loads('{"a":1,"b":2}')
        var target = loads('{"a":1,"c":3}')
        var patch = create_merge_patch(source, target)
        Result is `{"b":null,"c":3}`.
    """
    if not target.is_object():
        return target.copy()

    if not source.is_object():
        return target.copy()

    var patch = loads("{}")

    # Find removed and changed keys
    var source_items = source.object_items()
    for i in range(len(source_items)):
        var item = source_items[i]
        var key = item[0]
        var source_val = item[1].copy()

        var target_has_key = False
        var target_val: Value
        try:
            target_val = target[key].copy()
            target_has_key = True
        except:
            target_val = Value(Null())

        if not target_has_key:
            # Key was removed
            patch.set(key, Value(Null()))
        elif not _values_equal(source_val, target_val):
            # Key was changed
            if source_val.is_object() and target_val.is_object():
                var sub_patch = create_merge_patch(source_val, target_val)
                patch.set(key, sub_patch)
            else:
                patch.set(key, target_val)

    # Find added keys
    var target_items = target.object_items()
    for i in range(len(target_items)):
        var item = target_items[i]
        var key = item[0]
        var target_val = item[1].copy()

        var source_has_key = False
        try:
            _ = source[key]
            source_has_key = True
        except:
            pass

        if not source_has_key:
            patch.set(key, target_val)

    return patch^


# =============================================================================
# Helper Functions
# =============================================================================


fn _get_parent_path(path: String) -> String:
    """Get the parent path (everything before the last /)."""
    var last_slash = -1
    var path_bytes = path.as_bytes()
    for i in range(len(path_bytes)):
        if path_bytes[i] == ord("/"):
            last_slash = i

    if last_slash <= 0:
        return ""
    return String(path[:last_slash])


fn _get_last_token(path: String) -> String:
    """Get the last token from a JSON Pointer path."""
    var last_slash = -1
    var path_bytes = path.as_bytes()
    for i in range(len(path_bytes)):
        if path_bytes[i] == ord("/"):
            last_slash = i

    if last_slash < 0:
        return path

    var token = String(path[last_slash + 1 :])
    # Unescape ~1 and ~0
    token = _unescape_pointer_token(token)
    return token^


fn _unescape_pointer_token(token: String) -> String:
    """Unescape JSON Pointer token (~1 -> /, ~0 -> ~)."""
    var result = String()
    var token_bytes = token.as_bytes()
    var i = 0
    while i < len(token_bytes):
        if token_bytes[i] == ord("~") and i + 1 < len(token_bytes):
            if token_bytes[i + 1] == ord("1"):
                result += "/"
                i += 2
                continue
            elif token_bytes[i + 1] == ord("0"):
                result += "~"
                i += 2
                continue
        result += chr(Int(token_bytes[i]))
        i += 1
    return result^


fn _parse_array_index(token: String, max_index: Int) raises -> Int:
    """Parse an array index from a JSON Pointer token."""
    if token == "-":
        return max_index

    var idx: Int
    try:
        idx = atol(token)
    except:
        raise Error("Invalid array index: " + token)

    if idx < 0 or idx > max_index:
        raise Error("Array index out of bounds: " + token)

    return idx


fn _set_at_path(document: Value, path: String, value: Value) raises -> Value:
    """Set a value at the given JSON Pointer path."""
    if path == "":
        return value.copy()

    var result = document.copy()
    var tokens = _parse_path_tokens(path)

    # Navigate to parent and set
    if len(tokens) == 1:
        # Direct child of root
        var token = tokens[0]
        if result.is_object():
            result.set(token, value)
        elif result.is_array():
            var idx = _parse_array_index(token, result.array_count())
            result.set(idx, value)
    else:
        # Need to rebuild the path
        result = _set_nested(result, tokens, 0, value)

    return result^


fn _set_nested(
    document: Value, tokens: List[String], idx: Int, value: Value
) raises -> Value:
    """Recursively set a nested value."""
    if idx >= len(tokens):
        return value.copy()

    var token = tokens[idx]
    var result = document.copy()

    if idx == len(tokens) - 1:
        # Last token - set the value
        if result.is_object():
            result.set(token, value)
        elif result.is_array():
            var arr_idx = _parse_array_index(token, result.array_count())
            result.set(arr_idx, value)
        return result^

    # Not last token - recurse
    if result.is_object():
        var child = result[token].copy()
        var new_child = _set_nested(child, tokens, idx + 1, value)
        result.set(token, new_child)
    elif result.is_array():
        var arr_idx = _parse_array_index(token, result.array_count())
        var child = result[arr_idx].copy()
        var new_child = _set_nested(child, tokens, idx + 1, value)
        result.set(arr_idx, new_child)

    return result^


fn _parse_path_tokens(path: String) -> List[String]:
    """Parse a JSON Pointer path into tokens."""
    var tokens = List[String]()
    if path == "":
        return tokens^

    var path_bytes = path.as_bytes()
    var start = 1  # Skip leading /

    for i in range(1, len(path_bytes) + 1):
        if i == len(path_bytes) or path_bytes[i] == ord("/"):
            var token = String(path[start:i])
            tokens.append(_unescape_pointer_token(token))
            start = i + 1

    return tokens^


fn _remove_object_key(obj: Value, key: String) raises -> Value:
    """Remove a key from an object."""
    if not obj.is_object():
        raise Error("Cannot remove key from non-object")

    var items = obj.object_items()
    var json = "{"
    var first = True

    for i in range(len(items)):
        var item = items[i]
        if item[0] != key:
            if not first:
                json += ","
            json += '"' + item[0] + '":'
            json += dumps(item[1])
            first = False

    json += "}"
    return loads(json)


fn _array_insert(arr: Value, idx: Int, value: Value) raises -> Value:
    """Insert a value into an array at the given index."""
    if not arr.is_array():
        raise Error("Cannot insert into non-array")

    var items = arr.array_items()
    var json = "["

    for i in range(len(items) + 1):
        if i > 0:
            json += ","
        if i == idx:
            json += dumps(value)
            if i < len(items):
                json += ","
                json += dumps(items[i])
        elif i < len(items):
            var actual_idx = i
            if i > idx:
                actual_idx = i
            if actual_idx < len(items):
                json += dumps(items[actual_idx])

    # Fix: simpler implementation
    json = "["
    for i in range(len(items) + 1):
        if i > 0:
            json += ","
        if i == idx:
            json += dumps(value)
        elif i < idx:
            json += dumps(items[i])
        else:  # i > idx
            json += dumps(items[i - 1])

    json += "]"
    return loads(json)


fn _array_remove(arr: Value, idx: Int) raises -> Value:
    """Remove an element from an array at the given index."""
    if not arr.is_array():
        raise Error("Cannot remove from non-array")

    var items = arr.array_items()
    if idx >= len(items):
        raise Error("Array index out of bounds")

    var json = "["
    var first = True

    for i in range(len(items)):
        if i != idx:
            if not first:
                json += ","
            json += dumps(items[i])
            first = False

    json += "]"
    return loads(json)


fn _values_equal(a: Value, b: Value) -> Bool:
    """Check if two values are equal."""
    if a.is_null() and b.is_null():
        return True
    if a.is_bool() and b.is_bool():
        return a.bool_value() == b.bool_value()
    if a.is_int() and b.is_int():
        return a.int_value() == b.int_value()
    if a.is_float() and b.is_float():
        return a.float_value() == b.float_value()
    if a.is_string() and b.is_string():
        return a.string_value() == b.string_value()
    if a.is_array() and b.is_array():
        return dumps(a) == dumps(b)
    if a.is_object() and b.is_object():
        return dumps(a) == dumps(b)
    return False
