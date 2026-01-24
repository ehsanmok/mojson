# Tests for NDJSON (Newline-Delimited JSON) support

from testing import assert_equal, assert_true, TestSuite

from src import parse_ndjson, parse_ndjson_lazy, dumps_ndjson, loads, Value


def test_parse_ndjson_basic():
    """Test parsing basic NDJSON."""
    var ndjson = '{"a":1}\n{"a":2}\n{"a":3}'
    var values = parse_ndjson(ndjson)
    assert_equal(len(values), 3)


def test_parse_ndjson_single_line():
    """Test parsing single line NDJSON."""
    var ndjson = '{"name":"Alice"}'
    var values = parse_ndjson(ndjson)
    assert_equal(len(values), 1)
    assert_true(values[0].is_object())


def test_parse_ndjson_empty_lines():
    """Test that empty lines are skipped."""
    var ndjson = '{"a":1}\n\n{"a":2}\n\n\n{"a":3}\n'
    var values = parse_ndjson(ndjson)
    assert_equal(len(values), 3)


def test_parse_ndjson_whitespace_lines():
    """Test that whitespace-only lines are skipped."""
    var ndjson = '{"a":1}\n   \n{"a":2}\n\t\t\n{"a":3}'
    var values = parse_ndjson(ndjson)
    assert_equal(len(values), 3)


def test_parse_ndjson_crlf():
    """Test parsing NDJSON with Windows line endings."""
    var ndjson = '{"a":1}\r\n{"a":2}\r\n{"a":3}'
    var values = parse_ndjson(ndjson)
    assert_equal(len(values), 3)


def test_parse_ndjson_mixed_types():
    """Test parsing NDJSON with different JSON types."""
    var ndjson = '{"obj":true}\n[1,2,3]\n"string"\n42\ntrue\nnull'
    var values = parse_ndjson(ndjson)
    assert_equal(len(values), 6)
    assert_true(values[0].is_object())
    assert_true(values[1].is_array())
    assert_true(values[2].is_string())
    assert_true(values[3].is_int())
    assert_true(values[4].is_bool())
    assert_true(values[5].is_null())


def test_parse_ndjson_lazy_basic():
    """Test lazy NDJSON parsing."""
    var ndjson = '{"a":1}\n{"a":2}\n{"a":3}'
    var iter = parse_ndjson_lazy(ndjson)
    
    assert_true(iter.has_next())
    var v1 = iter.next()
    assert_true(v1.is_object())
    
    assert_true(iter.has_next())
    var v2 = iter.next()
    assert_true(v2.is_object())
    
    assert_true(iter.has_next())
    var v3 = iter.next()
    assert_true(v3.is_object())
    
    assert_true(not iter.has_next())


def test_parse_ndjson_lazy_count():
    """Test counting remaining items in lazy iterator."""
    var ndjson = '{"a":1}\n{"a":2}\n{"a":3}\n{"a":4}'
    var iter = parse_ndjson_lazy(ndjson)
    
    assert_equal(iter.count_remaining(), 4)
    
    _ = iter.next()
    assert_equal(iter.count_remaining(), 3)
    
    _ = iter.next()
    assert_equal(iter.count_remaining(), 2)


def test_dumps_ndjson_basic():
    """Test serializing to NDJSON."""
    var values = List[Value]()
    values.append(loads('{"a":1}'))
    values.append(loads('{"a":2}'))
    values.append(loads('{"a":3}'))
    
    var result = dumps_ndjson(values)
    assert_true(result.find("\n") >= 0)
    
    # Round-trip test
    var parsed = parse_ndjson(result)
    assert_equal(len(parsed), 3)


def test_dumps_ndjson_empty():
    """Test serializing empty list."""
    var values = List[Value]()
    var result = dumps_ndjson(values)
    assert_equal(result, "")


def test_dumps_ndjson_single():
    """Test serializing single value."""
    var values = List[Value]()
    values.append(loads('{"key":"value"}'))
    var result = dumps_ndjson(values)
    assert_true(result.find("\n") < 0)  # No newline for single value


def test_ndjson_roundtrip():
    """Test NDJSON round-trip."""
    var original = '{"id":1,"name":"Alice"}\n{"id":2,"name":"Bob"}\n{"id":3,"name":"Charlie"}'
    var values = parse_ndjson(original)
    var serialized = dumps_ndjson(values)
    var reparsed = parse_ndjson(serialized)
    
    assert_equal(len(values), len(reparsed))
    assert_equal(len(reparsed), 3)


def main():
    print("=" * 60)
    print("test_ndjson.mojo - NDJSON Tests")
    print("=" * 60)
    print()
    TestSuite.discover_tests[__functions_in_module()]().run()
