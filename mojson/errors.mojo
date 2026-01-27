# mojson - JSON error handling with line/column information


fn compute_line_column(source: String, position: Int) -> Tuple[Int, Int]:
    """Compute line and column number from byte position.

    Args:
        source: The source JSON string.
        position: Byte position (0-indexed).

    Returns:
        Tuple of (line, column) - both 1-indexed.
    """
    var source_bytes = source.as_bytes()
    var n = len(source_bytes)
    var pos = min(position, n)

    var line = 1
    var column = 1

    for i in range(pos):
        if source_bytes[i] == ord("\n"):
            line += 1
            column = 1
        else:
            column += 1

    return (line, column)


fn format_error_context(source: String, position: Int, context_chars: Int = 20) -> String:
    """Format error with surrounding context.

    Args:
        source: The source JSON string.
        position: Byte position of the error.
        context_chars: Number of characters to show before/after error.

    Returns:
        Formatted error context string.
    """
    var source_bytes = source.as_bytes()
    var n = len(source_bytes)
    var pos = min(position, n)

    var start = max(0, pos - context_chars)
    var end = min(n, pos + context_chars)

    var result = String()

    # Show context before
    if start > 0:
        result += "..."

    for i in range(start, end):
        var c = source_bytes[i]
        if c == ord("\n"):
            result += "\\n"
        elif c == ord("\r"):
            result += "\\r"
        elif c == ord("\t"):
            result += "\\t"
        else:
            result += chr(Int(c))

    if end < n:
        result += "..."

    return result^


fn json_parse_error(message: String, source: String, position: Int) -> String:
    """Create a detailed JSON parse error message.

    Args:
        message: The error message.
        source: The source JSON string.
        position: Byte position of the error.
    
    Returns:
        Formatted error message with line/column and context.

    Example:
        `JSON parse error at line 3, column 15: Expected ':' after object key`
        `Near: ..."key" value}...`
    """
    var line_col = compute_line_column(source, position)
    var line = line_col[0]
    var column = line_col[1]
    var context = format_error_context(source, position)

    return (
        "JSON parse error at line " + String(line) +
        ", column " + String(column) + ": " + message +
        "\n  Near: " + context
    )


fn find_error_position(source: String) -> Int:
    """Try to find the position of a JSON error by scanning.

    This is a heuristic to find where parsing likely failed.

    Args:
        source: The source JSON string.
    
    Returns:
        Estimated error position (byte offset).
    """
    var source_bytes = source.as_bytes()
    var n = len(source_bytes)
    var depth = 0
    var in_string = False
    var escaped = False
    var last_structural = 0

    for i in range(n):
        var c = source_bytes[i]

        if escaped:
            escaped = False
            continue

        if c == ord("\\") and in_string:
            escaped = True
            continue

        if c == ord('"'):
            in_string = not in_string
            last_structural = i
            continue

        if in_string:
            continue

        # Structural characters
        if c == ord("{") or c == ord("["):
            depth += 1
            last_structural = i
        elif c == ord("}") or c == ord("]"):
            depth -= 1
            if depth < 0:
                return i  # Unmatched closing bracket
            last_structural = i
        elif c == ord(":") or c == ord(","):
            last_structural = i

    # If we end with unclosed brackets, return the last structural position
    if depth > 0 or in_string:
        return last_structural

    return n  # End of source
