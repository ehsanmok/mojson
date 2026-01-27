# Tests for mojson/serialize.mojo

from testing import assert_equal, assert_true, TestSuite

from mojson import Value, Null, dumps


def test_serialize_null():
    """Test serializing null."""
    var v = Value(None)
    assert_equal(dumps(v), "null")


def test_serialize_true():
    """Test serializing true."""
    var v = Value(True)
    assert_equal(dumps(v), "true")


def test_serialize_false():
    """Test serializing false."""
    var v = Value(False)
    assert_equal(dumps(v), "false")


def test_serialize_int_positive():
    """Test serializing positive int."""
    var v = Value(42)
    assert_equal(dumps(v), "42")


def test_serialize_int_negative():
    """Test serializing negative int."""
    var v = Value(-123)
    assert_equal(dumps(v), "-123")


def test_serialize_int_zero():
    """Test serializing zero."""
    var v = Value(0)
    assert_equal(dumps(v), "0")


def test_serialize_string():
    """Test serializing string."""
    var v = Value("hello")
    assert_equal(dumps(v), '"hello"')


def test_serialize_string_empty():
    """Test serializing empty string."""
    var v = Value("")
    assert_equal(dumps(v), '""')


def test_serialize_string_with_escapes():
    """Test serializing string with special characters."""
    var v = Value('hello\nworld\ttab"quote')
    var result = dumps(v)
    assert_equal(result, '"hello\\nworld\\ttab\\"quote"')


def test_dumps_pretty_simple_object():
    """Test pretty printing a simple object."""
    from mojson import loads

    var data = loads('{"name":"Alice","age":30}')
    var result = dumps(data, indent="  ")
    # Check it contains newlines and indentation
    assert_true(result.find("\n") >= 0, "Should contain newlines")
    assert_true(result.find("  ") >= 0, "Should contain indentation")
    assert_true(result.find('"name"') >= 0, "Should contain name key")
    assert_true(result.find('"Alice"') >= 0, "Should contain Alice value")


def test_dumps_pretty_nested_object():
    """Test pretty printing a nested object."""
    from mojson import loads

    var data = loads('{"user":{"name":"Bob","scores":[1,2,3]}}')
    var result = dumps(data, indent="  ")
    # Check structure
    assert_true(result.find("\n") >= 0, "Should contain newlines")
    assert_true(result.find('"user"') >= 0, "Should contain user key")
    assert_true(result.find('"name"') >= 0, "Should contain name key")


def test_dumps_pretty_array():
    """Test pretty printing an array."""
    from mojson import loads

    var data = loads('[1,2,3,"hello",true,null]')
    var result = dumps(data, indent="  ")
    assert_true(result.find("\n") >= 0, "Should contain newlines")
    assert_true(result.find("1") >= 0, "Should contain 1")
    assert_true(result.find('"hello"') >= 0, "Should contain hello")


def test_dumps_pretty_empty_object():
    """Test pretty printing an empty object."""
    from mojson import loads

    var data = loads("{}")
    var result = dumps(data, indent="  ")
    assert_equal(result, "{}")


def test_dumps_pretty_empty_array():
    """Test pretty printing an empty array."""
    from mojson import loads

    var data = loads("[]")
    var result = dumps(data, indent="  ")
    assert_equal(result, "[]")


def test_dumps_compact_default():
    """Test that dumps without indent is compact."""
    from mojson import loads

    var data = loads('{"a":1,"b":2}')
    var result = dumps(data)
    # Should not contain newlines
    assert_true(
        result.find("\n") < 0, "Should not contain newlines in compact mode"
    )


def main():
    print("=" * 60)
    print("test_serialize.mojo")
    print("=" * 60)
    print()
    TestSuite.discover_tests[__functions_in_module()]().run()
