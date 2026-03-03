//! Presentation overlay widget for laser pointer, drawing, and annotations
const std = @import("std");
const vaxis = @import("vaxis");
const Theme = @import("../render/Theme.zig").Theme;

/// Overlay mode
pub const OverlayMode = enum {
    none,
    laser,
    draw,
};

/// Drawing cell/character
pub const DrawingCell = struct {
    x: usize,
    y: usize,
    char: u21,
    style: vaxis.Style,
};

/// Presentation overlay for laser pointer, drawing, and annotations
pub const PresentationOverlay = struct {
    allocator: std.mem.Allocator,

    // Mode
    mode: OverlayMode = .none,

    // Laser pointer position
    laser_x: usize = 0,
    laser_y: usize = 0,

    // Drawing state
    drawing_cells: std.ArrayList(DrawingCell),
    current_char: u21 = '█',
    draw_color: vaxis.Color = .{ .index = 196 }, // Red by default

    // Theme switching
    theme_names: []const []const u8 = &.{ "dark", "light" },
    current_theme_index: usize = 0,
    show_theme_picker: bool = false,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .drawing_cells = .empty,
        };
    }

    pub fn deinit(self: *Self) void {
        self.drawing_cells.deinit(self.allocator);
    }

    /// Toggle laser pointer mode
    pub fn toggleLaserMode(self: *Self) void {
        self.mode = if (self.mode == .laser) .none else .laser;
        self.show_theme_picker = false;
    }

    /// Toggle drawing mode
    pub fn toggleDrawMode(self: *Self) void {
        self.mode = if (self.mode == .draw) .none else .draw;
        self.show_theme_picker = false;
    }

    /// Check if in laser mode
    pub fn isLaserMode(self: Self) bool {
        return self.mode == .laser;
    }

    /// Check if in draw mode
    pub fn isDrawMode(self: Self) bool {
        return self.mode == .draw;
    }

    /// Check if any overlay mode is active
    pub fn isActive(self: Self) bool {
        return self.mode != .none or self.show_theme_picker;
    }

    /// Move laser pointer
    pub fn moveLaser(self: *Self, dx: i32, dy: i32, max_x: usize, max_y: usize) void {
        if (self.mode != .laser) return;

        const new_x = @as(i32, @intCast(self.laser_x)) + dx;
        const new_y = @as(i32, @intCast(self.laser_y)) + dy;

        if (new_x >= 0 and new_x < @as(i32, @intCast(max_x))) {
            self.laser_x = @intCast(new_x);
        }
        if (new_y >= 0 and new_y < @as(i32, @intCast(max_y))) {
            self.laser_y = @intCast(new_y);
        }
    }

    /// Draw at current position (in draw mode)
    pub fn drawAt(self: *Self, x: usize, y: usize) !void {
        if (self.mode != .draw) return;

        // Check if cell already exists
        for (self.drawing_cells.items) |*cell| {
            if (cell.x == x and cell.y == y) {
                cell.char = self.current_char;
                cell.style = .{ .fg = self.draw_color };
                return;
            }
        }

        // Add new cell
        try self.drawing_cells.append(self.allocator, .{
            .x = x,
            .y = y,
            .char = self.current_char,
            .style = .{ .fg = self.draw_color },
        });
    }

    /// Clear all drawings
    pub fn clearDrawings(self: *Self) void {
        self.drawing_cells.clearRetainingCapacity();
    }

    /// Toggle theme picker
    pub fn toggleThemePicker(self: *Self) void {
        self.show_theme_picker = !self.show_theme_picker;
        self.mode = .none;
    }

    /// Cycle to next theme
    pub fn nextTheme(self: *Self) void {
        if (self.theme_names.len == 0) return;
        self.current_theme_index = (self.current_theme_index + 1) % self.theme_names.len;
    }

    /// Cycle to previous theme
    pub fn prevTheme(self: *Self) void {
        if (self.theme_names.len == 0) return;
        self.current_theme_index = if (self.current_theme_index == 0)
            self.theme_names.len - 1
        else
            self.current_theme_index - 1;
    }

    /// Get current theme name
    pub fn getCurrentThemeName(self: Self) ?[]const u8 {
        if (self.theme_names.len == 0) return null;
        return self.theme_names[self.current_theme_index];
    }

    /// Set laser position
    pub fn setLaserPosition(self: *Self, x: usize, y: usize) void {
        self.laser_x = x;
        self.laser_y = y;
    }

    /// Draw the overlay
    pub fn draw(self: *Self, win: vaxis.Window, slide_width: usize, slide_height: usize) void {
        // Draw laser pointer
        if (self.mode == .laser) {
            if (self.laser_x < slide_width and self.laser_y < slide_height) {
                var laser_win = win.child(.{
                    .x_off = @intCast(self.laser_x),
                    .y_off = @intCast(self.laser_y),
                    .width = 1,
                    .height = 1,
                });
                laser_win.writeCell(0, 0, .{
                    .char = .{ .grapheme = "█", .width = 1 },
                    .style = .{ .fg = .{ .index = 196 } }, // Red laser
                });
            }
        }

        // Draw annotations
        if (self.mode == .draw or self.drawing_cells.items.len > 0) {
            for (self.drawing_cells.items) |cell| {
                if (cell.x < slide_width and cell.y < slide_height) {
                    var cell_win = win.child(.{
                        .x_off = @intCast(cell.x),
                        .y_off = @intCast(cell.y),
                        .width = 1,
                        .height = 1,
                    });
                    var grapheme_buf: [8]u8 = undefined;
                    const grapheme_len = std.unicode.utf8Encode(cell.char, &grapheme_buf) catch continue;
                    const grapheme = grapheme_buf[0..grapheme_len];
                    cell_win.writeCell(0, 0, .{
                        .char = .{ .grapheme = grapheme, .width = 1 },
                        .style = cell.style,
                    });
                }
            }
        }

        // Draw theme picker
        if (self.show_theme_picker) {
            self.drawThemePicker(win, slide_width, slide_height);
        }
    }

    fn drawThemePicker(self: *Self, win: vaxis.Window, slide_width: usize, slide_height: usize) void {
        _ = self;
        _ = slide_width;
        _ = slide_height;

        // Draw a simple theme picker overlay
        const picker_width = 30;
        const picker_height = 10;
        const x_off = 2;
        const y_off = 2;

        var picker_win = win.child(.{
            .x_off = x_off,
            .y_off = y_off,
            .width = picker_width,
            .height = picker_height,
        });

        // Draw border
        picker_win.fill(.{ .char = .{ .grapheme = " " }, .style = .{ .bg = .{ .index = 240 } } });

        // Draw title
        picker_win.writeCell(1, 1, .{
            .char = .{ .grapheme = "Select Theme:", .width = 13 },
            .style = .{ .fg = .{ .index = 255 }, .bg = .{ .index = 240 } },
        });

        // Draw theme options
        picker_win.writeCell(2, 3, .{
            .char = .{ .grapheme = "• dark", .width = 6 },
            .style = .{ .fg = .{ .index = 255 }, .bg = .{ .index = 240 } },
        });
        picker_win.writeCell(2, 4, .{
            .char = .{ .grapheme = "• light", .width = 7 },
            .style = .{ .fg = .{ .index = 255 }, .bg = .{ .index = 240 } },
        });
    }

    /// Reset state for new slide
    pub fn onSlideChange(self: *Self) void {
        // Keep drawings per slide? For now, clear them
        // In the future, we could store drawings per slide index
        self.drawing_cells.clearRetainingCapacity();
    }
};

