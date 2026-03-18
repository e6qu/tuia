//! Color and text style types for terminal rendering
const std = @import("std");

/// Terminal color — default, 256-color index, or 24-bit RGB
pub const Color = union(enum) {
    default,
    index: u8,
    rgb: [3]u8,
};

/// Text styling attributes
pub const Style = struct {
    fg: Color = .default,
    bg: Color = .default,
    ul: Color = .default,
    ul_style: Underline = .off,

    bold: bool = false,
    dim: bool = false,
    italic: bool = false,
    blink: bool = false,
    reverse: bool = false,
    invisible: bool = false,
    strikethrough: bool = false,

    pub const Underline = enum {
        off,
        single,
        double,
        curly,
        dotted,
        dashed,
    };
};
