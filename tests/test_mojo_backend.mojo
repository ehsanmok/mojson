# Tests for pure Mojo JSON parsing backend
# Ensures parity with simdjson FFI backend

from testing import assert_equal, assert_true, assert_false, TestSuite

from mojson import loads
from mojson.value import Value


# =============================================================================
# Primitive Parsing
# =============================================================================


def test_mojo_null():
    """Test loading null."""
    var v = loads("null")
    assert_true(v.is_null(), "Should load null")


def test_mojo_true():
    """Test loading true."""
    var v = loads("true")
    assert_true(v.is_bool() and v.bool_value(), "Should load true")


def test_mojo_false():
    """Test loading false."""
    var v = loads("false")
    assert_true(v.is_bool() and not v.bool_value(), "Should load false")


def test_mojo_int_positive():
    """Test loading positive integer."""
    var v = loads("42")
    assert_true(v.is_int(), "Should load int")
    assert_equal(Int(v.int_value()), 42)


def test_mojo_int_negative():
    """Test loading negative integer."""
    var v = loads("-123")
    assert_equal(Int(v.int_value()), -123)


def test_mojo_int_zero():
    """Test loading zero."""
    var v = loads("0")
    assert_equal(Int(v.int_value()), 0)


def test_mojo_float():
    """Test loading float."""
    var v = loads("3.14")
    assert_true(v.is_float(), "Should load float")


def test_mojo_float_scientific():
    """Test loading scientific notation."""
    var v = loads("1.5e10")
    assert_true(v.is_float(), "Should load scientific")


def test_mojo_float_negative_exp():
    """Test loading negative exponent."""
    var v = loads("1e-5")
    assert_true(v.is_float(), "Should load negative exp")


# =============================================================================
# String Parsing
# =============================================================================


def test_mojo_string():
    """Test loading simple string."""
    var v = loads('"hello world"')
    assert_true(v.is_string(), "Should load string")
    assert_equal(v.string_value(), "hello world")


def test_mojo_string_empty():
    """Test loading empty string."""
    var v = loads('""')
    assert_equal(v.string_value(), "")


def test_mojo_string_escape_newline():
    """Test loading escaped newline."""
    var v = loads('"hello\\nworld"')
    assert_equal(v.string_value(), "hello\nworld")


def test_mojo_string_escape_tab():
    """Test loading escaped tab."""
    var v = loads('"hello\\tworld"')
    assert_equal(v.string_value(), "hello\tworld")


def test_mojo_string_escape_quote():
    """Test loading escaped quote."""
    var v = loads('"say \\"hello\\""')
    assert_equal(v.string_value(), 'say "hello"')


def test_mojo_string_escape_backslash():
    """Test loading escaped backslash."""
    var v = loads('"path\\\\file"')
    assert_equal(v.string_value(), "path\\file")


# =============================================================================
# Array Parsing
# =============================================================================


def test_mojo_array_empty():
    """Test loading empty array."""
    var v = loads("[]")
    assert_true(v.is_array(), "Should load array")


def test_mojo_array_ints():
    """Test loading array of ints."""
    var v = loads("[1, 2, 3]")
    assert_true(v.is_array(), "Should load array")


def test_mojo_array_mixed():
    """Test loading mixed array."""
    var v = loads('[1, "two", true, null]')
    assert_true(v.is_array(), "Should load mixed array")


def test_mojo_array_nested():
    """Test loading nested array."""
    var v = loads("[[1, 2], [3, 4]]")
    assert_true(v.is_array(), "Should load nested array")


# =============================================================================
# Object Parsing
# =============================================================================


def test_mojo_object_empty():
    """Test loading empty object."""
    var v = loads("{}")
    assert_true(v.is_object(), "Should load object")


def test_mojo_object_simple():
    """Test loading simple object."""
    var v = loads('{"name": "Alice", "age": 30}')
    assert_true(v.is_object(), "Should load object")


def test_mojo_object_nested():
    """Test loading nested object."""
    var v = loads('{"user": {"name": "Bob", "scores": [85, 90, 95]}}')
    assert_true(v.is_object(), "Should load nested")


# =============================================================================
# Whitespace Handling
# =============================================================================


def test_mojo_whitespace_spaces():
    """Test loading with spaces."""
    var v = loads('  {  "key"  :  "value"  }  ')
    assert_true(v.is_object(), "Should handle spaces")