test "PresentationOverlay mode toggling" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var overlay = PresentationOverlay.init(allocator);
    defer overlay.deinit();

    // Initial state
    try testing.expect(!overlay.isActive());
    try testing.expect(!overlay.isLaserMode());
    try testing.expect(!overlay.isDrawMode());

    // Toggle laser mode
    overlay.toggleLaserMode();
    try testing.expect(overlay.isLaserMode());
    try testing.expect(overlay.isActive());

    // Toggle again to turn off
    overlay.toggleLaserMode();
    try testing.expect(!overlay.isLaserMode());
    try testing.expect(!overlay.isActive());

    // Toggle draw mode
    overlay.toggleDrawMode();
    try testing.expect(overlay.isDrawMode());
    try testing.expect(overlay.isActive());
}

test "PresentationOverlay laser movement" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var overlay = PresentationOverlay.init(allocator);
    defer overlay.deinit();

    overlay.toggleLaserMode();
    overlay.setLaserPosition(10, 10);

    // Move right
    overlay.moveLaser(1, 0, 80, 24);
    try testing.expectEqual(@as(usize, 11), overlay.laser_x);
    try testing.expectEqual(@as(usize, 10), overlay.laser_y);

    // Move down
    overlay.moveLaser(0, 1, 80, 24);
    try testing.expectEqual(@as(usize, 11), overlay.laser_x);
    try testing.expectEqual(@as(usize, 11), overlay.laser_y);

    // Try to move out of bounds
    overlay.moveLaser(100, 0, 80, 24);
    try testing.expectEqual(@as(usize, 11), overlay.laser_x); // Should stay at 11
}

test "PresentationOverlay drawing" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var overlay = PresentationOverlay.init(allocator);
    defer overlay.deinit();

    overlay.toggleDrawMode();

    // Draw some cells
    try overlay.drawAt(5, 5);
    try overlay.drawAt(6, 5);
    try overlay.drawAt(7, 5);

    try testing.expectEqual(@as(usize, 3), overlay.drawing_cells.items.len);

    // Clear drawings
    overlay.clearDrawings();
    try testing.expectEqual(@as(usize, 0), overlay.drawing_cells.items.len);
}

test "PresentationOverlay theme cycling" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var overlay = PresentationOverlay.init(allocator);
    defer overlay.deinit();

    try testing.expectEqualStrings("dark", overlay.getCurrentThemeName().?);

    overlay.nextTheme();
    try testing.expectEqualStrings("light", overlay.getCurrentThemeName().?);

    overlay.nextTheme();
    try testing.expectEqualStrings("dark", overlay.getCurrentThemeName().?); // Wraps around

    overlay.prevTheme();
    try testing.expectEqualStrings("light", overlay.getCurrentThemeName().?);
}
