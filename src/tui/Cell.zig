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
        // Zero-width characters
        if (cp == 0xFE0F or // Variation Selector-16 (emoji presentation)
            cp == 0xFE0E or // Variation Selector-15 (text presentation)
            cp == 0x200D or // Zero Width Joiner
            (cp >= 0xFE00 and cp <= 0xFE0F) or // Variation selectors
            (cp >= 0x1F3FB and cp <= 0x1F3FF)) // Skin tone modifiers
            return 0;
        // Wide characters
        if ((cp >= 0x1100 and cp <= 0x115F) or // Hangul Jamo
            (cp >= 0x2600 and cp <= 0x27BF) or // Misc symbols, Dingbats
            (cp >= 0x2B50 and cp <= 0x2B55) or // Stars, circles
            (cp >= 0x2E80 and cp <= 0x303E) or // CJK radicals
            (cp >= 0x3040 and cp <= 0x9FFF) or // Hiragana, Katakana, CJK Unified
            (cp >= 0xAC00 and cp <= 0xD7AF) or // Hangul syllables
            (cp >= 0xF900 and cp <= 0xFAFF) or // CJK Compatibility Ideographs
            (cp >= 0xFE30 and cp <= 0xFE6F) or // CJK Compatibility Forms
            (cp >= 0xFF01 and cp <= 0xFF60) or // Fullwidth forms
            (cp >= 0x1F004 and cp <= 0x1F004) or // Mahjong red dragon
            (cp >= 0x1F170 and cp <= 0x1F19A) or // Squared letters
            (cp >= 0x1F1E0 and cp <= 0x1F1FF) or // Regional indicators (flags)
            (cp >= 0x1F300 and cp <= 0x1F9FF) or // Misc Symbols/Emoji
            (cp >= 0x1FA00 and cp <= 0x1FAFF) or // Extended symbols
            (cp >= 0x20000 and cp <= 0x2FFFF)) // CJK Extension B+
            return 2;
        return 1;
    }
};
