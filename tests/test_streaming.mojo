# Tests for streaming JSON parsing

from testing import assert_equal, assert_true, TestSuite

from src import stream_ndjson, stream_json_array, StreamingParser


def test_stream_ndjson_basic():
    """Test streaming NDJSON file."""
    # Create test file
    with open("test_stream.ndjson", "w") as f:
        f.write('{"id":1}\n{"id":2}\n{"id":3}\n')
    
    var parser = stream_ndjson("test_stream.ndjson")
    var count = 0
    
    while parser.has_next():
        var value = parser.next()
        count += 1
        assert_true(value.is_object())
    
    parser.close()
    assert_equal(count, 3)


def test_stream_ndjson_empty_lines():
    """Test streaming NDJSON with empty lines."""
    with open("test_stream_empty.ndjson", "w") as f:
        f.write('{"a":1}\n\n{"a":2}\n\n{"a":3}\n')
    
    var parser = stream_ndjson("test_stream_empty.ndjson")
    var count = 0
    
    while parser.has_next():
        _ = parser.next()
        count += 1
    
    parser.close()
    assert_equal(count, 3)


def test_stream_json_array_basic():
    """Test streaming JSON array file."""
    with open("test_stream_array.json", "w") as f:
        f.write('[{"id":1},{"id":2},{"id":3}]')
    
    var parser = stream_json_array("test_stream_array.json")
    var count = 0
    
    while parser.has_next():
        var value = parser.next()
        count += 1
        assert_true(value.is_object())
    
    parser.close()
    assert_equal(count, 3)


def test_stream_json_array_primitives():
    """Test streaming array of primitives."""
    with open("test_stream_prims.json", "w") as f:
        f.write('[1, 2, 3, "hello", true]')
    
    var parser = stream_json_array("test_stream_prims.json")
    var count = 0
    
    while parser.has_next():
        _ = parser.next()
        count += 1
    
    parser.close()
    assert_equal(count, 5)


def test_stream_json_array_nested():
    """Test streaming array with nested objects."""
    with open("test_stream_nested.json", "w") as f:
        f.write('[{"user":{"name":"Alice"}},{"user":{"name":"Bob"}}]')
    
    var parser = stream_json_array("test_stream_nested.json")
    var count = 0
    
    while parser.has_next():
        var value = parser.next()
        assert_true(value.is_object())
        count += 1
    
    parser.close()
    assert_equal(count, 2)


def test_stream_small_chunks():
    """Test streaming with small chunk size."""
    with open("test_stream_small.ndjson", "w") as f:
        f.write('{"a":1}\n{"a":2}\n')
    
    # Use small chunk size to test buffering (but large enough for full line)
    var parser = StreamingParser("test_stream_small.ndjson", chunk_size=32)
    var count = 0
    
    while parser.has_next():
        var value = parser.next()
        assert_true(value.is_object())
        count += 1
    
    parser.close()
    assert_equal(count, 2)


def main():
    print("=" * 60)
    print("test_streaming.mojo - Streaming Parsing Tests")
    print("=" * 60)
    print()
    TestSuite.discover_tests[__functions_in_module()]().run()
    
    # Cleanup test files
    import os
    try:
        os.remove("test_stream.ndjson")
        os.remove("test_stream_empty.ndjson")
        os.remove("test_stream_array.json")
        os.remove("test_stream_prims.json")
        os.remove("test_stream_nested.json")
        os.remove("test_stream_small.ndjson")
    except:
        pass
