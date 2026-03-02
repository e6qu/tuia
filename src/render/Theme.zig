const std = @import("std");

/// Color definition for themes
pub const Color = union(enum) {
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
    rgb: struct { r: u8, g: u8, b: u8 },
};

/// Style configuration for an element type
pub const ElementStyle = struct {
    fg: ?Color = null,
    bg: ?Color = null,
    bold: ?bool = null,
    italic: ?bool = null,
    underline: ?bool = null,
    strikethrough: ?bool = null,
};

/// Complete theme definition
pub const Theme = struct {
    name: []const u8,
    author: ?[]const u8,
    description: ?[]const u8,

    // Element styles
    heading1: ElementStyle,
    heading2: ElementStyle,
    heading3: ElementStyle,
    heading4: ElementStyle,
    heading5: ElementStyle,
    heading6: ElementStyle,
    paragraph: ElementStyle,
    code_block: ElementStyle,
    code_inline: ElementStyle,
    blockquote: ElementStyle,
    list_bullet: ElementStyle,
    list_number: ElementStyle,
    link: ElementStyle,
    image: ElementStyle,
    emphasis: ElementStyle,
    strong: ElementStyle,
    thematic_break: ElementStyle,

    pub fn deinit(self: Theme, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        if (self.author) |a| allocator.free(a);
        if (self.description) |d| allocator.free(d);
    }

    /// Get style for heading level (1-6)
    pub fn getHeadingStyle(self: Theme, level: u8) ElementStyle {
        return switch (@min(@max(level, 1), 6)) {
            1 => self.heading1,
            2 => self.heading2,
            3 => self.heading3,
            4 => self.heading4,
            5 => self.heading5,
            6 => self.heading6,
            else => .{},
        };
    }

    /// Convert theme color to RGB values
    pub fn toRgb(color: ?Color) ?[3]u8 {
        const c = color orelse return null;
        return switch (c) {
            .default => null,
            .black => .{ 0, 0, 0 },
            .red => .{ 205, 49, 49 },
            .green => .{ 13, 188, 121 },
            .yellow => .{ 229, 229, 16 },
            .blue => .{ 36, 114, 200 },
            .magenta => .{ 188, 63, 188 },
            .cyan => .{ 17, 168, 205 },
            .white => .{ 229, 229, 229 },
            .bright_black => .{ 102, 102, 102 },
            .bright_red => .{ 241, 76, 76 },
            .bright_green => .{ 35, 209, 139 },
            .bright_yellow => .{ 245, 245, 67 },
            .bright_blue => .{ 59, 142, 234 },
            .bright_magenta => .{ 214, 112, 214 },
            .bright_cyan => .{ 41, 184, 219 },
            .bright_white => .{ 255, 255, 255 },
            .rgb => |rgb| .{ rgb.r, rgb.g, rgb.b },
        };
    }

    /// Check if element style has any properties set
    pub fn hasStyle(element_style: ElementStyle) bool {
        return element_style.fg != null or
            element_style.bg != null or
            element_style.bold != null or
            element_style.italic != null or
            element_style.underline != null or
            element_style.strikethrough != null;
    }
};

/// Built-in dark theme
pub fn darkTheme() Theme {
    return .{
        .name = "dark",
        .author = "tuia",
        .description = "Default dark theme",
        .heading1 = .{ .fg = .bright_white, .bold = true, .underline = true },
        .heading2 = .{ .fg = .bright_white, .bold = true },
        .heading3 = .{ .fg = .white, .bold = true },
        .heading4 = .{ .fg = .white, .underline = true },
        .heading5 = .{ .fg = .bright_black },
        .heading6 = .{ .fg = .bright_black, .italic = true },
        .paragraph = .{ .fg = .default },
        .code_block = .{ .fg = .bright_green, .bg = .{ .rgb = .{ .r = 40, .g = 40, .b = 40 } } },
        .code_inline = .{ .fg = .bright_green, .bg = .{ .rgb = .{ .r = 50, .g = 50, .b = 50 } } },
        .blockquote = .{ .fg = .bright_black, .italic = true },
        .list_bullet = .{ .fg = .bright_cyan },
        .list_number = .{ .fg = .bright_cyan },
        .link = .{ .fg = .bright_blue, .underline = true },
        .image = .{ .fg = .bright_magenta, .italic = true },
        .emphasis = .{ .italic = true },
        .strong = .{ .bold = true },
        .thematic_break = .{ .fg = .bright_black },
    };
}

/// Built-in light theme
pub fn lightTheme() Theme {
    return .{
        .name = "light",
        .author = "tuia",
        .description = "Default light theme",
        .heading1 = .{ .fg = .black, .bold = true, .underline = true },
        .heading2 = .{ .fg = .black, .bold = true },
        .heading3 = .{ .fg = .bright_black, .bold = true },
        .heading4 = .{ .fg = .bright_black, .underline = true },
        .heading5 = .{ .fg = .black },
        .heading6 = .{ .fg = .black, .italic = true },
        .paragraph = .{ .fg = .default },
        .code_block = .{ .fg = .{ .rgb = .{ .r = 0, .g = 100, .b = 0 } }, .bg = .{ .rgb = .{ .r = 245, .g = 245, .b = 245 } } },
        .code_inline = .{ .fg = .{ .rgb = .{ .r = 0, .g = 100, .b = 0 } }, .bg = .{ .rgb = .{ .r = 240, .g = 240, .b = 240 } } },
        .blockquote = .{ .fg = .bright_black, .italic = true },
        .list_bullet = .{ .fg = .blue },
        .list_number = .{ .fg = .blue },
        .link = .{ .fg = .blue, .underline = true },
        .image = .{ .fg = .magenta, .italic = true },
        .emphasis = .{ .italic = true },
        .strong = .{ .bold = true },
        .thematic_break = .{ .fg = .bright_black },
    };
}

// Tests
test "Theme getHeadingStyle" {
    const testing = std.testing;

    const theme = darkTheme();
    const h1 = theme.getHeadingStyle(1);
    try testing.expect(h1.bold.?);
    try testing.expect(h1.underline.?);

    const h6 = theme.getHeadingStyle(6);
    try testing.expect(h6.italic.?);
}

test "Theme color conversion" {
    const testing = std.testing;

    const red = Theme.toRgb(.red);
    try testing.expectEqual(@as(u8, 205), red.?[0]);
    try testing.expectEqual(@as(u8, 49), red.?[1]);
    try testing.expectEqual(@as(u8, 49), red.?[2]);

    const rgb = Theme.toRgb(.{ .rgb = .{ .r = 255, .g = 128, .b = 64 } });
    try testing.expectEqual(@as(u8, 255), rgb.?[0]);
    try testing.expectEqual(@as(u8, 128), rgb.?[1]);
    try testing.expectEqual(@as(u8, 64), rgb.?[2]);
}

test "Dark and light themes" {
    const testing = std.testing;

    const dark = darkTheme();
    try testing.expectEqualStrings("dark", dark.name);

    const light = lightTheme();
    try testing.expectEqualStrings("light", light.name);
}
