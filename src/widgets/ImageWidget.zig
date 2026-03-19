//! Image widget for rendering images
const std = @import("std");
const tui = @import("../tui/root.zig");
const DrawContext = @import("Widget.zig").DrawContext;
const Constraints = @import("Widget.zig").Constraints;
const Size = @import("Widget.zig").Size;
const toStyle = @import("Widget.zig").toStyle;

/// ImageWidget renders images (or placeholder for unsupported terminals)
pub const ImageWidget = struct {
    allocator: std.mem.Allocator,
    url: []const u8,
    alt: []const u8,

    const Self = @This();

    /// Initialize image widget
    pub fn init(allocator: std.mem.Allocator, url: []const u8, alt: []const u8) !*Self {
        const self = try allocator.create(Self);
        self.* = .{
            .allocator = allocator,
            .url = try allocator.dupe(u8, url),
            .alt = try allocator.dupe(u8, alt),
        };
        return self;
    }

    /// Clean up resources
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.url);
        self.allocator.free(self.alt);
        self.allocator.destroy(self);
    }

    /// Draw the image widget (placeholder implementation)
    pub fn draw(self: *Self, ctx: DrawContext, x: usize, y: usize) void {
        const image_style = toStyle(ctx.theme.image);

        // Draw placeholder box with image indicator
        const display_text = if (self.alt.len > 0)
            self.alt
        else
            "[Image]";

        // Draw border
        self.drawBorder(ctx, x, y, display_text.len + 4);

        // Draw text
        const text_x = x + 2;
        if (text_x < ctx.win.width and y + 1 < ctx.win.height) {
            for (display_text, 0..) |char, i| {
                const col = text_x + i;
                if (col >= ctx.win.width) break;
                ctx.win.writeCell(@intCast(col), @intCast(y + 1), .{
                    .char = .{ .grapheme = tui.Cell.grapheme(char) },
                    .style = image_style,
                });
            }
        }
    }

    /// Get the size of the widget
    pub fn getSize(self: *Self, constraints: Constraints) Size {
        const display_text = if (self.alt.len > 0)
            self.alt.len
        else
            7; // "[Image]".len

        return .{
            .width = @min(display_text + 4, constraints.max_width),
            .height = 3, // Border + content + border
        };
    }

    fn drawBorder(self: Self, ctx: DrawContext, x: usize, y: usize, width: usize) void {
        _ = self;
        const style: tui.Style = .{ .fg = .{ .rgb = .{ 100, 100, 100 } } };

        // Top border
        if (y < ctx.win.height) {
            for (0..width) |col| {
                if (x + col >= ctx.win.width) break;
                ctx.win.writeCell(@intCast(x + col), @intCast(y), .{
                    .char = .{ .grapheme = "─" },
                    .style = style,
                });
            }
        }

        // Bottom border
        if (y + 2 < ctx.win.height) {
            for (0..width) |col| {
                if (x + col >= ctx.win.width) break;
                ctx.win.writeCell(@intCast(x + col), @intCast(y + 2), .{
                    .char = .{ .grapheme = "─" },
                    .style = style,
                });
            }
        }

        // Side borders
        if (x < ctx.win.width and y + 1 < ctx.win.height) {
            ctx.win.writeCell(@intCast(x), @intCast(y + 1), .{
                .char = .{ .grapheme = "│" },
                .style = style,
            });
        }
        if (x + width - 1 < ctx.win.width and y + 1 < ctx.win.height) {
            ctx.win.writeCell(@intCast(x + width - 1), @intCast(y + 1), .{
                .char = .{ .grapheme = "│" },
                .style = style,
            });
        }

        // Corners
        if (x < ctx.win.width and y < ctx.win.height) {
            ctx.win.writeCell(@intCast(x), @intCast(y), .{
                .char = .{ .grapheme = "┌" },
                .style = style,
            });
        }
        if (x + width - 1 < ctx.win.width and y < ctx.win.height) {
            ctx.win.writeCell(@intCast(x + width - 1), @intCast(y), .{
                .char = .{ .grapheme = "┐" },
                .style = style,
            });
        }
        if (x < ctx.win.width and y + 2 < ctx.win.height) {
            ctx.win.writeCell(@intCast(x), @intCast(y + 2), .{
                .char = .{ .grapheme = "└" },
                .style = style,
            });
        }
        if (x + width - 1 < ctx.win.width and y + 2 < ctx.win.height) {
            ctx.win.writeCell(@intCast(x + width - 1), @intCast(y + 2), .{
                .char = .{ .grapheme = "┘" },
                .style = style,
            });
        }
    }
};

test "ImageWidget basic" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var widget = try ImageWidget.init(allocator, "image.png", "Alt text");
    defer widget.deinit();

    try testing.expectEqualStrings("image.png", widget.url);
    try testing.expectEqualStrings("Alt text", widget.alt);
}

test "ImageWidget without alt" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var widget = try ImageWidget.init(allocator, "image.png", "");
    defer widget.deinit();

    const size = widget.getSize(.{ .max_width = 80 });
    try testing.expectEqual(@as(usize, 3), size.height);
}

test "ImageWidget size calculation" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var widget = try ImageWidget.init(allocator, "image.png", "My Image");
    defer widget.deinit();

    const size = widget.getSize(.{ .max_width = 80 });
    try testing.expect(size.width >= 12); // "My Image".len + 4
    try testing.expectEqual(@as(usize, 3), size.height);
}
