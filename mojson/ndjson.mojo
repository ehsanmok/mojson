# mojson - NDJSON (Newline-Delimited JSON) support
#
# NDJSON format: Each line is a separate JSON value
# Example:
#   {"id": 1, "name": "Alice"}
#   {"id": 2, "name": "Bob"}
#   {"id": 3, "name": "Charlie"}

from collections import List
from .value import Value
from .parser import loads


fn parse_ndjson[target: StaticString = "cpu"](s: String) raises -> List[Value]:
    """Parse NDJSON (newline-delimited JSON) string into a list of Values.

    Each non-empty line is parsed as a separate JSON value.
    Empty lines and lines containing only whitespace are skipped.

    Parameters:
        target: "cpu" (default) or "gpu" for parsing backend.

    Args:
        s: NDJSON string with one JSON value per line.

    Returns:
        List of parsed Value objects.

    Example:
        var ndjson = '{"a":1}\\n{"a":2}\\n{"a":3}'
        var values = parse_ndjson(ndjson)
        print(len(values))  # Prints 3.
    """
    var result = List[Value]()
    var lines = _split_lines(s)

    for i in range(len(lines)):
        var line = lines[i]
        # Skip empty lines
        if _is_whitespace_only(line):
            continue

        var value = loads[target](line)
        result.append(value^)

    return result^


fn parse_ndjson_lazy[
    target: StaticString = "cpu"
](s: String) raises -> NDJSONIterator[target]:
    """Create a lazy iterator over NDJSON lines.

    More memory-efficient than parse_ndjson() for large files
    as it only parses one line at a time.

    Parameters:
        target: "cpu" (default) or "gpu" for parsing backend.

    Args:
        s: NDJSON string with one JSON value per line.

    Returns:
        Iterator that yields Values one at a time.

    Example:
        var iter = parse_ndjson_lazy(ndjson_string)
        while iter.has_next():
            var value = iter.next()
            process(value).
    """
    return NDJSONIterator[target](s)


struct NDJSONIterator[target: StaticString = "cpu"]:
    """Lazy iterator over NDJSON lines.

    Parses lines on-demand, reducing memory usage for large files.
    """

    var _data: String
    var _pos: Int
    var _len: Int

    fn __init__(out self, data: String):
        """Initialize iterator with NDJSON data."""
        self._data = data
        self._pos = 0
        self._len = len(data)

    fn has_next(self) -> Bool:
        """Check if there are more JSON values to parse."""
        # Skip whitespace and find next non-empty content
        var pos = self._pos
        var data_bytes = self._data.as_bytes()

        while pos < self._len:
            var c = data_bytes[pos]
            if (
                c != UInt8(ord(" "))
                and c != UInt8(ord("\t"))
                and c != UInt8(ord("\n"))
                and c != UInt8(ord("\r"))
            ):
                return True
            pos += 1

        return False

    fn next(mut self) raises -> Value:
        """Parse and return the next JSON value.

        Raises:
            Error if no more values or parse error.
        """
        var data_bytes = self._data.as_bytes()

        # Skip leading whitespace/newlines
        while self._pos < self._len:
            var c = data_bytes[self._pos]
            if (
                c != UInt8(ord(" "))
                and c != UInt8(ord("\t"))
                and c != UInt8(ord("\n"))
                and c != UInt8(ord("\r"))
            ):
                break
            self._pos += 1

        if self._pos >= self._len:
            raise Error("No more NDJSON values")

        # Find end of line
        var line_start = self._pos
        var line_end = line_start

        while line_end < self._len and data_bytes[line_end] != UInt8(ord("\n")):
            line_end += 1

        # Extract line (trim trailing \r if present)
        var end = line_end
        if end > line_start and data_bytes[end - 1] == UInt8(ord("\r")):
            end -= 1

        var line = String(self._data[line_start:end])

        # Move position past newline
        self._pos = line_end + 1

        # Parse the line
        return loads[Self.target](line)

    fn count_remaining(self) -> Int:
        """Count remaining non-empty lines without consuming them."""
        var count = 0
        var pos = self._pos
        var data_bytes = self._data.as_bytes()
        var in_line = False

        while pos < self._len:
            var c = data_bytes[pos]
            if c == UInt8(ord("\n")):
                if in_line:
                    count += 1
                    in_line = False
            elif (
                c != UInt8(ord(" "))
                and c != UInt8(ord("\t"))
                and c != UInt8(ord("\r"))
            ):
                in_line = True
            pos += 1

        # Count last line if it doesn't end with newline
        if in_line:
            count += 1

        return count


fn dumps_ndjson(values: List[Value]) -> String:
    """Serialize a list of Values to NDJSON format.

    Args:
        values: List of Value objects to serialize.

    Returns:
        NDJSON string with one JSON value per line.

    Example:
        var values = List[Value]()
        values.append(loads('{"a":1}'))
        values.append(loads('{"a":2}'))
        print(dumps_ndjson(values))
        Outputs `{"a":1}` and `{"a":2}` on separate lines.
    """
    from .serialize import dumps

    var result = String()
    for i in range(len(values)):
        if i > 0:
            result += "\n"
        result += dumps(values[i])
    return result^


# Helper functions


fn _split_lines(s: String) -> List[String]:
    """Split string into lines."""
    var result = List[String]()
    var s_bytes = s.as_bytes()
    var n = len(s_bytes)
    var line_start = 0

    for i in range(n):
        if s_bytes[i] == UInt8(ord("\n")):
            # Handle \r\n
            var end = i
            if end > line_start and s_bytes[end - 1] == UInt8(ord("\r")):
                end -= 1
            result.append(String(s[line_start:end]))
            line_start = i + 1

    # Add last line if not empty
    if line_start < n:
        var end = n
        if end > line_start and s_bytes[end - 1] == UInt8(ord("\r")):
            end -= 1
        result.append(String(s[line_start:end]))

    return result^


fn _is_whitespace_only(s: String) -> Bool:
    """Check if string contains only whitespace."""
    var s_bytes = s.as_bytes()
    for i in range(len(s_bytes)):
        var c = s_bytes[i]
        if (
            c != UInt8(ord(" "))
            and c != UInt8(ord("\t"))
            and c != UInt8(ord("\r"))
            and c != UInt8(ord("\n"))
        ):
            return False
    return True
