//! Token types for syntax highlighting
const std = @import("std");

/// Token kind for syntax highlighting
pub const TokenKind = enum {
    // Special
    eof,
    unknown,

    // Literals
    identifier,
    string,
    number,
    comment,
    doc_comment,

    // Keywords
    keyword,
    keyword_control, // if, else, for, while, return, etc.
    keyword_type, // int, string, bool, etc.
    keyword_constant, // true, false, null, undefined, etc.

    // Operators
    operator,
    operator_arithmetic, // +, -, *, /, %
    operator_comparison, // ==, !=, <, >, <=, >=
    operator_logical, // &&, ||, !
    operator_assignment, // =, +=, -=, etc.

    // Delimiters
    bracket, // (), [], {}
    delimiter, // , ; : .

    // Types
    type_name,
    function_name,
    property_name,

    // Whitespace
    whitespace,

    // Special for specific languages
    preprocessor, // #include, #define, etc.
    regex, // Regular expression literals
    escape_sequence, // \n, \t, etc. inside strings
    interpolation, // ${} or {} inside strings

    const Self = @This();

    /// Get a color index for this token kind (for theme lookup)
    pub fn colorIndex(self: Self) usize {
        return switch (self) {
            .eof, .unknown, .whitespace => 0,
            .identifier => 1,
            .string => 2,
            .number => 3,
            .comment, .doc_comment => 4,
            .keyword, .keyword_control, .keyword_type, .keyword_constant => 5,
            .operator, .operator_arithmetic, .operator_comparison, .operator_logical, .operator_assignment => 6,
            .bracket, .delimiter => 7,
            .type_name => 8,
            .function_name => 9,
            .property_name => 10,
            .preprocessor => 11,
            .regex => 12,
            .escape_sequence => 13,
            .interpolation => 14,
        };
    }

    /// Get default color for this token kind (fallback if theme doesn't define)
    pub fn defaultColor(self: Self) DefaultColor {
        return switch (self) {
            .eof, .unknown, .whitespace => .default,
            .identifier => .default,
            .string => .green,
            .number => .cyan,
            .comment, .doc_comment => .bright_black,
            .keyword, .keyword_control, .keyword_type, .keyword_constant => .magenta,
            .operator, .operator_arithmetic, .operator_comparison, .operator_logical, .operator_assignment => .yellow,
            .bracket, .delimiter => .default,
            .type_name => .cyan,
            .function_name => .blue,
            .property_name => .default,
            .preprocessor => .yellow,
            .regex => .green,
            .escape_sequence => .cyan,
            .interpolation => .yellow,
        };
    }
};

/// Default colors for tokens (ANSI color names)
pub const DefaultColor = enum {
    default,
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    bright_black,
    bright_red,
    bright_green,
    bright_yellow,
    bright_blue,
    bright_magenta,
    bright_cyan,
    bright_white,
};

/// A syntax token with kind and text
pub const Token = struct {
    kind: TokenKind,
    text: []const u8,
    start: usize,
    end: usize,

    const Self = @This();

    pub fn init(kind: TokenKind, text: []const u8, start: usize, end: usize) Self {
        return .{
            .kind = kind,
            .text = text,
            .start = start,
            .end = end,
        };
    }

    /// Get the length of this token
    pub fn len(self: Self) usize {
        return self.end - self.start;
    }
};

test "TokenKind color mapping" {
    const testing = std.testing;

    // Test that all token kinds have valid color indices
    const kinds = std.enums.values(TokenKind);
    for (kinds) |kind| {
        const idx = kind.colorIndex();
        try testing.expect(idx < 20);
    }
}

test "Token creation" {
    const testing = std.testing;

    const token = Token.init(.keyword, "fn", 0, 2);
    try testing.expectEqual(TokenKind.keyword, token.kind);
    try testing.expectEqualStrings("fn", token.text);
    try testing.expectEqual(@as(usize, 0), token.start);
    try testing.expectEqual(@as(usize, 2), token.end);
    try testing.expectEqual(@as(usize, 2), token.len());
}