def test_mojo_whitespace_newlines():
    """Test loading with newlines."""
    var v = loads('{\n"key":\n"value"\n}')
    assert_true(v.is_object(), "Should handle newlines")


def test_mojo_whitespace_tabs():
    """Test loading with tabs."""
    var v = loads('{\t"key":\t"value"\t}')
    assert_true(v.is_object(), "Should handle tabs")


# =============================================================================
# Error Handling
# =============================================================================


def test_mojo_error_empty():
    """Test error on empty input."""
    var caught = False
    try:
        _ = loads("")
    except:
        caught = True
    assert_true(caught, "Should raise on empty")


def test_mojo_error_invalid():
    """Test error on invalid JSON."""
    var caught = False
    try:
        _ = loads("invalid")
    except:
        caught = True
    assert_true(caught, "Should raise on invalid")


def test_mojo_error_unclosed_string():
    """Test error on unclosed string."""
    var caught = False
    try:
        _ = loads('"unclosed')
    except:
        caught = True
    assert_true(caught, "Should raise on unclosed string")


def test_mojo_error_unclosed_array():
    """Test error on unclosed array."""
    var caught = False
    try:
        _ = loads("[1, 2")
    except:
        caught = True
    assert_true(caught, "Should raise on unclosed array")


def test_mojo_error_unclosed_object():
    """Test error on unclosed object."""
    var caught = False
    try:
        _ = loads('{"key": "value"')
    except:
        caught = True
    assert_true(caught, "Should raise on unclosed object")


# =============================================================================
# Unicode Escape Tests
# =============================================================================


def test_mojo_unicode_basic():
    """Test basic unicode escape \\u0041 = 'A'."""
    var v = loads('"\\u0041"')
    assert_equal(v.string_value(), "A")


def test_mojo_unicode_euro():
    """Test unicode escape for euro sign \\u20AC."""
    var v = loads('"\\u20AC"')
    assert_equal(v.string_value(), "€")


def test_mojo_unicode_surrogate_pair():
    """Test surrogate pair for emoji (U+1F600 = 😀)."""
    # U+1F600 = D83D DE00 (surrogate pair)
    var v = loads('"\\uD83D\\uDE00"')
    var s = v.string_value()
    # 😀 in UTF-8 is 4 bytes: F0 9F 98 80
    assert_equal(len(s.as_bytes()), 4)


# =============================================================================
# Parity Tests (Mojo vs simdjson)
# =============================================================================


def test_parity_primitives():
    """Test that Mojo backend produces same results as simdjson for primitives.
    """
    var json_strs = List[String]()
    json_strs.append("null")
    json_strs.append("true")
    json_strs.append("false")
    json_strs.append("42")
    json_strs.append("-123")
    json_strs.append("3.14159")
    json_strs.append('"hello"')

    for i in range(len(json_strs)):
        var s = json_strs[i]
        var v_simdjson = loads[target="cpu-simdjson"](s)
        var v_mojo = loads(s)
        assert_equal(v_simdjson.__str__(), v_mojo.__str__())


def test_parity_arrays():
    """Test that Mojo backend produces same results as simdjson for arrays."""
    var json_strs = List[String]()
    json_strs.append("[]")
    json_strs.append("[1, 2, 3]")
    json_strs.append('["a", "b", "c"]')
    json_strs.append("[[1, 2], [3, 4]]")

    for i in range(len(json_strs)):
        var s = json_strs[i]
        var v_simdjson = loads[target="cpu-simdjson"](s)
        var v_mojo = loads(s)
        assert_true(v_simdjson.is_array() == v_mojo.is_array())


def test_parity_objects():
    """Test that Mojo backend produces same results as simdjson for objects."""
    var json_strs = List[String]()
    json_strs.append("{}")
    json_strs.append('{"a": 1}')
    json_strs.append('{"name": "Alice", "age": 30}')

    for i in range(len(json_strs)):
        var s = json_strs[i]
        var v_simdjson = loads[target="cpu-simdjson"](s)
        var v_mojo = loads(s)
        assert_true(v_simdjson.is_object() == v_mojo.is_object())


def main():
    print("=" * 60)
    print("test_mojo_backend.mojo - Pure Mojo backend tests")
    print("=" * 60)
    print()
    TestSuite.discover_tests[__functions_in_module()]().run()
