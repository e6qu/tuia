//! Slide widget - container for slide elements
const std = @import("std");
const vaxis = @import("vaxis");
const DrawContext = @import("Widget.zig").DrawContext;
const Constraints = @import("Widget.zig").Constraints;
const Size = @import("Widget.zig").Size;
const Widget = @import("Widget.zig").Widget;
const WidgetFactory = @import("Widget.zig").WidgetFactory;
const Slide = @import("../core/Slide.zig").Slide;

/// SlideWidget renders a complete slide with all its elements
pub const SlideWidget = struct {
    allocator: std.mem.Allocator,
    slide: Slide,
    widgets: std.ArrayList(Widget),
    padding: Padding,

    /// Padding configuration
    pub const Padding = struct {
        top: usize = 2,
        bottom: usize = 2,
        left: usize = 4,
        right: usize = 4,

        pub fn totalWidth(self: Padding) usize {
            return self.left + self.right;
        }

        pub fn totalHeight(self: Padding) usize {
            return self.top + self.bottom;
        }
    };

    const Self = @This();

    /// Initialize slide widget
    pub fn init(allocator: std.mem.Allocator, slide: Slide) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        const widgets: std.ArrayList(Widget) = .empty;

        self.* = .{
            .allocator = allocator,
            .slide = slide,
            .widgets = widgets,
            .padding = .{},
        };

        // Build child widgets
        try self.buildWidgets();

        return self;
    }

    /// Clean up resources
    pub fn deinit(self: *Self) void {
        // Destroy each widget (frees widget copies of element data)
        for (self.widgets.items) |widget| {
            widget.destroy(self.allocator);
        }
        self.widgets.deinit(self.allocator);
        // Deinit slide (frees original element data)
        self.slide.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    /// Build child widgets from slide elements
    fn buildWidgets(self: *Self) !void {
        const factory = WidgetFactory.init(self.allocator);

        for (self.slide.elements) |element| {
            const widget = factory.createWidget(element) catch |err| {
                // Log error but continue with other elements
                std.log.warn("Failed to create widget for element: {s}", .{@errorName(err)});
                continue;
            };
            try self.widgets.append(self.allocator, widget);
        }
    }

    /// Set padding
    pub fn setPadding(self: *Self, padding: Padding) void {
        self.padding = padding;
    }

    /// Draw the slide widget
    pub fn draw(self: *Self, ctx: DrawContext, x: usize, y: usize) void {
        const content_x = x + self.padding.left;
        const content_y = y + self.padding.top;
        const content_width = if (ctx.win.width > self.padding.totalWidth() + x)
            ctx.win.width - self.padding.totalWidth() - x
        else
            0;

        if (content_width == 0) return;

        var current_y = content_y;

        for (self.widgets.items) |widget| {
            // Get widget size with constraints
            const constraints = Constraints{
                .max_width = content_width,
                .max_height = if (ctx.win.height > current_y) ctx.win.height - current_y else 0,
            };
            const size = widget.getSize(constraints);

            // Check if widget fits
            if (current_y + size.height > ctx.win.height - self.padding.bottom) {
                // Skip remaining widgets if they don't fit
                break;
            }

            // Create constrained context for this widget
            const widget_ctx = DrawContext{
                .win = ctx.win,
                .theme = ctx.theme,
            };

            // Draw widget
            widget.draw(widget_ctx, content_x, current_y);

            // Add spacing between elements
            current_y += size.height + 1;
        }
    }

    /// Get the size of the widget
    pub fn getSize(self: *Self, constraints: Constraints) Size {
        const content_width = if (constraints.max_width > self.padding.totalWidth())
            constraints.max_width - self.padding.totalWidth()
        else
            0;

        var total_height: usize = self.padding.totalHeight();
        var max_width: usize = self.padding.totalWidth();

        for (self.widgets.items) |widget| {
            const widget_constraints = Constraints{
                .max_width = content_width,
                .max_height = constraints.max_height - total_height,
            };
            const size = widget.getSize(widget_constraints);

            max_width = @max(max_width, size.width + self.padding.totalWidth());
            total_height += size.height + 1; // +1 for spacing
        }

        // Remove trailing spacing
        if (self.widgets.items.len > 0) {
            total_height -= 1;
        }

        return .{
            .width = @min(max_width, constraints.max_width),
            .height = @min(total_height, constraints.max_height),
        };
    }

    /// Get slide title
    pub fn getTitle(self: Self) ?[]const u8 {
        return self.slide.getTitle();
    }

    /// Check if slide is empty
    pub fn isEmpty(self: Self) bool {
        return self.slide.isEmpty();
    }

    /// Get element count
    pub fn elementCount(self: Self) usize {
        return self.slide.elementCount();
    }

    /// Get the first code block (for execution)
    pub fn getFirstCodeBlock(self: Self) ?@import("../core/Element.zig").CodeBlock {
        return self.slide.getFirstCodeBlock();
    }
};

