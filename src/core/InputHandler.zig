//! Input handler for processing keyboard events
const std = @import("std");
const tui = @import("../tui/root.zig");
const Navigation = @import("Navigation.zig").Navigation;
const KeyBindings = @import("KeyBindings.zig").KeyBindings;
const Action = @import("KeyBindings.zig").Action;

/// InputHandler processes keyboard events and updates navigation state
pub const InputHandler = struct {
    bindings: KeyBindings,
    jump_buffer: std.ArrayList(u8),
    allocator: std.mem.Allocator,
    in_jump_mode: bool = false,

    const Self = @This();

    /// Initialize input handler
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .bindings = KeyBindings.init(allocator),
            .jump_buffer = .empty,
            .allocator = allocator,
            .in_jump_mode = false,
        };
    }

    /// Clean up
    pub fn deinit(self: *Self) void {
        self.bindings.deinit();
        self.jump_buffer.deinit(self.allocator);
    }

    /// Process a key event and return true if the app should quit
    pub fn handleKey(self: *Self, key: tui.Key, nav: *Navigation, allocator: std.mem.Allocator) !bool {
        // Handle jump mode (entering slide number)
        if (self.in_jump_mode) {
            return try self.handleJumpMode(key, nav);
        }

        // Look up the action for this key
        const action = self.bindings.lookup(key);

        switch (action) {
            .next_slide => {
                nav.nextSlide();
            },
            .prev_slide => {
                nav.prevSlide();
            },
            .first_slide => {
                nav.firstSlide();
            },
            .last_slide => {
                nav.lastSlide();
            },
            .goto_slide => {
                // Start jump mode with the digit pressed
                if (key.codepoint >= '0' and key.codepoint <= '9') {
                    self.in_jump_mode = true;
                    self.jump_buffer.clearRetainingCapacity();
                    try self.jump_buffer.append(allocator, @intCast(key.codepoint));
                    try nav.setMessage(allocator, self.jump_buffer.items, 0); // No timeout
                }
            },
            .toggle_help => {
                nav.toggleHelp();
            },
            .toggle_overview => {
                nav.toggleOverview();
            },
            .toggle_execution => {
                nav.toggleExecution();
            },
            .execute_code => {
                // Signal code execution request - the main loop will handle this
                return false;
            },
            .quit => {
                return true; // Signal to quit
            },
            .none => {
                // Unknown key - ignore
            },
        }

        return false; // Continue running
    }

    /// Handle keys while in jump mode
    fn handleJumpMode(self: *Self, key: tui.Key, nav: *Navigation) (std.mem.Allocator.Error || error{OutOfMemory})!bool {
        // Exit jump mode on escape or 'q'
        if (key.codepoint == tui.Key.escape or key.codepoint == 'q') {
            self.in_jump_mode = false;
            self.jump_buffer.clearRetainingCapacity();
            nav.clearMessage(self.allocator);
            return false;
        }

        // Enter key completes the jump
        if (key.codepoint == tui.Key.enter or key.codepoint == '\r') {
            self.in_jump_mode = false;
            const slide_num = std.fmt.parseInt(usize, self.jump_buffer.items, 10) catch 1;
            nav.gotoSlide(slide_num);
            self.jump_buffer.clearRetainingCapacity();
            nav.clearMessage(self.allocator);
            return false;
        }

        // Backspace removes last digit
        if (key.codepoint == tui.Key.backspace) {
            if (self.jump_buffer.items.len > 0) {
                _ = self.jump_buffer.pop();
                if (self.jump_buffer.items.len == 0) {
                    self.in_jump_mode = false;
                    nav.clearMessage(self.allocator);
                } else {
                    try nav.setMessage(self.allocator, self.jump_buffer.items, 0);
                }
            }
            return false;
        }

        // Digits add to buffer
        if (key.codepoint >= '0' and key.codepoint <= '9') {
            if (self.jump_buffer.items.len < 5) { // Reasonable limit
                try self.jump_buffer.append(self.allocator, @intCast(key.codepoint));
                try nav.setMessage(self.allocator, self.jump_buffer.items, 0);
            }
            return false;
        }

        // Any other key exits jump mode and processes normally
        self.in_jump_mode = false;
        self.jump_buffer.clearRetainingCapacity();
        nav.clearMessage(self.allocator);

        // Re-process the key normally (recursively, but we cleared jump mode)
        return try self.handleKey(key, nav, self.allocator);
    }

    /// Show current slide status
    fn showSlideStatus(self: *Self, nav: *Navigation, allocator: std.mem.Allocator) !void {
        _ = self;
        const msg = try std.fmt.allocPrint(allocator, "Slide {d}/{d}", .{
            nav.currentSlideNumber(),
            nav.total_slides,
        });
        defer allocator.free(msg);
        try nav.setMessage(allocator, msg, 60); // 60 ticks (~2 seconds)
    }

    /// Check if currently in jump mode
    pub fn isInJumpMode(self: Self) bool {
        return self.in_jump_mode;
    }

    /// Get current jump buffer content
    pub fn getJumpBuffer(self: Self) []const u8 {
        return self.jump_buffer.items;
    }
};

test "InputHandler navigation" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Create a mock presentation
    var slides: std.ArrayList(@import("Slide.zig").Slide) = .empty;
    defer slides.deinit(allocator);

    // Add 5 slides
    for (0..5) |_| {
        try slides.append(allocator, @import("Slide.zig").Slide{
            .elements = &.{},
            .speaker_notes = null,
        });
    }

    var presentation = @import("Presentation.zig").Presentation{
        .allocator = allocator,
        .metadata = .{ .title = null, .author = null, .date = null, .theme = null },
        .slides = try slides.toOwnedSlice(allocator),
    };
    defer {
        for (presentation.slides) |slide| {
            slide.deinit(allocator);
        }
        allocator.free(presentation.slides);
    }

    var nav = Navigation.init(&presentation);
    defer nav.deinit(allocator);

    var handler = InputHandler.init(allocator);
    defer handler.deinit();

    // Test next slide
    var should_quit = try handler.handleKey(.{ .codepoint = 'j', .mods = .{} }, &nav, allocator);
    try testing.expect(!should_quit);
    try testing.expectEqual(@as(usize, 1), nav.current_slide);

    // Test prev slide
    should_quit = try handler.handleKey(.{ .codepoint = 'k', .mods = .{} }, &nav, allocator);
    try testing.expect(!should_quit);
    try testing.expectEqual(@as(usize, 0), nav.current_slide);

    // Test quit
    should_quit = try handler.handleKey(.{ .codepoint = 'q', .mods = .{} }, &nav, allocator);
    try testing.expect(should_quit);
}
