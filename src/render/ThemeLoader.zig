const std = @import("std");
const Theme = @import("Theme.zig").Theme;
const Color = @import("Theme.zig").Color;
const ElementStyle = @import("Theme.zig").ElementStyle;

/// ThemeLoader loads themes from YAML files
pub const ThemeLoader = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{ .allocator = allocator };
    }

    /// Load theme from YAML file
    pub fn loadFromFile(self: Self, path: []const u8) !Theme {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const content = try file.readToEndAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(content);

        return try self.loadFromString(content);
    }

    /// Load theme from YAML string (simplified parser)
    pub fn loadFromString(self: Self, content: []const u8) !Theme {
        var theme = Theme{
            .name = try self.allocator.dupe(u8, "unnamed"),
            .author = null,
            .description = null,
            .heading1 = .{},
            .heading2 = .{},
            .heading3 = .{},
            .heading4 = .{},
            .heading5 = .{},
            .heading6 = .{},
            .paragraph = .{},
            .code_block = .{},
            .code_inline = .{},
            .blockquote = .{},
            .list_bullet = .{},
            .list_number = .{},
            .link = .{},
            .image = .{},
            .emphasis = .{},
            .strong = .{},
            .thematic_break = .{},
        };

        var lines = std.mem.splitSequence(u8, content, "\n");
        var current_section: ?[]const u8 = null;
        var current_style: ElementStyle = .{};

        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \t\r");

            // Skip empty lines and comments
            if (trimmed.len == 0 or std.mem.startsWith(u8, trimmed, "#")) continue;

            // Check for section header (ends with : but not a key: value pair)
            if (std.mem.endsWith(u8, trimmed, ":") and !std.mem.containsAtLeast(u8, trimmed, 1, ": ")) {
                // Save current style before switching sections
                if (current_section) |section| {
                    try setStyle(&theme, section, current_style);
                }
                current_section = std.mem.trim(u8, trimmed, ":");
                current_style = .{};
                continue;
            }

            // Parse key: value
            if (std.mem.indexOf(u8, trimmed, ": ")) |colon_pos| {
                const key = std.mem.trim(u8, trimmed[0..colon_pos], " \t");
                const value = std.mem.trim(u8, trimmed[colon_pos + 1 ..], " \t");

                // Parse metadata (no current section)
                if (current_section == null) {
                    if (std.mem.eql(u8, key, "name")) {
                        self.allocator.free(theme.name);
                        theme.name = try self.allocator.dupe(u8, value);
                    } else if (std.mem.eql(u8, key, "author")) {
                        theme.author = try self.allocator.dupe(u8, value);
                    } else if (std.mem.eql(u8, key, "description")) {
                        theme.description = try self.allocator.dupe(u8, value);
                    }
                } else {
                    // Parse style property
                    if (std.mem.eql(u8, key, "fg")) {
                        current_style.fg = parseColor(value);
                    } else if (std.mem.eql(u8, key, "bg")) {
                        current_style.bg = parseColor(value);
                    } else if (std.mem.eql(u8, key, "bold")) {
                        current_style.bold = std.mem.eql(u8, value, "true");
                    } else if (std.mem.eql(u8, key, "italic")) {
                        current_style.italic = std.mem.eql(u8, value, "true");
                    } else if (std.mem.eql(u8, key, "underline")) {
                        current_style.underline = std.mem.eql(u8, value, "true");
                    } else if (std.mem.eql(u8, key, "strikethrough")) {
                        current_style.strikethrough = std.mem.eql(u8, value, "true");
                    }
                }
            }
        }

        // Save final section's style
        if (current_section) |section| {
            try setStyle(&theme, section, current_style);
        }

        return theme;
    }

    fn setStyle(theme: *Theme, section: []const u8, style: ElementStyle) !void {
        if (std.mem.eql(u8, section, "heading1")) {
            theme.heading1 = style;
        } else if (std.mem.eql(u8, section, "heading2")) {
            theme.heading2 = style;
        } else if (std.mem.eql(u8, section, "heading3")) {
            theme.heading3 = style;
        } else if (std.mem.eql(u8, section, "heading4")) {
            theme.heading4 = style;
        } else if (std.mem.eql(u8, section, "heading5")) {
            theme.heading5 = style;
        } else if (std.mem.eql(u8, section, "heading6")) {
            theme.heading6 = style;
        } else if (std.mem.eql(u8, section, "paragraph")) {
            theme.paragraph = style;
        } else if (std.mem.eql(u8, section, "code_block")) {
            theme.code_block = style;
        } else if (std.mem.eql(u8, section, "code_inline")) {
            theme.code_inline = style;
        } else if (std.mem.eql(u8, section, "blockquote")) {
            theme.blockquote = style;
        } else if (std.mem.eql(u8, section, "list_bullet")) {
            theme.list_bullet = style;
        } else if (std.mem.eql(u8, section, "list_number")) {
            theme.list_number = style;
        } else if (std.mem.eql(u8, section, "link")) {
            theme.link = style;
        } else if (std.mem.eql(u8, section, "image")) {
            theme.image = style;
        } else if (std.mem.eql(u8, section, "emphasis")) {
            theme.emphasis = style;
        } else if (std.mem.eql(u8, section, "strong")) {
            theme.strong = style;
        } else if (std.mem.eql(u8, section, "thematic_break")) {
            theme.thematic_break = style;
        }
    }

    /// Parse color string
    fn parseColor(color_str: []const u8) ?Color {
        const colors = std.StaticStringMap(Color).initComptime(.{
            .{ "default", .default },
            .{ "black", .black },
            .{ "red", .red },
            .{ "green", .green },
            .{ "yellow", .yellow },
            .{ "blue", .blue },
            .{ "magenta", .magenta },
            .{ "cyan", .cyan },
            .{ "white", .white },
            .{ "bright_black", .bright_black },
            .{ "bright_red", .bright_red },
            .{ "bright_green", .bright_green },
            .{ "bright_yellow", .bright_yellow },
            .{ "bright_blue", .bright_blue },
            .{ "bright_magenta", .bright_magenta },
            .{ "bright_cyan", .bright_cyan },
            .{ "bright_white", .bright_white },
        });

        return colors.get(color_str);
    }
};

// Tests
test "ThemeLoader parseColor" {
    const testing = std.testing;

    const red = ThemeLoader.parseColor("red");
    try testing.expectEqual(Color.red, red.?);

    const bright_blue = ThemeLoader.parseColor("bright_blue");
    try testing.expectEqual(Color.bright_blue, bright_blue.?);

    const unknown = ThemeLoader.parseColor("unknown");
    try testing.expect(unknown == null);
}

test "ThemeLoader loadFromString" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const yaml =
        \\name: test-theme
        \\author: Test Author
        \\
        \\heading1:
        \\  fg: red
        \\  bold: true
        \\paragraph:
        \\  fg: blue
    ;

    var loader = ThemeLoader.init(allocator);
    const theme = try loader.loadFromString(yaml);
    defer theme.deinit(allocator);

    try testing.expectEqualStrings("test-theme", theme.name);
    try testing.expectEqualStrings("Test Author", theme.author.?);
    try testing.expectEqual(Color.red, theme.heading1.fg.?);
    try testing.expect(theme.heading1.bold.?);
    try testing.expectEqual(Color.blue, theme.paragraph.fg.?);
}