test "SlideWidget basic" {
    const testing = std.testing;
    const allocator = testing.allocator;
    const Element = @import("../core/Element.zig").Element;

    // Create a slide with one element
    var elements: std.ArrayList(Element) = .empty;
    defer elements.deinit(allocator);

    try elements.append(allocator, .{
        .heading = .{
            .level = 1,
            .text = try allocator.dupe(u8, "Test Slide"),
        },
    });

    const slide = Slide{
        .elements = try elements.toOwnedSlice(allocator),
        .speaker_notes = null,
    };

    var widget = try SlideWidget.init(allocator, slide);
    defer widget.deinit();

    try testing.expect(!widget.isEmpty());
    try testing.expectEqual(@as(usize, 1), widget.elementCount());
}

test "SlideWidget with multiple elements" {
    const testing = std.testing;
    const allocator = testing.allocator;
    const Element = @import("../core/Element.zig").Element;

    var elements: std.ArrayList(Element) = .empty;
    defer elements.deinit(allocator);

    try elements.append(allocator, .{
        .heading = .{
            .level = 1,
            .text = try allocator.dupe(u8, "Title"),
        },
    });
    try elements.append(allocator, .{
        .paragraph = .{
            .text = try allocator.dupe(u8, "Some content"),
        },
    });

    const slide = Slide{
        .elements = try elements.toOwnedSlice(allocator),
        .speaker_notes = null,
    };

    var widget = try SlideWidget.init(allocator, slide);
    defer widget.deinit();

    try testing.expectEqual(@as(usize, 2), widget.elementCount());

    // Test size calculation
    const size = widget.getSize(.{ .max_width = 80, .max_height = 40 });
    try testing.expect(size.width > 0);
    try testing.expect(size.height > 0);
}

test "SlideWidget getTitle" {
    const testing = std.testing;
    const allocator = testing.allocator;
    const Element = @import("../core/Element.zig").Element;

    var elements: std.ArrayList(Element) = .empty;
    defer elements.deinit(allocator);

    try elements.append(allocator, .{
        .heading = .{
            .level = 1,
            .text = try allocator.dupe(u8, "My Slide Title"),
        },
    });

    const slide = Slide{
        .elements = try elements.toOwnedSlice(allocator),
        .speaker_notes = null,
    };

    var widget = try SlideWidget.init(allocator, slide);
    defer widget.deinit();

    const title = widget.getTitle();
    try testing.expect(title != null);
    try testing.expectEqualStrings("My Slide Title", title.?);
}

test "SlideWidget padding" {
    const testing = std.testing;
    const allocator = testing.allocator;
    const Element = @import("../core/Element.zig").Element;

    var elements: std.ArrayList(Element) = .empty;
    defer elements.deinit(allocator);

    try elements.append(allocator, .{
        .heading = .{
            .level = 1,
            .text = try allocator.dupe(u8, "Title"),
        },
    });

    const slide = Slide{
            .speaker_notes = null,
        .elements = try elements.toOwnedSlice(allocator),
    };

    var widget = try SlideWidget.init(allocator, slide);
    defer widget.deinit();

    // Test custom padding
    widget.setPadding(.{ .top = 5, .bottom = 5, .left = 10, .right = 10 });
    try testing.expectEqual(@as(usize, 5), widget.padding.top);
    try testing.expectEqual(@as(usize, 10), widget.padding.left);
}
