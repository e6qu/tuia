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
            (cp >= 0x231A and cp <= 0x231B) or // Watch, Hourglass
            (cp >= 0x2328 and cp <= 0x2328) or // Keyboard
            (cp >= 0x23E9 and cp <= 0x23F3) or // Media controls
            (cp >= 0x23F8 and cp <= 0x23FA) or // Media controls
            (cp >= 0x25AA and cp <= 0x25AB) or // Small squares
            (cp >= 0x25B6 and cp <= 0x25B6) or // Play button
            (cp >= 0x25C0 and cp <= 0x25C0) or // Reverse play
            (cp >= 0x25FB and cp <= 0x25FE) or // Medium squares
            (cp >= 0x2600 and cp <= 0x2604) or // Sun, cloud, umbrella, etc.
            (cp >= 0x260E and cp <= 0x260E) or // Telephone
            (cp >= 0x2611 and cp <= 0x2611) or // Ballot box with check
            (cp >= 0x2614 and cp <= 0x2615) or // Umbrella, hot beverage
            (cp >= 0x2618 and cp <= 0x2618) or // Shamrock
            (cp >= 0x261D and cp <= 0x261D) or // Index finger
            (cp >= 0x2620 and cp <= 0x2620) or // Skull and crossbones
            (cp >= 0x2622 and cp <= 0x2623) or // Radioactive, biohazard
            (cp >= 0x2626 and cp <= 0x2626) or // Orthodox cross
            (cp >= 0x262A and cp <= 0x262A) or // Star and crescent
            (cp >= 0x262E and cp <= 0x262F) or // Peace, yin yang
            (cp >= 0x2638 and cp <= 0x263A) or // Wheel, frowning, smiling
            (cp >= 0x2640 and cp <= 0x2640) or // Female sign
            (cp >= 0x2642 and cp <= 0x2642) or // Male sign
            (cp >= 0x2648 and cp <= 0x2653) or // Zodiac signs
            (cp >= 0x265F and cp <= 0x2660) or // Chess pawn, spade
            (cp >= 0x2663 and cp <= 0x2663) or // Club
            (cp >= 0x2665 and cp <= 0x2666) or // Heart, diamond
            (cp >= 0x2668 and cp <= 0x2668) or // Hot springs
            (cp >= 0x267B and cp <= 0x267B) or // Recycling
            (cp >= 0x267E and cp <= 0x267F) or // Infinity, wheelchair
            (cp >= 0x2692 and cp <= 0x2697) or // Hammer, tools
            (cp >= 0x2699 and cp <= 0x2699) or // Gear
            (cp >= 0x269B and cp <= 0x269C) or // Atom, fleur-de-lis
            (cp >= 0x26A0 and cp <= 0x26A1) or // Warning, high voltage
            (cp >= 0x26AA and cp <= 0x26AB) or // Circles
            (cp >= 0x26B0 and cp <= 0x26B1) or // Coffin, urn
            (cp >= 0x26BD and cp <= 0x26BE) or // Soccer, baseball
            (cp >= 0x26C4 and cp <= 0x26C5) or // Snowman, sun behind cloud
            (cp >= 0x26CE and cp <= 0x26CE) or // Ophiuchus
            (cp >= 0x26CF and cp <= 0x26CF) or // Pick
            (cp >= 0x26D1 and cp <= 0x26D1) or // Helmet
            (cp >= 0x26D3 and cp <= 0x26D4) or // Chains, no entry
            (cp >= 0x26E9 and cp <= 0x26EA) or // Shinto shrine, church
            (cp >= 0x26F0 and cp <= 0x26F5) or // Mountain, umbrella, person, etc.
            (cp >= 0x26F7 and cp <= 0x26FA) or // Skier, ice skater, etc.
            (cp >= 0x26FD and cp <= 0x26FD) or // Fuel pump
            (cp >= 0x2702 and cp <= 0x2702) or // Scissors
            (cp >= 0x2705 and cp <= 0x2705) or // White check mark
            (cp >= 0x2708 and cp <= 0x270D) or // Airplane, envelope, etc.
            (cp >= 0x270F and cp <= 0x270F) or // Pencil
            (cp >= 0x2712 and cp <= 0x2712) or // Black nib
            (cp >= 0x2714 and cp <= 0x2714) or // Heavy check mark
            (cp >= 0x2716 and cp <= 0x2716) or // Heavy multiplication X
            (cp >= 0x271D and cp <= 0x271D) or // Latin cross
            (cp >= 0x2721 and cp <= 0x2721) or // Star of David
            (cp >= 0x2728 and cp <= 0x2728) or // Sparkles
            (cp >= 0x2733 and cp <= 0x2734) or // Eight spoked asterisk
            (cp >= 0x2744 and cp <= 0x2744) or // Snowflake
            (cp >= 0x2747 and cp <= 0x2747) or // Sparkle
            (cp >= 0x274C and cp <= 0x274C) or // Cross mark
            (cp >= 0x274E and cp <= 0x274E) or // Cross mark in box
            (cp >= 0x2753 and cp <= 0x2755) or // Question marks
            (cp >= 0x2757 and cp <= 0x2757) or // Heavy exclamation mark
            (cp >= 0x2763 and cp <= 0x2764) or // Heart exclamation, heavy heart
            (cp >= 0x2795 and cp <= 0x2797) or // Plus, minus, division
            (cp >= 0x27A1 and cp <= 0x27A1) or // Right arrow
            (cp >= 0x27B0 and cp <= 0x27B0) or // Curly loop
            (cp >= 0x27BF and cp <= 0x27BF) or // Double curly loop
            (cp >= 0x2934 and cp <= 0x2935) or // Right arrow curving up/down
            (cp >= 0x2B05 and cp <= 0x2B07) or // Left/up/down arrows
            (cp >= 0x2B1B and cp <= 0x2B1C) or // Black/white large square
            (cp >= 0x2B50 and cp <= 0x2B50) or // White medium star
            (cp >= 0x2B55 and cp <= 0x2B55) or // Heavy large circle
            (cp >= 0x2E80 and cp <= 0x303E) or // CJK radicals
            (cp >= 0x3040 and cp <= 0x9FFF) or // Hiragana, Katakana, CJK Unified
            (cp >= 0xAC00 and cp <= 0xD7AF) or // Hangul syllables
            (cp >= 0xF900 and cp <= 0xFAFF) or // CJK Compatibility Ideographs
            (cp >= 0xFE30 and cp <= 0xFE6F) or // CJK Compatibility Forms
            (cp >= 0xFF01 and cp <= 0xFF60) or // Fullwidth forms
            (cp >= 0x1F004 and cp <= 0x1F004) or // Mahjong red dragon
            (cp >= 0x1F0CF and cp <= 0x1F0CF) or // Joker
            (cp >= 0x1F170 and cp <= 0x1F171) or // Negative squared A/B
            (cp >= 0x1F17E and cp <= 0x1F17F) or // Negative squared O/P
            (cp >= 0x1F18E and cp <= 0x1F18E) or // Negative squared AB
            (cp >= 0x1F191 and cp <= 0x1F19A) or // Squared CL, COOL, etc.
            (cp >= 0x1F1E0 and cp <= 0x1F1FF) or // Regional indicator symbols (flags)
            (cp >= 0x1F200 and cp <= 0x1F202) or // Enclosed ideographic supplemental
            (cp >= 0x1F210 and cp <= 0x1F23B) or // Enclosed ideographic supplemental
            (cp >= 0x1F240 and cp <= 0x1F248) or // Enclosed ideographic supplemental
            (cp >= 0x1F250 and cp <= 0x1F251) or // Enclosed ideographic supplemental
            (cp >= 0x1F300 and cp <= 0x1F9FF) or // Misc Symbols/Emoji
            (cp >= 0x1FA00 and cp <= 0x1FA6F) or // Chess/extended-A
            (cp >= 0x1FA70 and cp <= 0x1FAFF) or // Symbols extended-A
            (cp >= 0x20000 and cp <= 0x2FFFF)) // CJK Extension B+
            return 2;
        // Zero-width characters
        if (cp == 0xFE0F or // Variation Selector-16 (emoji presentation)
            cp == 0xFE0E or // Variation Selector-15 (text presentation)
            cp == 0x200D or // Zero Width Joiner
            (cp >= 0xFE00 and cp <= 0xFE0F) or // Variation selectors
            (cp >= 0x1F3FB and cp <= 0x1F3FF)) // Skin tone modifiers
            return 0;
        return 1;
    }
};
