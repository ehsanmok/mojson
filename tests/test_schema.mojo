# Tests for JSON Schema validation

from testing import assert_equal, assert_true, TestSuite

from src import loads, validate, is_valid


# Type validation tests

def test_schema_type_string():
    """Test string type validation."""
    var schema = loads('{"type":"string"}')
    assert_true(is_valid(loads('"hello"'), schema))
    assert_true(not is_valid(loads('123'), schema))


def test_schema_type_integer():
    """Test integer type validation."""
    var schema = loads('{"type":"integer"}')
    assert_true(is_valid(loads('42'), schema))
    assert_true(not is_valid(loads('3.14'), schema))


def test_schema_type_number():
    """Test number type validation."""
    var schema = loads('{"type":"number"}')
    assert_true(is_valid(loads('42'), schema))
    assert_true(is_valid(loads('3.14'), schema))
    assert_true(not is_valid(loads('"hello"'), schema))


def test_schema_type_boolean():
    """Test boolean type validation."""
    var schema = loads('{"type":"boolean"}')
    assert_true(is_valid(loads('true'), schema))
    assert_true(is_valid(loads('false'), schema))
    assert_true(not is_valid(loads('1'), schema))


def test_schema_type_null():
    """Test null type validation."""
    var schema = loads('{"type":"null"}')
    assert_true(is_valid(loads('null'), schema))
    assert_true(not is_valid(loads('0'), schema))


def test_schema_type_array():
    """Test array type validation."""
    var schema = loads('{"type":"array"}')
    assert_true(is_valid(loads('[1,2,3]'), schema))
    assert_true(not is_valid(loads('{}'), schema))


def test_schema_type_object():
    """Test object type validation."""
    var schema = loads('{"type":"object"}')
    assert_true(is_valid(loads('{"a":1}'), schema))
    assert_true(not is_valid(loads('[]'), schema))


# Number constraints

def test_schema_minimum():
    """Test minimum constraint."""
    var schema = loads('{"type":"number","minimum":5}')
    assert_true(is_valid(loads('10'), schema))
    assert_true(is_valid(loads('5'), schema))
    assert_true(not is_valid(loads('3'), schema))


def test_schema_maximum():
    """Test maximum constraint."""
    var schema = loads('{"type":"number","maximum":10}')
    assert_true(is_valid(loads('5'), schema))
    assert_true(is_valid(loads('10'), schema))
    assert_true(not is_valid(loads('15'), schema))


# String constraints

def test_schema_minLength():
    """Test minLength constraint."""
    var schema = loads('{"type":"string","minLength":3}')
    assert_true(is_valid(loads('"hello"'), schema))
    assert_true(not is_valid(loads('"hi"'), schema))


def test_schema_maxLength():
    """Test maxLength constraint."""
    var schema = loads('{"type":"string","maxLength":5}')
    assert_true(is_valid(loads('"hi"'), schema))
    assert_true(not is_valid(loads('"hello world"'), schema))


# Array constraints

def test_schema_minItems():
    """Test minItems constraint."""
    var schema = loads('{"type":"array","minItems":2}')
    assert_true(is_valid(loads('[1,2,3]'), schema))
    assert_true(not is_valid(loads('[1]'), schema))


def test_schema_maxItems():
    """Test maxItems constraint."""
    var schema = loads('{"type":"array","maxItems":3}')
    assert_true(is_valid(loads('[1,2]'), schema))
    assert_true(not is_valid(loads('[1,2,3,4]'), schema))


def test_schema_items():
    """Test items schema."""
    var schema = loads('{"type":"array","items":{"type":"integer"}}')
    assert_true(is_valid(loads('[1,2,3]'), schema))
    assert_true(not is_valid(loads('[1,"two",3]'), schema))


# Object constraints

def test_schema_required():
    """Test required properties."""
    var schema = loads('{"type":"object","required":["name"]}')
    assert_true(is_valid(loads('{"name":"Alice"}'), schema))
    assert_true(not is_valid(loads('{"age":30}'), schema))


def test_schema_properties():
    """Test properties schema."""
    var schema = loads('{"type":"object","properties":{"age":{"type":"integer"}}}')
    assert_true(is_valid(loads('{"age":30}'), schema))
    assert_true(not is_valid(loads('{"age":"thirty"}'), schema))


def test_schema_additionalProperties_false():
    """Test additionalProperties false."""
    var schema = loads('{"type":"object","properties":{"a":{"type":"integer"}},"additionalProperties":false}')
    assert_true(is_valid(loads('{"a":1}'), schema))
    assert_true(not is_valid(loads('{"a":1,"b":2}'), schema))


# Enum and const

def test_schema_enum():
    """Test enum validation."""
    var schema = loads('{"enum":["red","green","blue"]}')
    assert_true(is_valid(loads('"red"'), schema))
    assert_true(not is_valid(loads('"yellow"'), schema))


def test_schema_const():
    """Test const validation."""
    var schema = loads('{"const":42}')
    assert_true(is_valid(loads('42'), schema))
    assert_true(not is_valid(loads('43'), schema))


# Composition

def test_schema_allOf():
    """Test allOf composition."""
    var schema = loads('{"allOf":[{"type":"object"},{"required":["name"]}]}')
    assert_true(is_valid(loads('{"name":"Alice"}'), schema))
    assert_true(not is_valid(loads('{"age":30}'), schema))


def test_schema_anyOf():
    """Test anyOf composition."""
    var schema = loads('{"anyOf":[{"type":"string"},{"type":"integer"}]}')
    assert_true(is_valid(loads('"hello"'), schema))
    assert_true(is_valid(loads('42'), schema))
    assert_true(not is_valid(loads('true'), schema))


def test_schema_not():
    """Test not composition."""
    var schema = loads('{"not":{"type":"string"}}')
    assert_true(is_valid(loads('42'), schema))
    assert_true(not is_valid(loads('"hello"'), schema))


# Validation result

def test_validation_result_errors():
    """Test validation result contains errors."""
    var schema = loads('{"type":"object","required":["name","age"]}')
    var doc = loads('{}')
    var result = validate(doc, schema)
    assert_true(not result.valid)
    assert_true(len(result.errors) >= 2)


def main():
    print("=" * 60)
    print("test_schema.mojo - JSON Schema Tests")
    print("=" * 60)
    print()
    TestSuite.discover_tests[__functions_in_module()]().run()
