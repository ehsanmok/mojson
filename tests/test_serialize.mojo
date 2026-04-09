# Tests for json/serialize.mojo

from std.testing import assert_equal, assert_true, TestSuite

from json import Value, Null, dumps


def test_serialize_null() raises:
    """Test serializing null."""
    var v = Value(None)
    assert_equal(dumps(v), "null")


def test_serialize_true() raises:
    """Test serializing true."""
    var v = Value(True)
    assert_equal(dumps(v), "true")


def test_serialize_false() raises:
    """Test serializing false."""
    var v = Value(False)
    assert_equal(dumps(v), "false")


def test_serialize_int_positive() raises:
    """Test serializing positive int."""
    var v = Value(42)
    assert_equal(dumps(v), "42")


def test_serialize_int_negative() raises:
    """Test serializing negative int."""
    var v = Value(-123)
    assert_equal(dumps(v), "-123")


def test_serialize_int_zero() raises:
    """Test serializing zero."""
    var v = Value(0)
    assert_equal(dumps(v), "0")


def test_serialize_string() raises:
    """Test serializing string."""
    var v = Value("hello")
    assert_equal(dumps(v), '"hello"')


def test_serialize_string_empty() raises:
    """Test serializing empty string."""
    var v = Value("")
    assert_equal(dumps(v), '""')


def test_serialize_string_with_escapes() raises:
    """Test serializing string with special characters."""
    var v = Value('hello\nworld\ttab"quote')
    var result = dumps(v)
    assert_equal(result, '"hello\\nworld\\ttab\\"quote"')


def test_dumps_pretty_simple_object() raises:
    """Test pretty printing a simple object."""
    from json import loads

    var data = loads('{"name":"Alice","age":30}')
    var result = dumps(data, indent="  ")
    # Check it contains newlines and indentation
    assert_true(result.find("\n") >= 0, "Should contain newlines")
    assert_true(result.find("  ") >= 0, "Should contain indentation")
    assert_true(result.find('"name"') >= 0, "Should contain name key")
    assert_true(result.find('"Alice"') >= 0, "Should contain Alice value")


def test_dumps_pretty_nested_object() raises:
    """Test pretty printing a nested object."""
    from json import loads

    var data = loads('{"user":{"name":"Bob","scores":[1,2,3]}}')
    var result = dumps(data, indent="  ")
    # Check structure
    assert_true(result.find("\n") >= 0, "Should contain newlines")
    assert_true(result.find('"user"') >= 0, "Should contain user key")
    assert_true(result.find('"name"') >= 0, "Should contain name key")


def test_dumps_pretty_array() raises:
    """Test pretty printing an array."""
    from json import loads

    var data = loads('[1,2,3,"hello",true,null]')
    var result = dumps(data, indent="  ")
    assert_true(result.find("\n") >= 0, "Should contain newlines")
    assert_true(result.find("1") >= 0, "Should contain 1")
    assert_true(result.find('"hello"') >= 0, "Should contain hello")


def test_dumps_pretty_empty_object() raises:
    """Test pretty printing an empty object."""
    from json import loads

    var data = loads("{}")
    var result = dumps(data, indent="  ")
    assert_equal(result, "{}")


def test_dumps_pretty_empty_array() raises:
    """Test pretty printing an empty array."""
    from json import loads

    var data = loads("[]")
    var result = dumps(data, indent="  ")
    assert_equal(result, "[]")


def test_dumps_compact_default() raises:
    """Test that dumps without indent is compact."""
    from json import loads

    var data = loads('{"a":1,"b":2}')
    var result = dumps(data)
    # Should not contain newlines
    assert_true(
        result.find("\n") < 0, "Should not contain newlines in compact mode"
    )


def main() raises:
    print("=" * 60)
    print("test_serialize.mojo")
    print("=" * 60)
    print()
    TestSuite.discover_tests[__functions_in_module()]().run()
