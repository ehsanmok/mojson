# Tests for JSON Schema validation

from std.testing import assert_equal, assert_true, TestSuite

from json import loads, validate, is_valid


# Type validation tests


def test_schema_type_string() raises:
    """Test string type validation."""
    var schema = loads('{"type":"string"}')
    assert_true(is_valid(loads('"hello"'), schema))
    assert_true(not is_valid(loads("123"), schema))


def test_schema_type_integer() raises:
    """Test integer type validation."""
    var schema = loads('{"type":"integer"}')
    assert_true(is_valid(loads("42"), schema))
    assert_true(not is_valid(loads("3.14"), schema))


def test_schema_type_number() raises:
    """Test number type validation."""
    var schema = loads('{"type":"number"}')
    assert_true(is_valid(loads("42"), schema))
    assert_true(is_valid(loads("3.14"), schema))
    assert_true(not is_valid(loads('"hello"'), schema))


def test_schema_type_boolean() raises:
    """Test boolean type validation."""
    var schema = loads('{"type":"boolean"}')
    assert_true(is_valid(loads("true"), schema))
    assert_true(is_valid(loads("false"), schema))
    assert_true(not is_valid(loads("1"), schema))


def test_schema_type_null() raises:
    """Test null type validation."""
    var schema = loads('{"type":"null"}')
    assert_true(is_valid(loads("null"), schema))
    assert_true(not is_valid(loads("0"), schema))


def test_schema_type_array() raises:
    """Test array type validation."""
    var schema = loads('{"type":"array"}')
    assert_true(is_valid(loads("[1,2,3]"), schema))
    assert_true(not is_valid(loads("{}"), schema))


def test_schema_type_object() raises:
    """Test object type validation."""
    var schema = loads('{"type":"object"}')
    assert_true(is_valid(loads('{"a":1}'), schema))
    assert_true(not is_valid(loads("[]"), schema))


# Number constraints


def test_schema_minimum() raises:
    """Test minimum constraint."""
    var schema = loads('{"type":"number","minimum":5}')
    assert_true(is_valid(loads("10"), schema))
    assert_true(is_valid(loads("5"), schema))
    assert_true(not is_valid(loads("3"), schema))


def test_schema_maximum() raises:
    """Test maximum constraint."""
    var schema = loads('{"type":"number","maximum":10}')
    assert_true(is_valid(loads("5"), schema))
    assert_true(is_valid(loads("10"), schema))
    assert_true(not is_valid(loads("15"), schema))


# String constraints


def test_schema_minLength() raises:
    """Test minLength constraint."""
    var schema = loads('{"type":"string","minLength":3}')
    assert_true(is_valid(loads('"hello"'), schema))
    assert_true(not is_valid(loads('"hi"'), schema))


def test_schema_maxLength() raises:
    """Test maxLength constraint."""
    var schema = loads('{"type":"string","maxLength":5}')
    assert_true(is_valid(loads('"hi"'), schema))
    assert_true(not is_valid(loads('"hello world"'), schema))


# Array constraints


def test_schema_minItems() raises:
    """Test minItems constraint."""
    var schema = loads('{"type":"array","minItems":2}')
    assert_true(is_valid(loads("[1,2,3]"), schema))
    assert_true(not is_valid(loads("[1]"), schema))


def test_schema_maxItems() raises:
    """Test maxItems constraint."""
    var schema = loads('{"type":"array","maxItems":3}')
    assert_true(is_valid(loads("[1,2]"), schema))
    assert_true(not is_valid(loads("[1,2,3,4]"), schema))


def test_schema_items() raises:
    """Test items schema."""
    var schema = loads('{"type":"array","items":{"type":"integer"}}')
    assert_true(is_valid(loads("[1,2,3]"), schema))
    assert_true(not is_valid(loads('[1,"two",3]'), schema))


# Object constraints


def test_schema_required() raises:
    """Test required properties."""
    var schema = loads('{"type":"object","required":["name"]}')
    assert_true(is_valid(loads('{"name":"Alice"}'), schema))
    assert_true(not is_valid(loads('{"age":30}'), schema))


def test_schema_properties() raises:
    """Test properties schema."""
    var schema = loads(
        '{"type":"object","properties":{"age":{"type":"integer"}}}'
    )
    assert_true(is_valid(loads('{"age":30}'), schema))
    assert_true(not is_valid(loads('{"age":"thirty"}'), schema))


def test_schema_additionalProperties_false() raises:
    """Test additionalProperties false."""
    var schema = loads(
        '{"type":"object","properties":{"a":{"type":"integer"}},"additionalProperties":false}'
    )
    assert_true(is_valid(loads('{"a":1}'), schema))
    assert_true(not is_valid(loads('{"a":1,"b":2}'), schema))


# Enum and const


def test_schema_enum() raises:
    """Test enum validation."""
    var schema = loads('{"enum":["red","green","blue"]}')
    assert_true(is_valid(loads('"red"'), schema))
    assert_true(not is_valid(loads('"yellow"'), schema))


def test_schema_const() raises:
    """Test const validation."""
    var schema = loads('{"const":42}')
    assert_true(is_valid(loads("42"), schema))
    assert_true(not is_valid(loads("43"), schema))


# Composition


def test_schema_allOf() raises:
    """Test allOf composition."""
    var schema = loads('{"allOf":[{"type":"object"},{"required":["name"]}]}')
    assert_true(is_valid(loads('{"name":"Alice"}'), schema))
    assert_true(not is_valid(loads('{"age":30}'), schema))


def test_schema_anyOf() raises:
    """Test anyOf composition."""
    var schema = loads('{"anyOf":[{"type":"string"},{"type":"integer"}]}')
    assert_true(is_valid(loads('"hello"'), schema))
    assert_true(is_valid(loads("42"), schema))
    assert_true(not is_valid(loads("true"), schema))


def test_schema_not() raises:
    """Test not composition."""
    var schema = loads('{"not":{"type":"string"}}')
    assert_true(is_valid(loads("42"), schema))
    assert_true(not is_valid(loads('"hello"'), schema))


# Validation result


def test_validation_result_errors() raises:
    """Test validation result contains errors."""
    var schema = loads('{"type":"object","required":["name","age"]}')
    var doc = loads("{}")
    var result = validate(doc, schema)
    assert_true(not result.valid)
    assert_true(len(result.errors) >= 2)


def main() raises:
    print("=" * 60)
    print("test_schema.mojo - JSON Schema Tests")
    print("=" * 60)
    print()
    TestSuite.discover_tests[__functions_in_module()]().run()
