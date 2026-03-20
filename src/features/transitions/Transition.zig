//! Slide transition interface and types
const std = @import("std");
const tui = @import("../../tui/root.zig");

/// Types of slide transitions
pub const TransitionType = enum {
    none,
    fade,
    slide_left,
    slide_right,
    slide_up,
    slide_down,
    dissolve,
    wipe_left,
    wipe_right,
    wipe_up,
    wipe_down,

    /// Get transition type from string name
    pub fn fromString(name: []const u8) ?TransitionType {
        const map = std.StaticStringMap(TransitionType).initComptime(.{
            .{ "none", .none },
            .{ "fade", .fade },
            .{ "slide-left", .slide_left },
            .{ "slide-right", .slide_right },
            .{ "slide-up", .slide_up },
            .{ "slide-down", .slide_down },
            .{ "dissolve", .dissolve },
            .{ "wipe-left", .wipe_left },
            .{ "wipe-right", .wipe_right },
            .{ "wipe-up", .wipe_up },
            .{ "wipe-down", .wipe_down },
        });
        return map.get(name);
    }

    /// Convert to string representation
    pub fn toString(self: TransitionType) []const u8 {
        return switch (self) {
            .none => "none",
            .fade => "fade",
            .slide_left => "slide-left",
            .slide_right => "slide-right",
            .slide_up => "slide-up",
            .slide_down => "slide-down",
            .dissolve => "dissolve",
            .wipe_left => "wipe-left",
            .wipe_right => "wipe-right",
            .wipe_up => "wipe-up",
            .wipe_down => "wipe-down",
        };
    }
};

/// Transition direction
pub const Direction = enum {
    forward,
    backward,
};

/// Transition state
pub const TransitionState = struct {
    /// Current progress (0.0 to 1.0)
    progress: f32,
    /// From slide index
    from_slide: usize,
    /// To slide index
    to_slide: usize,
    /// Direction of transition
    direction: Direction,
    /// Type of transition
    transition_type: TransitionType,
    /// Duration in milliseconds
    duration_ms: u32,
    /// Start timestamp
    start_time_ms: i64,

    const Self = @This();

    /// Create a new transition state
    pub fn init(
        from_slide: usize,
        to_slide: usize,
        transition_type: TransitionType,
        duration_ms: u32,
        current_time_ms: i64,
    ) Self {
        return .{
            .progress = 0.0,
            .from_slide = from_slide,
            .to_slide = to_slide,
            .direction = if (to_slide > from_slide) .forward else .backward,
            .transition_type = transition_type,
            .duration_ms = duration_ms,
            .start_time_ms = current_time_ms,
        };
    }

    /// Update progress based on current time
    /// Returns true if transition is complete
    pub fn update(self: *Self, current_time_ms: i64) bool {
        const elapsed = current_time_ms - self.start_time_ms;
        if (elapsed >= self.duration_ms) {
            self.progress = 1.0;
            return true;
        }
        self.progress = @as(f32, @floatFromInt(elapsed)) / @as(f32, @floatFromInt(self.duration_ms));
        return false;
    }

    /// Check if transition is complete
    pub fn isComplete(self: Self) bool {
        return self.progress >= 1.0;
    }

    /// Get eased progress (smooth interpolation)
    pub fn getEasedProgress(self: Self) f32 {
        // Use ease-in-out cubic
        const t = self.progress;
        if (t < 0.5) {
            return 4.0 * t * t * t;
        } else {
            const f = ((2.0 * t) - 2.0);
            return 1.0 + (f * f * f) / 2.0;
        }
    }
};

/// Transition configuration
pub const TransitionConfig = struct {
    /// Default transition type
    default_type: TransitionType = .fade,
    /// Default duration in milliseconds
    default_duration_ms: u32 = 300,
    /// Whether transitions are enabled
    // Disabled by default: transition buffers hold Cell grapheme slices that can
    // become dangling pointers when the screen is re-rendered. Needs deep-copy of
    // grapheme data in CellBuffer.captureFromWindow() to work correctly.
    enabled: bool = false,

    /// Parse from string (for config)
    pub fn parseType(self: TransitionConfig, name: []const u8) TransitionType {
        _ = self;
        return TransitionType.fromString(name) orelse .none;
    }
};

/// Cell buffer for storing slide snapshots
pub const CellBuffer = struct {
    width: usize,
    height: usize,
    cells: []tui.Cell,

    const Self = @This();

    /// Initialize cell buffer
    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Self {
        const cells = try allocator.alloc(tui.Cell, width * height);
        @memset(cells, tui.Cell{});
        return .{
            .width = width,
            .height = height,
            .cells = cells,
        };
    }

    /// Deinitialize cell buffer
    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        allocator.free(self.cells);
    }

    /// Get cell at position
    pub fn getCell(self: Self, x: usize, y: usize) ?tui.Cell {
        if (x >= self.width or y >= self.height) return null;
        return self.cells[y * self.width + x];
    }

    /// Set cell at position
    pub fn setCell(self: *Self, x: usize, y: usize, cell: tui.Cell) void {
        if (x >= self.width or y >= self.height) return;
        self.cells[y * self.width + x] = cell;
    }

    /// Clear buffer
    pub fn clear(self: *Self) void {
        @memset(self.cells, tui.Cell{});
    }

    /// Capture window contents
    pub fn captureFromWindow(self: *Self, win: tui.Window) void {
        const w = @min(self.width, win.width);
        const h = @min(self.height, win.height);

        for (0..h) |y| {
            for (0..w) |x| {
                if (win.readCell(@intCast(x), @intCast(y))) |cell| {
                    self.setCell(x, y, cell);
                }
            }
        }
    }
};

