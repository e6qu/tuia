//! Status bar widget for displaying slide info and messages
const std = @import("std");
const vaxis = @import("vaxis");
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
        win: vaxis.Window,
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
        for (0..win.width) |col| {
            const cell = win.cellIndex(.{ .row = @intCast(row), .col = @intCast(col) });
            win.setCell(cell, .{
                .char = .{ .grapheme = " " },
                .style = .{
                    .fg = theme.code_block.fg,
                    .bg = theme.code_block.bg,
                },
            });
        }

        // Draw status text
        for (status, 0..) |char, col| {
            if (col >= win.width) break;
            const cell = win.cellIndex(.{ .row = @intCast(row), .col = @intCast(col) });
            win.setCell(cell, .{
                .char = .{ .grapheme = &[_]u8{char} },
                .style = .{
                    .fg = theme.code_block.fg,
                    .bg = theme.code_block.bg,
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
