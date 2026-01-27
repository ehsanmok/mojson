# Tests for JSONPath queries

from testing import assert_equal, assert_true, TestSuite

from mojson import loads, jsonpath_query, jsonpath_one


def test_jsonpath_root():
    """Test root selector $."""
    var doc = loads('{"a":1}')
    var results = jsonpath_query(doc, "$")
    assert_equal(len(results), 1)
    assert_true(results[0].is_object())


def test_jsonpath_child():
    """Test child selector $.key."""
    var doc = loads('{"name":"Alice","age":30}')
    var results = jsonpath_query(doc, "$.name")
    assert_equal(len(results), 1)
    assert_equal(results[0].string_value(), "Alice")


def test_jsonpath_nested():
    """Test nested selector $.a.b.c."""
    var doc = loads('{"a":{"b":{"c":42}}}')
    var results = jsonpath_query(doc, "$.a.b.c")
    assert_equal(len(results), 1)
    assert_equal(Int(results[0].int_value()), 42)


def test_jsonpath_array_index():
    """Test array index $[0]."""
    var doc = loads('[10,20,30]')
    var results = jsonpath_query(doc, "$[0]")
    assert_equal(len(results), 1)
    assert_equal(Int(results[0].int_value()), 10)


def test_jsonpath_nested_array():
    """Test nested array access $.items[1]."""
    var doc = loads('{"items":[1,2,3]}')
    var results = jsonpath_query(doc, "$.items[1]")
    assert_equal(len(results), 1)
    assert_equal(Int(results[0].int_value()), 2)


def test_jsonpath_wildcard_array():
    """Test wildcard on array $[*]."""
    var doc = loads('[1,2,3]')
    var results = jsonpath_query(doc, "$[*]")
    assert_equal(len(results), 3)


def test_jsonpath_wildcard_object():
    """Test wildcard on object $.*."""
    var doc = loads('{"a":1,"b":2,"c":3}')
    var results = jsonpath_query(doc, "$.*")
    assert_equal(len(results), 3)


def test_jsonpath_nested_wildcard():
    """Test $.users[*].name."""
    var doc = loads('{"users":[{"name":"Alice"},{"name":"Bob"}]}')
    var results = jsonpath_query(doc, "$.users[*].name")
    assert_equal(len(results), 2)
    assert_equal(results[0].string_value(), "Alice")
    assert_equal(results[1].string_value(), "Bob")


def test_jsonpath_recursive():
    """Test recursive descent $..name."""
    var doc = loads('{"a":{"name":"foo"},"b":{"name":"bar"}}')
    var results = jsonpath_query(doc, "$..name")
    assert_true(len(results) >= 2)


def test_jsonpath_slice():
    """Test array slice $[0:2]."""
    var doc = loads('[0,1,2,3,4]')
    var results = jsonpath_query(doc, "$[0:2]")
    assert_equal(len(results), 2)


def test_jsonpath_negative_index():
    """Test negative index $[-1]."""
    var doc = loads('[1,2,3]')
    var results = jsonpath_query(doc, "$[-1]")
    assert_equal(len(results), 1)
    assert_equal(Int(results[0].int_value()), 3)


def test_jsonpath_bracket_notation():
    """Test bracket notation $['key']."""
    var doc = loads('{"key with space":"value"}')
    var results = jsonpath_query(doc, "$['key with space']")
    assert_equal(len(results), 1)
    assert_equal(results[0].string_value(), "value")


def test_jsonpath_filter_eq():
    """Test filter with equality $[?@.price==10]."""
    var doc = loads('[{"price":5},{"price":10},{"price":15}]')
    var results = jsonpath_query(doc, "$[?@.price==10]")
    assert_equal(len(results), 1)


def test_jsonpath_filter_lt():
    """Test filter with less than $[?@.price<10]."""
    var doc = loads('[{"price":5},{"price":10},{"price":15}]')
    var results = jsonpath_query(doc, "$[?@.price<10]")
    assert_equal(len(results), 1)


def test_jsonpath_filter_gt():
    """Test filter with greater than $[?@.price>10]."""
    var doc = loads('[{"price":5},{"price":10},{"price":15}]')
    var results = jsonpath_query(doc, "$[?@.price>10]")
    assert_equal(len(results), 1)


def test_jsonpath_one():
    """Test jsonpath_one helper."""
    var doc = loads('{"name":"Alice"}')
    var result = jsonpath_one(doc, "$.name")
    assert_equal(result.string_value(), "Alice")


def test_jsonpath_one_no_match():
    """Test jsonpath_one with no match."""
    var doc = loads('{"name":"Alice"}')
    var caught = False
    try:
        _ = jsonpath_one(doc, "$.nonexistent")
    except:
        caught = True
    assert_true(caught)


def main():
    print("=" * 60)
    print("test_jsonpath.mojo - JSONPath Tests")
    print("=" * 60)
    print()
    TestSuite.discover_tests[__functions_in_module()]().run()
