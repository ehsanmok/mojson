# Tests for JSON Patch (RFC 6902) and JSON Merge Patch (RFC 7396)

from testing import assert_equal, assert_true, TestSuite

from mojson import loads, dumps, apply_patch, merge_patch, create_merge_patch


# JSON Patch tests

def test_patch_add_new_key():
    """Test adding a new key to an object."""
    var doc = loads('{"name":"Alice"}')
    var patch = loads('[{"op":"add","path":"/age","value":30}]')
    var result = apply_patch(doc, patch)
    assert_true(result["age"].int_value() == 30)


def test_patch_add_to_array():
    """Test adding to an array."""
    var doc = loads('{"items":[1,2]}')
    var patch = loads('[{"op":"add","path":"/items/-","value":3}]')
    var result = apply_patch(doc, patch)
    assert_equal(result["items"].array_count(), 3)


def test_patch_add_array_middle():
    """Test adding to middle of array."""
    var doc = loads('[1,2,3]')
    var patch = loads('[{"op":"add","path":"/1","value":99}]')
    var result = apply_patch(doc, patch)
    assert_equal(Int(result[1].int_value()), 99)


def test_patch_remove_key():
    """Test removing a key."""
    var doc = loads('{"a":1,"b":2}')
    var patch = loads('[{"op":"remove","path":"/a"}]')
    var result = apply_patch(doc, patch)
    var caught = False
    try:
        _ = result["a"]
    except:
        caught = True
    assert_true(caught)


def test_patch_remove_array_element():
    """Test removing array element."""
    var doc = loads('[1,2,3]')
    var patch = loads('[{"op":"remove","path":"/1"}]')
    var result = apply_patch(doc, patch)
    assert_equal(result.array_count(), 2)


def test_patch_replace():
    """Test replacing a value."""
    var doc = loads('{"name":"Alice"}')
    var patch = loads('[{"op":"replace","path":"/name","value":"Bob"}]')
    var result = apply_patch(doc, patch)
    assert_equal(result["name"].string_value(), "Bob")


def test_patch_move():
    """Test moving a value."""
    var doc = loads('{"a":1,"b":2}')
    var patch = loads('[{"op":"move","from":"/a","path":"/c"}]')
    var result = apply_patch(doc, patch)
    assert_equal(Int(result["c"].int_value()), 1)


def test_patch_copy():
    """Test copying a value."""
    var doc = loads('{"a":1}')
    var patch = loads('[{"op":"copy","from":"/a","path":"/b"}]')
    var result = apply_patch(doc, patch)
    assert_equal(Int(result["a"].int_value()), 1)
    assert_equal(Int(result["b"].int_value()), 1)


def test_patch_test_pass():
    """Test the test operation (passing)."""
    var doc = loads('{"a":1}')
    var patch = loads('[{"op":"test","path":"/a","value":1}]')
    var result = apply_patch(doc, patch)
    assert_true(result.is_object())


def test_patch_test_fail():
    """Test the test operation (failing)."""
    var doc = loads('{"a":1}')
    var patch = loads('[{"op":"test","path":"/a","value":2}]')
    var caught = False
    try:
        _ = apply_patch(doc, patch)
    except:
        caught = True
    assert_true(caught)


def test_patch_multiple_ops():
    """Test multiple operations."""
    var doc = loads('{"name":"Alice","age":25}')
    var patch = loads('[{"op":"replace","path":"/name","value":"Bob"},{"op":"add","path":"/active","value":true}]')
    var result = apply_patch(doc, patch)
    assert_equal(result["name"].string_value(), "Bob")
    assert_true(result["active"].bool_value())


# JSON Merge Patch tests

def test_merge_patch_add():
    """Test merge patch adding a key."""
    var target = loads('{"a":1}')
    var patch = loads('{"b":2}')
    var result = merge_patch(target, patch)
    assert_equal(Int(result["a"].int_value()), 1)
    assert_equal(Int(result["b"].int_value()), 2)


def test_merge_patch_remove():
    """Test merge patch removing a key (null)."""
    var target = loads('{"a":1,"b":2}')
    var patch = loads('{"b":null}')
    var result = merge_patch(target, patch)
    var caught = False
    try:
        _ = result["b"]
    except:
        caught = True
    assert_true(caught)


def test_merge_patch_replace():
    """Test merge patch replacing a value."""
    var target = loads('{"a":1}')
    var patch = loads('{"a":2}')
    var result = merge_patch(target, patch)
    assert_equal(Int(result["a"].int_value()), 2)


def test_merge_patch_nested():
    """Test nested merge patch."""
    var target = loads('{"a":{"b":1}}')
    var patch = loads('{"a":{"c":2}}')
    var result = merge_patch(target, patch)
    assert_equal(Int(result["a"]["b"].int_value()), 1)
    assert_equal(Int(result["a"]["c"].int_value()), 2)


def test_merge_patch_replace_object():
    """Test merge patch replacing entire object."""
    var target = loads('{"a":1}')
    var patch = loads('[1,2,3]')
    var result = merge_patch(target, patch)
    assert_true(result.is_array())


def test_create_merge_patch():
    """Test creating a merge patch."""
    var source = loads('{"a":1,"b":2}')
    var target = loads('{"a":1,"c":3}')
    var patch = create_merge_patch(source, target)
    assert_true(patch["b"].is_null())
    assert_equal(Int(patch["c"].int_value()), 3)


def main():
    print("=" * 60)
    print("test_patch.mojo - JSON Patch Tests")
    print("=" * 60)
    print()
    TestSuite.discover_tests[__functions_in_module()]().run()
