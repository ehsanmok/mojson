# mojson CPU backend - Common types and constants
# Backend-agnostic definitions used by all CPU parsing backends

# =============================================================================
# JSON Value Type Constants
# =============================================================================

comptime JSON_TYPE_NULL: Int = 0
comptime JSON_TYPE_BOOL: Int = 1
comptime JSON_TYPE_INT64: Int = 2
comptime JSON_TYPE_UINT64: Int = 3
comptime JSON_TYPE_DOUBLE: Int = 4
comptime JSON_TYPE_STRING: Int = 5
comptime JSON_TYPE_ARRAY: Int = 6
comptime JSON_TYPE_OBJECT: Int = 7


# =============================================================================
# Parse Result Codes
# =============================================================================

comptime JSON_OK: Int = 0
comptime JSON_ERROR_INVALID: Int = 1
comptime JSON_ERROR_CAPACITY: Int = 2
comptime JSON_ERROR_UTF8: Int = 3
comptime JSON_ERROR_OTHER: Int = 99
