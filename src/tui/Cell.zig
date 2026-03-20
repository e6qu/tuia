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

    /// Return the display width of a Unicode codepoint (1 or 2 columns).
    /// Wide characters include CJK ideographs, Hangul, fullwidth forms, and most emoji.
    pub fn charWidth(cp: u21) u8 {
        if ((cp >= 0x1100 and cp <= 0x115F) or // Hangul Jamo
            (cp >= 0x2E80 and cp <= 0x303E) or // CJK radicals
            (cp >= 0x3040 and cp <= 0x9FFF) or // Hiragana, Katakana, CJK Unified
            (cp >= 0xAC00 and cp <= 0xD7AF) or // Hangul syllables
            (cp >= 0xF900 and cp <= 0xFAFF) or // CJK Compatibility Ideographs
            (cp >= 0xFE30 and cp <= 0xFE6F) or // CJK Compatibility Forms
            (cp >= 0xFF01 and cp <= 0xFF60) or // Fullwidth forms
            (cp >= 0x20000 and cp <= 0x2FFFF) or // CJK Extension B+
            (cp >= 0x1F300 and cp <= 0x1F9FF) or // Misc Symbols/Emoji
            (cp >= 0x1FA00 and cp <= 0x1FA6F) or // Chess/extended-A
            (cp >= 0x1FA70 and cp <= 0x1FAFF)) // Symbols extended-A
            return 2;
        return 1;
    }
};
