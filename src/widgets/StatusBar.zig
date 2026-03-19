//! Status bar widget for displaying slide info and messages
const std = @import("std");
const tui = @import("../tui/root.zig");
const Theme = @import("../render/Theme.zig").Theme;
const Navigation = @import("../core/Navigation.zig").Navigation;

/// StatusBar displays current slide, total slides, and messages
pub const StatusBar = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        _ = allocator;
        return .{
            .allocator = undefined,
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }

    /// Draw the status bar at the bottom of the screen
    pub fn draw(
        self: Self,
        win: tui.Window,
        nav: Navigation,
        theme: Theme,
        presentation_title: ?[]const u8,
    ) void {
        _ = self;

        if (win.height == 0) return;

        const row = win.height - 1;

        // Build status line
        var buf: [256]u8 = undefined;
        const status = if (nav.message) |msg|
            msg
        else blk: {
            if (presentation_title) |title| {
                break :blk std.fmt.bufPrint(
                    &buf,
                    " {s}  Slide {d}/{d} ",
                    .{ title, nav.currentSlideNumber(), nav.total_slides },
                ) catch "";
            } else {
                break :blk std.fmt.bufPrint(
                    &buf,
                    " Slide {d}/{d} ",
                    .{ nav.currentSlideNumber(), nav.total_slides },
                ) catch "";
            }
        };

        // Draw background for entire row
        const bg_color = if (theme.code_block.bg) |c|
            if (@import("../render/Theme.zig").Theme.toRgb(c)) |rgb|
                tui.Cell.Color{ .rgb = rgb }
            else
                .default
        else
            .default;

        const fg_color = if (theme.code_block.fg) |c|
            if (@import("../render/Theme.zig").Theme.toRgb(c)) |rgb|
                tui.Cell.Color{ .rgb = rgb }
            else
                .default
        else
            .default;

        for (0..win.width) |col| {
            win.writeCell(@intCast(col), @intCast(row), .{
                .char = .{ .grapheme = " " },
                .style = .{
                    .fg = fg_color,
                    .bg = bg_color,
                },
            });
        }

        // Draw status text
        for (status, 0..) |char, col| {
            if (col >= win.width) break;
            win.writeCell(@intCast(col), @intCast(row), .{
                .char = .{ .grapheme = tui.Cell.grapheme(char) },
                .style = .{
                    .fg = fg_color,
                    .bg = bg_color,
                },
            });
        }
    }
};

test "StatusBar basic" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const status_bar = StatusBar.init(allocator);
    _ = status_bar;

    // StatusBar is stateless, just verify it compiles
}
