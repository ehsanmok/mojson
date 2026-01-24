# Tests for on-demand (lazy) JSON parsing

from testing import assert_equal, assert_true, TestSuite

from src import loads_lazy, LazyValue


def test_lazy_value_type_detection():
    """Test lazy type detection."""
    var null_v = loads_lazy("null")
    assert_true(null_v.is_null())
    
    var bool_v = loads_lazy("true")
    assert_true(bool_v.is_bool())
    
    var int_v = loads_lazy("42")
    assert_true(int_v.is_int())
    
    var float_v = loads_lazy("3.14")
    assert_true(float_v.is_float())
    
    var str_v = loads_lazy('"hello"')
    assert_true(str_v.is_string())
    
    var arr_v = loads_lazy("[1,2,3]")
    assert_true(arr_v.is_array())
    
    var obj_v = loads_lazy('{"a":1}')
    assert_true(obj_v.is_object())


def test_lazy_get_simple():
    """Test lazy access to simple values."""
    var lazy = loads_lazy('{"name":"Alice","age":30}')
    
    var name = lazy.get("/name")
    assert_equal(name.string_value(), "Alice")
    
    var age = lazy.get("/age")
    assert_equal(Int(age.int_value()), 30)


def test_lazy_get_nested():
    """Test lazy access to nested values."""
    var lazy = loads_lazy('{"user":{"profile":{"name":"Bob"}}}')
    
    var name = lazy.get("/user/profile/name")
    assert_equal(name.string_value(), "Bob")


def test_lazy_get_array():
    """Test lazy access to array elements."""
    var lazy = loads_lazy('{"items":[10,20,30]}')
    
    var first = lazy.get("/items/0")
    assert_equal(Int(first.int_value()), 10)
    
    var second = lazy.get("/items/1")
    assert_equal(Int(second.int_value()), 20)


def test_lazy_get_array_of_objects():
    """Test lazy access to array of objects."""
    var lazy = loads_lazy('{"users":[{"name":"Alice"},{"name":"Bob"}]}')
    
    var first_name = lazy.get("/users/0/name")
    assert_equal(first_name.string_value(), "Alice")
    
    var second_name = lazy.get("/users/1/name")
    assert_equal(second_name.string_value(), "Bob")


def test_lazy_getitem_object():
    """Test lazy [] access for objects."""
    var lazy = loads_lazy('{"a":{"b":{"c":42}}}')
    var inner = lazy["a"]["b"]
    var c = inner.get("/c")
    assert_equal(Int(c.int_value()), 42)


def test_lazy_getitem_array():
    """Test lazy [] access for simple arrays."""
    var lazy = loads_lazy('[10, 20, 30]')
    var second = lazy[1]
    var parsed = second.parse()
    assert_true(parsed.is_int())
    assert_equal(Int(parsed.int_value()), 20)


def test_lazy_get_string():
    """Test get_string helper."""
    var lazy = loads_lazy('{"name":"Alice"}')
    var name = lazy.get_string("/name")
    assert_equal(name, "Alice")


def test_lazy_get_int():
    """Test get_int helper."""
    var lazy = loads_lazy('{"count":42}')
    var count = lazy.get_int("/count")
    assert_equal(Int(count), 42)


def test_lazy_get_bool():
    """Test get_bool helper."""
    var lazy = loads_lazy('{"active":true}')
    var active = lazy.get_bool("/active")
    assert_true(active)


def test_lazy_parse():
    """Test converting lazy value to full Value."""
    var lazy = loads_lazy('{"a":1,"b":2}')
    var value = lazy.parse()
    assert_true(value.is_object())


def test_lazy_empty_pointer():
    """Test empty pointer returns whole document."""
    var lazy = loads_lazy('{"key":"value"}')
    var value = lazy.get("")
    assert_true(value.is_object())


def test_lazy_raw():
    """Test getting raw JSON."""
    var json = '{"a":1}'
    var lazy = loads_lazy(json)
    assert_equal(lazy.raw(), json)


def main():
    print("=" * 60)
    print("test_lazy.mojo - On-Demand Parsing Tests")
    print("=" * 60)
    print()
    TestSuite.discover_tests[__functions_in_module()]().run()
