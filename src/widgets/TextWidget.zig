//! Text widget for rendering headings, paragraphs, and blockquotes
const std = @import("std");
const vaxis = @import("vaxis");
const Widget = @import("Widget.zig").Widget;
const DrawContext = @import("Widget.zig").DrawContext;
const Constraints = @import("Widget.zig").Constraints;
const Size = @import("Widget.zig").Size;
const DrawUtils = @import("Widget.zig").DrawUtils;
const toVaxisStyle = @import("Widget.zig").toVaxisStyle;

/// Text widget types
pub const TextType = enum {
    heading,
    paragraph,
    blockquote,
    thematic_break,
};

/// TextWidget renders text elements (headings, paragraphs, blockquotes)
pub const TextWidget = struct {
    allocator: std.mem.Allocator,
    text: []const u8,
    text_type: TextType,
    heading_level: u8 = 0,

    const Self = @This();

    /// Initialize as heading
    pub fn initHeading(allocator: std.mem.Allocator, text: []const u8, level: u8) !*Self {
        const self = try allocator.create(Self);
        self.* = .{
            .allocator = allocator,
            .text = try allocator.dupe(u8, text),
            .text_type = .heading,
            .heading_level = @min(level, 6),
        };
        return self;
    }

    /// Initialize as paragraph
    pub fn initParagraph(allocator: std.mem.Allocator, text: []const u8) !*Self {
        const self = try allocator.create(Self);
        self.* = .{
            .allocator = allocator,
            .text = try allocator.dupe(u8, text),
            .text_type = .paragraph,
        };
        return self;
    }

    /// Initialize as blockquote
    pub fn initBlockquote(allocator: std.mem.Allocator, text: []const u8) !*Self {
        const self = try allocator.create(Self);
        self.* = .{
            .allocator = allocator,
            .text = try allocator.dupe(u8, text),
            .text_type = .blockquote,
        };
        return self;
    }

    /// Initialize as thematic break (horizontal rule)
    pub fn initThematicBreak(allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);
        self.* = .{
            .allocator = allocator,
            .text = &.{}, // Empty slice (not a literal), won't be freed
            .text_type = .thematic_break,
        };
        return self;
    }

    /// Clean up resources
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.text);
        self.allocator.destroy(self);
    }

    /// Get the element style based on text type and heading level
    fn getStyle(self: Self, theme: @import("../render/Theme.zig").Theme) @import("../render/Theme.zig").ElementStyle {
        return switch (self.text_type) {
            .heading => theme.getHeadingStyle(self.heading_level),
            .paragraph => theme.paragraph,
            .blockquote => theme.blockquote,
            .thematic_break => theme.thematic_break,
        };
    }

    /// Draw the text widget
    pub fn draw(self: *Self, ctx: DrawContext, x: usize, y: usize) void {
        const style = self.getStyle(ctx.theme);
        const vaxis_style = toVaxisStyle(style);

        switch (self.text_type) {
            .thematic_break => {
                self.drawThematicBreak(ctx, x, y, vaxis_style);
            },
            .blockquote => {
                self.drawBlockquote(ctx, x, y, vaxis_style);
            },
            else => {
                // Heading or paragraph - just draw the text
                const max_width = if (ctx.win.width > x) ctx.win.width - x else 0;
                _ = DrawUtils.drawTextWrapped(ctx.win, x, y, self.text, vaxis_style, max_width);
            },
        }
    }

    /// Get the size of the widget
    pub fn getSize(self: *Self, constraints: Constraints) Size {
        const available_width = @min(constraints.max_width, 80); // Default max width

        return switch (self.text_type) {
            .thematic_break => .{
                .width = @min(available_width, 40),
                .height = 1,
            },
            else => {
                const lines = DrawUtils.measureWrappedLines(self.text, available_width);
                return .{
                    .width = @min(self.text.len, available_width),
                    .height = lines,
                };
            },
        };
    }

    fn drawThematicBreak(self: Self, ctx: DrawContext, x: usize, y: usize, style: vaxis.Style) void {
        _ = self;
        const width = @min(40, ctx.win.width - x);
        if (width == 0) return;

        for (0..width) |col| {
            const target_col = x + col;
            if (target_col >= ctx.win.width) break;

            _ = ctx.win.writeCell(@intCast(target_col), @intCast(y), .{
                .char = .{ .grapheme = "─" },
                .style = style,
            });
        }
    }

    fn drawBlockquote(self: *Self, ctx: DrawContext, x: usize, y: usize, style: vaxis.Style) void {
        const max_width = if (ctx.win.width > x + 2) ctx.win.width - x - 2 else 0;

        // Draw border line
        if (x < ctx.win.width) {
            _ = ctx.win.writeCell(@intCast(x), @intCast(y), .{
                .char = .{ .grapheme = "│" },
                .style = style,
            });
        }

        // Draw text with indentation
        _ = DrawUtils.drawTextWrapped(ctx.win, x + 2, y, self.text, style, max_width);
    }
};

test "TextWidget heading" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var widget = try TextWidget.initHeading(allocator, "Hello World", 1);
    defer widget.deinit();

    try testing.expectEqual(TextType.heading, widget.text_type);
    try testing.expectEqual(@as(u8, 1), widget.heading_level);
    try testing.expectEqualStrings("Hello World", widget.text);
}

test "TextWidget paragraph" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var widget = try TextWidget.initParagraph(allocator, "This is a paragraph.");
    defer widget.deinit();

    try testing.expectEqual(TextType.paragraph, widget.text_type);
    try testing.expectEqualStrings("This is a paragraph.", widget.text);
}

test "TextWidget size calculation" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var widget = try TextWidget.initParagraph(allocator, "Short text");
    defer widget.deinit();

    const size = widget.getSize(.{ .max_width = 100 });
    try testing.expect(size.width > 0);
    try testing.expectEqual(@as(usize, 1), size.height);
}

test "TextWidget thematic break" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var widget = try TextWidget.initThematicBreak(allocator);
    defer widget.deinit();

    try testing.expectEqual(TextType.thematic_break, widget.text_type);

    const size = widget.getSize(.{ .max_width = 100 });
    try testing.expectEqual(@as(usize, 1), size.height);
}