/// Transition interface - namespace for transition functions
pub const TransitionInterface = struct {
    /// Apply transition effect between two cell buffers
    /// progress: 0.0 = start, 1.0 = complete
    pub fn apply(
        transition_type: TransitionType,
        from_buffer: CellBuffer,
        to_buffer: CellBuffer,
        target: *CellBuffer,
        progress: f32,
        _direction: Direction,
    ) void {
        _ = _direction;
        switch (transition_type) {
            .none => applyNone(from_buffer, to_buffer, target),
            .fade => applyFade(from_buffer, to_buffer, target, progress),
            .slide_left, .slide_right, .slide_up, .slide_down => applySlide(from_buffer, to_buffer, target, progress, transition_type),
            .dissolve => applyDissolve(from_buffer, to_buffer, target, progress),
            .wipe_left, .wipe_right, .wipe_up, .wipe_down => applyWipe(from_buffer, to_buffer, target, progress, transition_type),
        }
    }

    /// No transition - just show target
    fn applyNone(from_buffer: CellBuffer, to_buffer: CellBuffer, target: *CellBuffer) void {
        _ = from_buffer;
        // Copy to_buffer to target
        const w = @min(to_buffer.width, target.width);
        const h = @min(to_buffer.height, target.height);
        for (0..h) |y| {
            for (0..w) |x| {
                if (to_buffer.getCell(x, y)) |cell| {
                    target.setCell(x, y, cell);
                }
            }
        }
    }

    /// Fade transition
    fn applyFade(from_buffer: CellBuffer, to_buffer: CellBuffer, target: *CellBuffer, progress: f32) void {
        const w = @min(@min(from_buffer.width, to_buffer.width), target.width);
        const h = @min(@min(from_buffer.height, to_buffer.height), target.height);

        // Simple fade: blend character visibility based on progress
        // For terminal, we switch at 0.5 threshold
        const threshold: f32 = 0.5;

        for (0..h) |y| {
            for (0..w) |x| {
                if (progress < threshold) {
                    // Show from slide fading out
                    if (from_buffer.getCell(x, y)) |cell| {
                        var faded = cell;
                        // Reduce intensity by using dimmer colors or default
                        if (progress < threshold / 2) {
                            target.setCell(x, y, faded);
                        } else {
                            faded.style = .{}; // Clear styling for fade effect
                            target.setCell(x, y, faded);
                        }
                    }
                } else {
                    // Show to slide fading in
                    if (to_buffer.getCell(x, y)) |cell| {
                        var faded = cell;
                        if (progress > threshold + (1.0 - threshold) / 2) {
                            target.setCell(x, y, faded);
                        } else {
                            faded.style = .{};
                            target.setCell(x, y, faded);
                        }
                    }
                }
            }
        }
    }

    /// Slide transition
    fn applySlide(
        from_buffer: CellBuffer,
        to_buffer: CellBuffer,
        target: *CellBuffer,
        progress: f32,
        slide_type: TransitionType,
    ) void {
        const w = @min(@min(from_buffer.width, to_buffer.width), target.width);
        const h = @min(@min(from_buffer.height, to_buffer.height), target.height);

        const offset_f = progress * @as(f32, @floatFromInt(if (slide_type == .slide_left or slide_type == .slide_right) w else h));
        const offset: usize = @intFromFloat(offset_f);

        // Clear target first
        target.clear();

        switch (slide_type) {
            .slide_left => {
                // From slides left, to comes from right
                for (0..h) |y| {
                    for (offset..w) |x| {
                        if (from_buffer.getCell(x, y)) |cell| {
                            target.setCell(x - offset, y, cell);
                        }
                    }
                    for (0..offset) |x| {
                        const src_x = w - offset + x;
                        if (src_x < to_buffer.width) {
                            if (to_buffer.getCell(src_x, y)) |cell| {
                                target.setCell(x, y, cell);
                            }
                        }
                    }
                }
            },
            .slide_right => {
                // From slides right, to comes from left
                for (0..h) |y| {
                    for (0..w - offset) |x| {
                        if (from_buffer.getCell(x, y)) |cell| {
                            target.setCell(x + offset, y, cell);
                        }
                    }
                    for (0..offset) |x| {
                        if (to_buffer.getCell(x, y)) |cell| {
                            target.setCell(x, y, cell);
                        }
                    }
                }
            },
            .slide_up => {
                // From slides up, to comes from below
                for (offset..h) |y| {
                    for (0..w) |x| {
                        if (from_buffer.getCell(x, y)) |cell| {
                            target.setCell(x, y - offset, cell);
                        }
                    }
                }
                for (0..offset) |y| {
                    const src_y = h - offset + y;
                    if (src_y < to_buffer.height) {
                        for (0..w) |x| {
                            if (to_buffer.getCell(x, src_y)) |cell| {
                                target.setCell(x, y, cell);
                            }
                        }
                    }
                }
            },
            .slide_down => {
                // From slides down, to comes from above
                for (0..h - offset) |y| {
                    for (0..w) |x| {
                        if (from_buffer.getCell(x, y)) |cell| {
                            target.setCell(x, y + offset, cell);
                        }
                    }
                }
                for (0..offset) |y| {
                    for (0..w) |x| {
                        if (to_buffer.getCell(x, y)) |cell| {
                            target.setCell(x, y, cell);
                        }
                    }
                }
            },
            else => {},
        }
    }

    /// Dissolve transition (random pixelation effect)
    fn applyDissolve(
        from_buffer: CellBuffer,
        to_buffer: CellBuffer,
        target: *CellBuffer,
        progress: f32,
    ) void {
        const w = @min(@min(from_buffer.width, to_buffer.width), target.width);
        const h = @min(@min(from_buffer.height, to_buffer.height), target.height);

        // Simple deterministic "random" using position
        for (0..h) |y| {
            for (0..w) |x| {
                const hash = (x * 374761393 + y * 668265263) % 100;
                const threshold = @as(i32, @intFromFloat(progress * 100));

                if (hash < threshold) {
                    if (to_buffer.getCell(x, y)) |cell| {
                        target.setCell(x, y, cell);
                    }
                } else {
                    if (from_buffer.getCell(x, y)) |cell| {
                        target.setCell(x, y, cell);
                    }
                }
            }
        }
    }

    /// Wipe transition
    fn applyWipe(
        from_buffer: CellBuffer,
        to_buffer: CellBuffer,
        target: *CellBuffer,
        progress: f32,
        wipe_type: TransitionType,
    ) void {
        const w = @min(@min(from_buffer.width, to_buffer.width), target.width);
        const h = @min(@min(from_buffer.height, to_buffer.height), target.height);

        const threshold: usize = switch (wipe_type) {
            .wipe_left, .wipe_right => @intFromFloat(progress * @as(f32, @floatFromInt(w))),
            .wipe_up, .wipe_down => @intFromFloat(progress * @as(f32, @floatFromInt(h))),
            else => 0,
        };

        for (0..h) |y| {
            for (0..w) |x| {
                const show_to = switch (wipe_type) {
                    .wipe_left => x < threshold,
                    .wipe_right => x >= w - threshold,
                    .wipe_up => y < threshold,
                    .wipe_down => y >= h - threshold,
                    else => false,
                };

                if (show_to) {
                    if (to_buffer.getCell(x, y)) |cell| {
                        target.setCell(x, y, cell);
                    }
                } else {
                    if (from_buffer.getCell(x, y)) |cell| {
                        target.setCell(x, y, cell);
                    }
                }
            }
        }
    }
};

