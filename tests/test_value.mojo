# Tests for mojson/value.mojo

from testing import assert_equal, assert_true, assert_false, TestSuite

from mojson import Value, Null


def test_null_creation():
    """Test null value creation."""
    var v = Value(None)
    assert_true(v.is_null(), "Should be null")
    assert_equal(String(v), "null")


def test_null_from_null_type():
    """Test null from Null type."""
    var v = Value(Null())
    assert_true(v.is_null(), "Should be null")


def test_bool_true():
    """Test boolean true."""
    var v = Value(True)
    assert_true(v.is_bool(), "Should be bool")
    assert_true(v.bool_value(), "Should be true")
    assert_equal(String(v), "true")


def test_bool_false():
    """Test boolean false."""
    var v = Value(False)
    assert_true(v.is_bool(), "Should be bool")
    assert_false(v.bool_value(), "Should be false")
    assert_equal(String(v), "false")


def test_int_positive():
    """Test positive integer."""
    var v = Value(42)
    assert_true(v.is_int(), "Should be int")
    assert_true(v.is_number(), "Should be number")
    assert_equal(Int(v.int_value()), 42)


def test_int_negative():
    """Test negative integer."""
    var v = Value(-123)
    assert_true(v.is_int(), "Should be int")
    assert_equal(Int(v.int_value()), -123)


def test_int_zero():
    """Test zero."""
    var v = Value(0)
    assert_true(v.is_int(), "Should be int")
    assert_equal(Int(v.int_value()), 0)


def test_float():
    """Test float value."""
    var v = Value(3.14)
    assert_true(v.is_float(), "Should be float")
    assert_true(v.is_number(), "Should be number")


def test_string():
    """Test string value."""
    var v = Value("hello")
    assert_true(v.is_string(), "Should be string")
    assert_equal(v.string_value(), "hello")


def test_string_empty():
    """Test empty string."""
    var v = Value("")
    assert_true(v.is_string(), "Should be string")
    assert_equal(v.string_value(), "")


def test_equality_null():
    """Test null equality."""
    var a = Value(None)
    var b = Value(None)
    assert_true(a == b, "Nulls should be equal")


def test_equality_bool():
    """Test bool equality."""
    var a = Value(True)
    var b = Value(True)
    assert_true(a == b, "Bools should be equal")


def test_equality_int():
    """Test int equality."""
    var a = Value(42)
    var b = Value(42)
    assert_true(a == b, "Ints should be equal")


def test_equality_string():
    """Test string equality."""
    var a = Value("hello")
    var b = Value("hello")
    assert_true(a == b, "Strings should be equal")


def test_inequality():
    """Test inequality."""
    var a = Value(1)
    var b = Value(2)
    assert_true(a != b, "Different values should not be equal")


def test_type_mismatch():
    """Test type mismatch."""
    var a = Value(1)
    var b = Value("1")
    assert_true(a != b, "Different types should not be equal")


# JSON Pointer (RFC 6901) tests
def test_json_pointer_empty():
    """Test empty pointer returns whole document."""
    from mojson import loads
    var data = loads('{"a":1}')
    var result = data.at("")
    assert_true(result.is_object(), "Empty pointer should return whole document")


def test_json_pointer_simple_object():
    """Test simple object access."""
    from mojson import loads
    var data = loads('{"name":"Alice","age":30}')
    var name = data.at("/name")
    assert_true(name.is_string(), "Should be string")
    assert_equal(name.string_value(), "Alice")
    
    var age = data.at("/age")
    assert_true(age.is_int(), "Should be int")
    assert_equal(Int(age.int_value()), 30)


def test_json_pointer_nested_object():
    """Test nested object access."""
    from mojson import loads
    var data = loads('{"user":{"name":"Bob","email":"bob@test.com"}}')
    var name = data.at("/user/name")
    assert_equal(name.string_value(), "Bob")
    
    var email = data.at("/user/email")
    assert_equal(email.string_value(), "bob@test.com")


def test_json_pointer_array_index():
    """Test array index access."""
    from mojson import loads
    var data = loads('{"items":[10,20,30]}')
    var first = data.at("/items/0")
    assert_equal(Int(first.int_value()), 10)
    
    var second = data.at("/items/1")
    assert_equal(Int(second.int_value()), 20)
    
    var third = data.at("/items/2")
    assert_equal(Int(third.int_value()), 30)


def test_json_pointer_array_of_objects():
    """Test array of objects access."""
    from mojson import loads
    var data = loads('{"users":[{"name":"Alice"},{"name":"Bob"}]}')
    var first_name = data.at("/users/0/name")
    assert_equal(first_name.string_value(), "Alice")
    
    var second_name = data.at("/users/1/name")
    assert_equal(second_name.string_value(), "Bob")


