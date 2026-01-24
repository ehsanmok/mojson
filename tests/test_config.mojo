# Tests for Parser and Serializer configuration

from testing import assert_equal, assert_true, TestSuite

from src import (
    loads_with_config,
    dumps_with_config,
    ParserConfig,
    SerializerConfig,
    loads,
    Value,
)


# Parser config tests

def test_parser_config_default():
    """Test default parser config (strict mode)."""
    var config = ParserConfig.default()
    assert_equal(config.max_depth, 0)
    assert_true(not config.allow_comments)
    assert_true(not config.allow_trailing_comma)


def test_parser_config_lenient():
    """Test lenient parser config."""
    var config = ParserConfig.lenient()
    assert_true(config.allow_comments)
    assert_true(config.allow_trailing_comma)


def test_parser_allow_single_line_comments():
    """Test parsing JSON with single-line comments."""
    var config = ParserConfig(allow_comments=True)
    var json = '{\n  "name": "Alice" // user name\n}'
    var data = loads_with_config(json, config)
    assert_true(data.is_object())


def test_parser_allow_multi_line_comments():
    """Test parsing JSON with multi-line comments."""
    var config = ParserConfig(allow_comments=True)
    var json = '{\n  /* this is a comment */\n  "value": 42\n}'
    var data = loads_with_config(json, config)
    assert_true(data.is_object())


def test_parser_allow_trailing_comma_array():
    """Test parsing arrays with trailing commas."""
    var config = ParserConfig(allow_trailing_comma=True)
    var json = '[1, 2, 3,]'
    var data = loads_with_config(json, config)
    assert_true(data.is_array())
    assert_equal(data.array_count(), 3)


def test_parser_allow_trailing_comma_object():
    """Test parsing objects with trailing commas."""
    var config = ParserConfig(allow_trailing_comma=True)
    var json = '{"a": 1, "b": 2,}'
    var data = loads_with_config(json, config)
    assert_true(data.is_object())


def test_parser_max_depth_ok():
    """Test parsing within max depth."""
    var config = ParserConfig(max_depth=3)
    var json = '{"a": {"b": {"c": 1}}}'
    var data = loads_with_config(json, config)
    assert_true(data.is_object())


def test_parser_max_depth_exceeded():
    """Test that exceeding max depth raises error."""
    var config = ParserConfig(max_depth=2)
    var json = '{"a": {"b": {"c": 1}}}'  # depth 3
    var caught = False
    try:
        _ = loads_with_config(json, config)
    except:
        caught = True
    assert_true(caught, "Should raise error for exceeding max depth")


def test_parser_combined_options():
    """Test combining multiple parser options."""
    var config = ParserConfig(
        allow_comments=True,
        allow_trailing_comma=True,
        max_depth=10
    )
    var json = '{\n  "items": [1, 2, 3,], // trailing comma\n}'
    var data = loads_with_config(json, config)
    assert_true(data.is_object())


# Serializer config tests

def test_serializer_config_default():
    """Test default serializer config."""
    var config = SerializerConfig.default()
    assert_equal(config.indent, "")
    assert_true(not config.sort_keys)
    assert_true(not config.escape_unicode)


def test_serializer_config_pretty():
    """Test pretty serializer config."""
    var config = SerializerConfig.pretty("  ")
    assert_equal(config.indent, "  ")


def test_serializer_with_indent():
    """Test serialization with indentation."""
    var config = SerializerConfig(indent="  ")
    var data = loads('{"a":1,"b":2}')
    var result = dumps_with_config(data, config)
    assert_true(result.find("\n") >= 0)


def test_serializer_escape_forward_slash():
    """Test escaping forward slashes."""
    var config = SerializerConfig(escape_forward_slash=True)
    var data = loads('{"url":"http://example.com"}')
    var result = dumps_with_config(data, config)
    assert_true(result.find("\\/") >= 0)


def test_serializer_compact():
    """Test compact serialization (no indent)."""
    var config = SerializerConfig()
    var data = loads('{"a": 1, "b": 2}')
    var result = dumps_with_config(data, config)
    assert_true(result.find("\n") < 0)


def main():
    print("=" * 60)
    print("test_config.mojo - Parser/Serializer Config Tests")
    print("=" * 60)
    print()
    TestSuite.discover_tests[__functions_in_module()]().run()