// Tests
test "TransitionType fromString/toString" {
    const testing = std.testing;

    try testing.expectEqual(TransitionType.fade, TransitionType.fromString("fade").?);
    try testing.expectEqual(TransitionType.slide_left, TransitionType.fromString("slide-left").?);
    try testing.expectEqual(TransitionType.none, TransitionType.fromString("none").?);
    try testing.expectEqual(null, TransitionType.fromString("invalid"));

    try testing.expectEqualStrings("fade", TransitionType.fade.toString());
    try testing.expectEqualStrings("slide-left", TransitionType.slide_left.toString());
}

test "TransitionState init and update" {
    const testing = std.testing;

    var state = TransitionState.init(0, 1, .fade, 100, 0);
    try testing.expectEqual(@as(f32, 0.0), state.progress);
    try testing.expectEqual(@as(usize, 0), state.from_slide);
    try testing.expectEqual(@as(usize, 1), state.to_slide);

    // Halfway through
    const complete = state.update(50);
    try testing.expect(!complete);
    try testing.expect(state.progress > 0.4 and state.progress < 0.6);

    // Complete
    const done = state.update(100);
    try testing.expect(done);
    try testing.expectEqual(@as(f32, 1.0), state.progress);
}

test "CellBuffer operations" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var buffer = try CellBuffer.init(allocator, 10, 5);
    defer buffer.deinit(allocator);

    try testing.expectEqual(@as(usize, 10), buffer.width);
    try testing.expectEqual(@as(usize, 5), buffer.height);

    // Test get/set
    const cell = tui.Cell{
        .char = .{ .grapheme = "X" },
    };
    buffer.setCell(5, 2, cell);

    const retrieved = buffer.getCell(5, 2);
    try testing.expect(retrieved != null);
    try testing.expectEqualStrings("X", retrieved.?.char.grapheme);

    // Out of bounds returns null
    try testing.expectEqual(null, buffer.getCell(20, 20));
}
