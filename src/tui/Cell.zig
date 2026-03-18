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
};
