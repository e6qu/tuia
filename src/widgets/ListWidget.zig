//! List widget for rendering bullet and numbered lists
const std = @import("std");
const vaxis = @import("vaxis");
const DrawContext = @import("Widget.zig").DrawContext;
const Constraints = @import("Widget.zig").Constraints;
const Size = @import("Widget.zig").Size;
const DrawUtils = @import("Widget.zig").DrawUtils;
const toVaxisStyle = @import("Widget.zig").toVaxisStyle;
const List = @import("../core/Element.zig").List;
const ListItem = @import("../core/Element.zig").ListItem;
const Inline = @import("../core/Element.zig").Inline;
const inlineToPlainText = @import("../core/Element.zig").inlineToPlainText;

/// ListWidget renders bullet and numbered lists
pub const ListWidget = struct {
    allocator: std.mem.Allocator,
    items: []Item,
    ordered: bool,

    /// Internal item representation
    const Item = struct {
        text: []const u8,

        pub fn deinit(self: Item, allocator: std.mem.Allocator) void {
            allocator.free(self.text);
        }
    };

    const Self = @This();

    /// Initialize list widget from List element
    pub fn initFromElement(allocator: std.mem.Allocator, list: List) !*Self {
        const items = try allocator.alloc(Item, list.items.len);
        errdefer allocator.free(items);

        for (list.items, 0..) |list_item, i| {
            const text = try inlineToPlainText(allocator, list_item.content);
            errdefer allocator.free(text);
            items[i] = .{
                .text = text,
            };
        }

        const self = try allocator.create(Self);
        self.* = .{
            .allocator = allocator,
            .items = items,
            .ordered = list.ordered,
        };
        return self;
    }

    /// Initialize list widget directly
    pub fn init(allocator: std.mem.Allocator, list: List) !*Self {
        return initFromElement(allocator, list);
    }

    /// Clean up resources
    pub fn deinit(self: *Self) void {
        for (self.items) |item| {
            item.deinit(self.allocator);
        }
        self.allocator.free(self.items);
        self.allocator.destroy(self);
    }

    /// Draw the list widget
    pub fn draw(self: *Self, ctx: DrawContext, x: usize, y: usize) void {
        const bullet_style = toVaxisStyle(if (self.ordered)
            ctx.theme.list_number
        else
            ctx.theme.list_bullet);

        const text_style = toVaxisStyle(ctx.theme.paragraph);

        var row = y;
        const indent_size = self.getIndentSize();

        for (self.items, 0..) |item, i| {
            if (row >= ctx.win.height) break;

            // Draw bullet/number
            const marker = self.getMarker(i);
            if (x < ctx.win.width) {
                _ = ctx.win.writeCell(@intCast(x), @intCast(row), .{
                    .char = .{ .grapheme = marker },
                    .style = bullet_style,
                });
            }

            // Draw item text with wrapping
            const content_x = x + indent_size;
            const max_width = if (ctx.win.width > content_x) ctx.win.width - content_x else 0;

            if (max_width > 0 and content_x < ctx.win.width) {
                const lines_used = DrawUtils.drawTextWrapped(ctx.win, content_x, row, item.text, text_style, max_width);
                row += lines_used;
            } else {
                row += 1;
            }

            // Add spacing between items
            if (i < self.items.len - 1) {
                row += 1;
            }
        }
    }

    /// Get the size of the widget
    pub fn getSize(self: *Self, constraints: Constraints) Size {
        const indent_size = self.getIndentSize();
        const content_width = if (constraints.max_width > indent_size)
            constraints.max_width - indent_size
        else
            1;

        var total_height: usize = 0;
        var max_content_width: usize = 0;

        for (self.items, 0..) |item, i| {
            // Calculate marker width
            const marker = self.getMarker(i);
            max_content_width = @max(max_content_width, item.text.len + marker.len);

            // Calculate wrapped lines for this item
            const lines = DrawUtils.measureWrappedLines(item.text, content_width);
            total_height += @max(1, lines);

            // Add spacing between items
            if (i < self.items.len - 1) {
                total_height += 1;
            }
        }

        return .{
            .width = @min(max_content_width + indent_size, constraints.max_width),
            .height = total_height,
        };
    }

    /// Get the marker string for an item index
    fn getMarker(self: Self, index: usize) []const u8 {
        if (self.ordered) {
            // Format: "1. ", "2. ", etc.
            return switch (index) {
                0 => "1. ",
                1 => "2. ",
                2 => "3. ",
                3 => "4. ",
                4 => "5. ",
                5 => "6. ",
                6 => "7. ",
                7 => "8. ",
                8 => "9. ",
                9 => "10.",
                10 => "11.",
                11 => "12.",
                else => "• ",
            };
        } else {
            return "• ";
        }
    }

    /// Get the indentation size for content
    fn getIndentSize(self: Self) usize {
        if (self.ordered) {
            // Find max marker width
            var max_marker_width: usize = 3; // "1. "
            if (self.items.len > 9) max_marker_width = 4; // "10."
            if (self.items.len > 99) max_marker_width = 5; // "100."
            return max_marker_width + 1;
        } else {
            return 3; // "• " + 1 space
        }
    }
};