def test_json_pointer_escape_tilde():
    """Test ~0 escape for tilde."""
    from mojson import loads
    var data = loads('{"a~b":42}')
    var result = data.at("/a~0b")
    assert_equal(Int(result.int_value()), 42)


def test_json_pointer_escape_slash():
    """Test ~1 escape for slash."""
    from mojson import loads
    var data = loads('{"a/b":42}')
    var result = data.at("/a~1b")
    assert_equal(Int(result.int_value()), 42)


def test_json_pointer_deep_nesting():
    """Test deeply nested access."""
    from mojson import loads
    var data = loads('{"a":{"b":{"c":{"d":"deep"}}}}')
    var result = data.at("/a/b/c/d")
    assert_equal(result.string_value(), "deep")


def test_json_pointer_null_value():
    """Test accessing null value."""
    from mojson import loads
    var data = loads('{"value":null}')
    var result = data.at("/value")
    assert_true(result.is_null(), "Should be null")


def test_json_pointer_bool_value():
    """Test accessing boolean value."""
    from mojson import loads
    var data = loads('{"active":true,"deleted":false}')
    var active = data.at("/active")
    assert_true(active.is_bool() and active.bool_value(), "Should be true")
    
    var deleted = data.at("/deleted")
    assert_true(deleted.is_bool() and not deleted.bool_value(), "Should be false")


# Value iteration tests
def test_array_items():
    """Test iterating over array items."""
    from mojson import loads
    var data = loads('[1, 2, 3]')
    var items = data.array_items()
    assert_equal(len(items), 3)
    assert_equal(Int(items[0].int_value()), 1)
    assert_equal(Int(items[1].int_value()), 2)
    assert_equal(Int(items[2].int_value()), 3)


def test_array_items_mixed():
    """Test iterating over mixed array items."""
    from mojson import loads
    var data = loads('[1, "hello", true, null]')
    var items = data.array_items()
    assert_equal(len(items), 4)
    assert_true(items[0].is_int())
    assert_true(items[1].is_string())
    assert_true(items[2].is_bool())
    assert_true(items[3].is_null())


def test_object_items():
    """Test iterating over object items."""
    from mojson import loads
    var data = loads('{"a": 1, "b": 2}')
    var items = data.object_items()
    assert_equal(len(items), 2)


def test_array_getitem():
    """Test array index access."""
    from mojson import loads
    var data = loads('[10, 20, 30]')
    assert_equal(Int(data[0].int_value()), 10)
    assert_equal(Int(data[1].int_value()), 20)
    assert_equal(Int(data[2].int_value()), 30)


def test_object_getitem():
    """Test object key access."""
    from mojson import loads
    var data = loads('{"name": "Alice", "age": 30}')
    assert_equal(data["name"].string_value(), "Alice")
    assert_equal(Int(data["age"].int_value()), 30)


def test_nested_access():
    """Test nested array/object access."""
    from mojson import loads
    var data = loads('{"users": [{"name": "Alice"}, {"name": "Bob"}]}')
    var users = data["users"]
    assert_true(users.is_array())
    var first = users[0]
    assert_equal(first["name"].string_value(), "Alice")


# Value mutation tests
def test_object_set_new_key():
    """Test adding a new key to an object."""
    from mojson import loads
    var data = loads('{"name": "Alice"}')
    data.set("age", Value(30))
    assert_equal(data.object_count(), 2)


def test_object_set_update_key():
    """Test updating an existing key."""
    from mojson import loads
    var data = loads('{"name": "Alice"}')
    data.set("name", Value("Bob"))
    assert_equal(data["name"].string_value(), "Bob")


def test_array_set():
    """Test setting array element."""
    from mojson import loads
    var data = loads('[1, 2, 3]')
    data.set(1, Value(20))
    assert_equal(Int(data[1].int_value()), 20)


def test_array_append():
    """Test appending to array."""
    from mojson import loads
    var data = loads('[1, 2]')
    data.append(Value(3))
    assert_equal(data.array_count(), 3)


def test_array_append_empty():
    """Test appending to empty array."""
    from mojson import loads
    var data = loads('[]')
    data.append(Value(1))
    assert_equal(data.array_count(), 1)
    assert_equal(Int(data[0].int_value()), 1)


def test_object_set_empty():
    """Test adding to empty object."""
    from mojson import loads
    var data = loads('{}')
    data.set("key", Value("value"))
    assert_equal(data.object_count(), 1)


def main():
    print("=" * 60)
    print("test_value.mojo")
    print("=" * 60)
    print()
    TestSuite.discover_tests[__functions_in_module()]().run()
