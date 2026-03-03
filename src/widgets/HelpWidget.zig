//! Help widget for displaying keyboard shortcuts
const std = @import("std");
const vaxis = @import("vaxis");
const Widget = @import("Widget.zig").Widget;
const Slide = @import("../core/Slide.zig").Slide;
const Theme = @import("../render/Theme.zig").Theme;

/// HelpWidget displays a help overlay with keyboard shortcuts
pub const HelpWidget = struct {
    allocator: std.mem.Allocator,
    visible: bool = false,

    const Self = @This();

    /// Help text content
    const HELP_TEXT =
        \\╭──────────────────────────────────────────╮
        \\│  TUIA Help - Keyboard Shortcuts          │
        \\├──────────────────────────────────────────┤
        \\│                                          │
        \\│  Navigation:                             │
        \\│    j, l, →, ↓, Space    Next slide       │
        \\│    k, h, ←, ↑, Back     Previous slide   │
        \\│    g                    First slide      │
        \\│    G                    Last slide       │
        \\│    1-9, Enter           Go to slide N    │
        \\│                                          │
        \\│  Presentation Tools:                     │
        \\│    L                    Toggle laser     │
        \\│    h/j/k/l (in laser)   Move laser       │
        \\│    D                    Toggle drawing   │
        \\│    Space (in draw)      Draw at cursor   │
        \\│    C                    Clear drawings   │
        \\│    t                    Switch theme     │
        \\│                                          │
        \\│  View:                                   │
        \\│    ?, F1                Toggle help      │
        \\│    o                    Toggle overview  │
        \\│                                          │
        \\│  General:                                │
        \\│    q, Esc               Quit             │
        \\│                                          │
        \\╰──────────────────────────────────────────╯
        \\
    ;

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .visible = false,
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }

    pub fn toggle(self: *Self) void {
        self.visible = !self.visible;
    }

    pub fn show(self: *Self) void {
        self.visible = true;
    }

    pub fn hide(self: *Self) void {
        self.visible = false;
    }

    /// Draw the help overlay centered on screen
    pub fn draw(self: Self, win: vaxis.Window, theme: Theme) void {
        if (!self.visible) return;

        // Calculate dimensions
        var max_width: usize = 0;
        var line_count: usize = 0;
        {
            var iter = std.mem.splitScalar(u8, HELP_TEXT, '\n');
            while (iter.next()) |line| {
                max_width = @max(max_width, line.len);
                line_count += 1;
            }
        }

        // Center on screen
        const start_row = @divTrunc(win.height, 2) - @divTrunc(line_count, 2);
        const start_col = @divTrunc(win.width, 2) - @divTrunc(max_width, 2);

        // Draw background box
        for (0..line_count + 2) |row| {
            const r = start_row + row - 1;
            if (r >= win.height) continue;
            for (0..max_width + 4) |col| {
                const c = start_col + col - 2;
                if (c >= win.width) continue;
                const bg_color = if (theme.code_block.bg) |color|
                    if (@import("../render/Theme.zig").Theme.toRgb(color)) |rgb|
                        @import("vaxis").Cell.Color{ .rgb = rgb }
                    else
                        .default
                else
                    .default;

                _ = win.writeCell(@intCast(c), @intCast(r), .{
                    .char = .{ .grapheme = " " },
                    .style = .{
                        .bg = bg_color,
                    },
                });
            }
        }

        // Draw help text
        var iter = std.mem.splitScalar(u8, HELP_TEXT, '\n');
        var row: usize = 0;
        while (iter.next()) |line| : (row += 1) {
            const r = start_row + row;
            if (r >= win.height) break;

            for (line, 0..) |char, col| {
                const c = start_col + col;
                if (c >= win.width) break;

                const fg_color = if (theme.code_block.fg) |color|
                    if (@import("../render/Theme.zig").Theme.toRgb(color)) |rgb|
                        @import("vaxis").Cell.Color{ .rgb = rgb }
                    else
                        .default
                else
                    .default;

                _ = win.writeCell(@intCast(c), @intCast(r), .{
                    .char = .{ .grapheme = &[_]u8{char} },
                    .style = .{
                        .fg = fg_color,
                    },
                });
            }
        }
    }

    /// Get the height needed for the help widget
    pub fn getHeight(self: Self) usize {
        _ = self;
        var count: usize = 0;
        var iter = std.mem.splitScalar(u8, HELP_TEXT, '\n');
        while (iter.next()) |_| count += 1;
        return count;
    }

    /// Get the width needed for the help widget
    pub fn getWidth(self: Self) usize {
        _ = self;
        var max_width: usize = 0;
        var iter = std.mem.splitScalar(u8, HELP_TEXT, '\n');
        while (iter.next()) |line| {
            max_width = @max(max_width, line.len);
        }
        return max_width;
    }
};

test "HelpWidget visibility" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var widget = HelpWidget.init(allocator);
    defer widget.deinit();

    // Initially hidden
    try testing.expect(!widget.visible);

    // Toggle on
    widget.toggle();
    try testing.expect(widget.visible);

    // Toggle off
    widget.toggle();
    try testing.expect(!widget.visible);

    // Show
    widget.show();
    try testing.expect(widget.visible);

    // Hide
    widget.hide();
    try testing.expect(!widget.visible);
}
