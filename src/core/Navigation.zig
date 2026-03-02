//! Navigation state for presentation control
const std = @import("std");
const Presentation = @import("Presentation.zig").Presentation;

/// Navigation state manages the current position in a presentation
pub const Navigation = struct {
    /// Current slide index (0-based)
    current_slide: usize = 0,
    /// Total number of slides
    total_slides: usize = 0,
    /// Whether help overlay is visible
    show_help: bool = false,
    /// Whether we're in slide overview mode
    show_overview: bool = false,
    /// Jump input buffer (for "go to slide N")
    jump_buffer: ?[]const u8 = null,
    /// Message to display (temporary status)
    message: ?[]const u8 = null,
    /// Message timeout (in event loop ticks)
    message_timeout: u32 = 0,

    const Self = @This();

    /// Initialize navigation with a presentation
    pub fn init(presentation: *const Presentation) Self {
        return .{
            .current_slide = 0,
            .total_slides = presentation.slides.len,
            .show_help = false,
            .show_overview = false,
            .jump_buffer = null,
            .message = null,
            .message_timeout = 0,
        };
    }

    /// Clean up allocated memory
    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        if (self.jump_buffer) |buf| {
            allocator.free(buf);
        }
        if (self.message) |msg| {
            allocator.free(msg);
        }
    }

    /// Go to the next slide
    pub fn nextSlide(self: *Self) void {
        if (self.current_slide < self.total_slides - 1) {
            self.current_slide += 1;
        }
    }

    /// Go to the previous slide
    pub fn prevSlide(self: *Self) void {
        if (self.current_slide > 0) {
            self.current_slide -= 1;
        }
    }

    /// Go to the first slide
    pub fn firstSlide(self: *Self) void {
        self.current_slide = 0;
    }

    /// Go to the last slide
    pub fn lastSlide(self: *Self) void {
        if (self.total_slides > 0) {
            self.current_slide = self.total_slides - 1;
        }
    }

    /// Jump to a specific slide (1-based index from user input)
    pub fn gotoSlide(self: *Self, slide_number: usize) void {
        if (slide_number == 0 or self.total_slides == 0) return;
        const zero_based = slide_number - 1;
        if (zero_based < self.total_slides) {
            self.current_slide = zero_based;
        } else {
            self.current_slide = self.total_slides - 1;
        }
    }

    /// Toggle help overlay
    pub fn toggleHelp(self: *Self) void {
        self.show_help = !self.show_help;
    }

    /// Toggle overview mode
    pub fn toggleOverview(self: *Self) void {
        self.show_overview = !self.show_overview;
    }

    /// Set a temporary message
    pub fn setMessage(self: *Self, allocator: std.mem.Allocator, msg: []const u8, timeout: u32) !void {
        if (self.message) |old| {
            allocator.free(old);
        }
        self.message = try allocator.dupe(u8, msg);
        self.message_timeout = timeout;
    }

    /// Clear the message
    pub fn clearMessage(self: *Self, allocator: std.mem.Allocator) void {
        if (self.message) |msg| {
            allocator.free(msg);
            self.message = null;
            self.message_timeout = 0;
        }
    }

    /// Get current slide number (1-based for display)
    pub fn currentSlideNumber(self: Self) usize {
        return self.current_slide + 1;
    }

    /// Check if we're on the first slide
    pub fn isFirstSlide(self: Self) bool {
        return self.current_slide == 0;
    }

    /// Check if we're on the last slide
    pub fn isLastSlide(self: Self) bool {
        return self.current_slide >= self.total_slides - 1;
    }

    /// Update message timeout (call each tick)
    pub fn tick(self: *Self, allocator: std.mem.Allocator) void {
        if (self.message_timeout > 0) {
            self.message_timeout -= 1;
            if (self.message_timeout == 0) {
                self.clearMessage(allocator);
            }
        }
    }
};

test "Navigation basic operations" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Create a mock presentation with 5 slides
    var slides: std.ArrayList(@import("Slide.zig").Slide) = .empty;
    defer slides.deinit(allocator);

    // Add 5 slides
    for (0..5) |_| {
        try slides.append(allocator, @import("Slide.zig").Slide{
            .elements = &.{},
        });
    }

    var presentation = Presentation{
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

    // Test initial state
    try testing.expectEqual(@as(usize, 0), nav.current_slide);
    try testing.expectEqual(@as(usize, 5), nav.total_slides);
    try testing.expect(nav.isFirstSlide());
    try testing.expect(!nav.isLastSlide());

    // Test next slide
    nav.nextSlide();
    try testing.expectEqual(@as(usize, 1), nav.current_slide);

    // Test previous slide
    nav.prevSlide();
    try testing.expectEqual(@as(usize, 0), nav.current_slide);

    // Test bounds (can't go before first)
    nav.prevSlide();
    try testing.expectEqual(@as(usize, 0), nav.current_slide);

    // Test goto
    nav.gotoSlide(3);
    try testing.expectEqual(@as(usize, 2), nav.current_slide);

    // Test last slide
    nav.lastSlide();
    try testing.expect(nav.isLastSlide());
    try testing.expectEqual(@as(usize, 4), nav.current_slide);

    // Test first slide
    nav.firstSlide();
    try testing.expect(nav.isFirstSlide());

    // Test out of bounds goto
    nav.gotoSlide(100);
    try testing.expectEqual(@as(usize, 4), nav.current_slide);

    // Test slide number display
    nav.gotoSlide(3);
    try testing.expectEqual(@as(usize, 3), nav.currentSlideNumber());
}

test "Navigation message handling" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var presentation = Presentation{
        .allocator = allocator,
        .metadata = .{ .title = null, .author = null, .date = null, .theme = null },
        .slides = &.{},
    };

    var nav = Navigation.init(&presentation);
    defer nav.deinit(allocator);

    // Test message
    try nav.setMessage(allocator, "Test message", 3);
    try testing.expect(nav.message != null);
    try testing.expectEqualStrings("Test message", nav.message.?);

    // Test tick clears message
    nav.tick(allocator);
    nav.tick(allocator);
    try testing.expect(nav.message != null);
    nav.tick(allocator);
    try testing.expect(nav.message == null);
}
