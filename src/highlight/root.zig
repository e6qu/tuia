//! Syntax highlighting module
const std = @import("std");

pub const Token = @import("Token.zig");
pub const TokenKind = Token.TokenKind;
pub const Language = @import("Language.zig").Language;
pub const Keywords = @import("Language.zig").Keywords;
pub const Highlighter = @import("Highlighter.zig").Highlighter;
pub const highlight = @import("Highlighter.zig").highlight;

test {
    _ = @import("Token.zig");
    _ = @import("Language.zig");
    _ = @import("Highlighter.zig");
}
