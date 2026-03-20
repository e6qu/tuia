//! Manages slide transitions
const std = @import("std");
const tui = @import("../../tui/root.zig");

const TransitionModule = @import("Transition.zig");
const Transition = TransitionModule.TransitionInterface;
const TransitionType = TransitionModule.TransitionType;
const TransitionState = TransitionModule.TransitionState;
const TransitionConfig = TransitionModule.TransitionConfig;
const Direction = TransitionModule.Direction;
const CellBuffer = TransitionModule.CellBuffer;

/// Manages slide transitions including capturing slide snapshots
/// and animating between them
pub const TransitionManager = struct {
    allocator: std.mem.Allocator,

    /// Current transition state (null if not transitioning)
    current_transition: ?TransitionState,

    /// Configuration
    config: TransitionConfig,

    /// Buffer for from slide
    from_buffer: ?CellBuffer,
    /// Buffer for to slide
    to_buffer: ?CellBuffer,
    /// Buffer for rendering transition
    render_buffer: ?CellBuffer,

    /// Last slide index we rendered
    last_slide_index: usize,

    /// Window dimensions (for buffer sizing)
    buffer_width: usize,
    buffer_height: usize,

    const Self = @This();

    /// Initialize the transition manager
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .current_transition = null,
            .config = .{},
            .from_buffer = null,
            .to_buffer = null,
            .render_buffer = null,
            .last_slide_index = 0,
            .buffer_width = 0,
            .buffer_height = 0,
        };
    }

    /// Clean up resources
    pub fn deinit(self: *Self) void {
        self.freeBuffers();
    }

    /// Free all buffers
    fn freeBuffers(self: *Self) void {
        if (self.from_buffer) |*buf| {
            buf.deinit(self.allocator);
            self.from_buffer = null;
        }
        if (self.to_buffer) |*buf| {
            buf.deinit(self.allocator);
            self.to_buffer = null;
        }
        if (self.render_buffer) |*buf| {
            buf.deinit(self.allocator);
            self.render_buffer = null;
        }
    }

    /// Initialize or resize buffers for window size
    pub fn resizeBuffers(self: *Self, width: usize, height: usize) !void {
        // Only reallocate if size changed significantly
        if (self.buffer_width == width and self.buffer_height == height) {
            return;
        }

        self.freeBuffers();

        self.from_buffer = try CellBuffer.init(self.allocator, width, height);
        self.to_buffer = try CellBuffer.init(self.allocator, width, height);
        self.render_buffer = try CellBuffer.init(self.allocator, width, height);

        self.buffer_width = width;
        self.buffer_height = height;
    }

    /// Set configuration
    pub fn setConfig(self: *Self, config: TransitionConfig) void {
        self.config = config;
    }

    /// Check if currently in a transition
    pub fn isTransitioning(self: Self) bool {
        return self.current_transition != null and !self.current_transition.?.isComplete();
    }

    /// Start a transition between slides
    /// Call this BEFORE changing the current slide
    pub fn startTransition(
        self: *Self,
        from_slide: usize,
        to_slide: usize,
        capture_window: tui.Window,
    ) !void {
        // Don't transition if disabled
        if (!self.config.enabled) {
            self.current_transition = null;
            return;
        }

        // Don't transition for "none" type
        if (self.config.default_type == .none) {
            self.current_transition = null;
            return;
        }

        // Resize buffers if needed
        try self.resizeBuffers(capture_window.width, capture_window.height);

        // Capture current slide (from)
        if (self.from_buffer) |*buf| {
            buf.clear();
            buf.captureFromWindow(capture_window);
        }

        // Clear to buffer - it will be filled after the slide changes
        if (self.to_buffer) |*buf| {
            buf.clear();
        }

        // Create transition state
        const now = std.time.milliTimestamp();
        self.current_transition = TransitionState.init(
            from_slide,
            to_slide,
            self.config.default_type,
            self.config.default_duration_ms,
            now,
        );
    }

    /// Complete the transition by capturing the destination slide
    /// Call this AFTER the slide has changed
    pub fn completeTransition(self: *Self, capture_window: tui.Window) void {
        // Capture new slide (to)
        if (self.to_buffer) |*buf| {
            buf.clear();
            buf.captureFromWindow(capture_window);
        }
    }

    /// Update transition progress
    /// Returns true if transition just completed
    pub fn update(self: *Self) bool {
        if (self.current_transition) |*state| {
            const now = std.time.milliTimestamp();
            const was_complete = state.isComplete();
            const now_complete = state.update(now);

            if (!was_complete and now_complete) {
                return true; // Transition just finished
            }
        }
        return false;
    }

    /// Render the current transition state to a window
    pub fn render(self: *Self, target_win: tui.Window) void {
        const state = self.current_transition orelse return;

        const from_buf = self.from_buffer orelse return;
        const to_buf = self.to_buffer orelse return;
        const render_buf = &(self.render_buffer orelse return);

        // Apply transition effect
        Transition.apply(
            state.transition_type,
            from_buf,
            to_buf,
            render_buf,
            state.getEasedProgress(),
            state.direction,
        );

        // Copy render buffer to target window
        const w = @min(render_buf.width, target_win.width);
        const h = @min(render_buf.height, target_win.height);

        for (0..h) |y| {
            for (0..w) |x| {
                if (render_buf.getCell(x, y)) |cell| {
                    _ = target_win.writeCell(@intCast(x), @intCast(y), cell);
                }
            }
        }
    }

    /// Get current transition progress (0.0 to 1.0)
    pub fn getProgress(self: Self) f32 {
        if (self.current_transition) |state| {
            return state.progress;
        }
        return 1.0;
    }

    /// Skip current transition
    pub fn skipTransition(self: *Self) void {
        if (self.current_transition) |*state| {
            state.progress = 1.0;
        }
    }

    /// Set transition type
    pub fn setTransitionType(self: *Self, transition_type: TransitionType) void {
        self.config.default_type = transition_type;
    }

    /// Set transition duration
    pub fn setTransitionDuration(self: *Self, duration_ms: u32) void {
        self.config.default_duration_ms = duration_ms;
    }

    /// Toggle transitions on/off
    pub fn toggleEnabled(self: *Self) void {
        self.config.enabled = !self.config.enabled;
    }
};

// Tests
test "TransitionManager init/deinit" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var manager = TransitionManager.init(allocator);
    defer manager.deinit();

    try testing.expect(!manager.isTransitioning());
    try testing.expect(!manager.config.enabled); // disabled by default
}

test "TransitionManager buffer resize" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var manager = TransitionManager.init(allocator);
    defer manager.deinit();

    try manager.resizeBuffers(80, 24);

    try testing.expectEqual(@as(usize, 80), manager.buffer_width);
    try testing.expectEqual(@as(usize, 24), manager.buffer_height);
    try testing.expect(manager.from_buffer != null);
    try testing.expect(manager.to_buffer != null);
    try testing.expect(manager.render_buffer != null);
}

test "TransitionManager config" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var manager = TransitionManager.init(allocator);
    defer manager.deinit();

    manager.setTransitionType(.slide_left);
    try testing.expectEqual(TransitionType.slide_left, manager.config.default_type);

    manager.setTransitionDuration(500);
    try testing.expectEqual(@as(u32, 500), manager.config.default_duration_ms);

    manager.toggleEnabled();
    try testing.expect(manager.config.enabled); // toggled from false to true
}