test "ListWidget unordered" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var items: std.ArrayList(ListItem) = .empty;
    defer items.deinit(allocator);

    const content1 = try allocator.alloc(Inline, 1);
    content1[0] = .{ .text = try allocator.dupe(u8, "First item") };
    try items.append(allocator, .{ .content = content1, .children = null });

    const content2 = try allocator.alloc(Inline, 1);
    content2[0] = .{ .text = try allocator.dupe(u8, "Second item") };
    try items.append(allocator, .{ .content = content2, .children = null });

    const content3 = try allocator.alloc(Inline, 1);
    content3[0] = .{ .text = try allocator.dupe(u8, "Third item") };
    try items.append(allocator, .{ .content = content3, .children = null });

    const list = List{
        .ordered = false,
        .items = try items.toOwnedSlice(allocator),
    };
    defer {
        for (list.items) |item| item.deinit(allocator);
        allocator.free(list.items);
    }

    var widget = try ListWidget.init(allocator, list);
    defer widget.deinit();

    try testing.expect(!widget.ordered);
    try testing.expectEqual(@as(usize, 3), widget.items.len);
}

test "ListWidget ordered" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var items: std.ArrayList(ListItem) = .empty;
    defer items.deinit(allocator);

    const content1 = try allocator.alloc(Inline, 1);
    content1[0] = .{ .text = try allocator.dupe(u8, "Step one") };
    try items.append(allocator, .{ .content = content1, .children = null });

    const content2 = try allocator.alloc(Inline, 1);
    content2[0] = .{ .text = try allocator.dupe(u8, "Step two") };
    try items.append(allocator, .{ .content = content2, .children = null });

    const list = List{
        .ordered = true,
        .items = try items.toOwnedSlice(allocator),
    };
    defer {
        for (list.items) |item| item.deinit(allocator);
        allocator.free(list.items);
    }

    var widget = try ListWidget.init(allocator, list);
    defer widget.deinit();

    try testing.expect(widget.ordered);
}

test "ListWidget size calculation" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var items: std.ArrayList(ListItem) = .empty;
    defer items.deinit(allocator);

    const content1 = try allocator.alloc(Inline, 1);
    content1[0] = .{ .text = try allocator.dupe(u8, "Item 1") };
    try items.append(allocator, .{ .content = content1, .children = null });

    const content2 = try allocator.alloc(Inline, 1);
    content2[0] = .{ .text = try allocator.dupe(u8, "Item 2") };
    try items.append(allocator, .{ .content = content2, .children = null });

    const list = List{
        .ordered = false,
        .items = try items.toOwnedSlice(allocator),
    };
    defer {
        for (list.items) |item| item.deinit(allocator);
        allocator.free(list.items);
    }

    var widget = try ListWidget.init(allocator, list);
    defer widget.deinit();

    const size = widget.getSize(.{ .max_width = 80 });
    try testing.expect(size.width > 0);
    try testing.expect(size.height > 0);
}

test "ListWidget markers" {
    const testing = std.testing;

    // Test unordered marker
    const unordered_widget = ListWidget{
        .allocator = undefined,
        .items = &.{},
        .ordered = false,
    };
    try testing.expectEqualStrings("• ", unordered_widget.getMarker(0));
    try testing.expectEqualStrings("• ", unordered_widget.getMarker(99));

    // Test ordered markers
    const ordered_widget = ListWidget{
        .allocator = undefined,
        .items = &.{},
        .ordered = true,
    };
    try testing.expectEqualStrings("1. ", ordered_widget.getMarker(0));
    try testing.expectEqualStrings("2. ", ordered_widget.getMarker(1));
    try testing.expectEqualStrings("10.", ordered_widget.getMarker(9));
}
