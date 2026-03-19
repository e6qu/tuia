//! Terminal cell — a single character position with style
const style_mod = @import("Style.zig");

pub const Color = style_mod.Color;
pub const Style = style_mod.Style;

/// A single terminal cell
pub const Cell = struct {
    char: Character = .{},
    style: Style = .{},

    pub const Color = style_mod.Color;

    /// Grapheme cluster with display width
    pub const Character = struct {
        grapheme: []const u8 = " ",
        width: u8 = 1,
    };

    /// Static lookup table for single-byte graphemes.
    /// Returns a stable slice pointing to static memory, avoiding use-after-free
    /// when writing individual characters to cells.
    const byte_graphemes = init: {
        var table: [256][1]u8 = undefined;
        for (0..256) |i| {
            table[i] = .{@intCast(i)};
        }
        break :init table;
    };

    pub fn grapheme(byte: u8) []const u8 {
        return &byte_graphemes[byte];
    }
};
