//! Inline text widget for rendering styled text (bold, italic, code, links)
const std = @import("std");
const tui = @import("../tui/root.zig");
const Widget = @import("Widget.zig").Widget;
const DrawContext = @import("Widget.zig").DrawContext;
const Constraints = @import("Widget.zig").Constraints;
const Size = @import("Widget.zig").Size;
const DrawUtils = @import("Widget.zig").DrawUtils;
const toStyle = @import("Widget.zig").toStyle;
const Inline = @import("../core/Element.zig").Inline;
const ElementStyle = @import("../render/Theme.zig").ElementStyle;
const Theme = @import("../render/Theme.zig").Theme;

/// Segment represents a styled piece of text
const Segment = struct {
    text: []const u8,
    style: SegmentStyle,
    is_link: bool = false,
    link_url: ?[]const u8 = null,
};

/// Segment style for inline formatting
const SegmentStyle = struct {
    bold: bool = false,
    italic: bool = false,
    code: bool = false,
    strikethrough: bool = false,
};

/// InlineTextWidget renders styled inline content
pub const InlineTextWidget = struct {
    allocator: std.mem.Allocator,
    segments: []Segment,
    base_style: ElementStyle,
    left_border: ?[]const u8 = null,
    left_border_width: usize = 0,

    const Self = @This();

    /// Initialize from inline content
    pub fn init(allocator: std.mem.Allocator, inlines: []const Inline, base_style: ElementStyle, link_refs: ?*const std.StringHashMap([]const u8)) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        // Convert inline content to segments
        var segments: std.ArrayList(Segment) = .empty;
        errdefer {
            for (segments.items) |seg| {
                if (seg.link_url) |url| allocator.free(url);
                allocator.free(seg.text);
            }
            segments.deinit(allocator);
        }

        try Self.collectSegments(allocator, inlines, &segments, .{}, link_refs);

        self.* = .{
            .allocator = allocator,
            .segments = try segments.toOwnedSlice(allocator),
            .base_style = base_style,
        };
        return self;
    }

    /// Recursively collect segments from inline content
    fn collectSegments(
        allocator: std.mem.Allocator,
        inlines: []const Inline,
        segments: *std.ArrayList(Segment),
        base_seg_style: SegmentStyle,
        link_refs: ?*const std.StringHashMap([]const u8),
    ) !void {
        for (inlines) |inline_elem| {
            switch (inline_elem) {
                .text => |text| {
                    try segments.append(allocator, .{
                        .text = try allocator.dupe(u8, text),
                        .style = base_seg_style,
                    });
                },
                .code => |code| {
                    try segments.append(allocator, .{
                        .text = try allocator.dupe(u8, code),
                        .style = .{ .code = true },
                    });
                },
                .italic => |emph| {
                    var new_style = base_seg_style;
                    new_style.italic = true;
                    try collectSegments(allocator, emph, segments, new_style, link_refs);
                },
                .bold => |strong| {
                    var new_style = base_seg_style;
                    new_style.bold = true;
                    try collectSegments(allocator, strong, segments, new_style, link_refs);
                },
                .strikethrough => |st| {
                    var new_style = base_seg_style;
                    new_style.strikethrough = true;
                    try collectSegments(allocator, st, segments, new_style, link_refs);
                },
                .link => |link| {
                    // For now, just show the link text (URL can be shown on hover later)
                    const link_text = try inlineToPlainText(allocator, link.content);
                    errdefer allocator.free(link_text);

                    try segments.append(allocator, .{
                        .text = link_text,
                        .style = .{ .italic = true }, // Links shown as italic for now
                        .is_link = true,
                        .link_url = try allocator.dupe(u8, link.url),
                    });
                },
                .image => |img| {
                    // Images displayed as their alt text in brackets
                    const img_text = try std.fmt.allocPrint(allocator, "[{s}]", .{img.alt});
                    try segments.append(allocator, .{
                        .text = img_text,
                        .style = .{ .italic = true },
                    });
                },
            }
        }
    }

    /// Convert inline content to plain text
    fn inlineToPlainText(allocator: std.mem.Allocator, inlines: []const Inline) ![]const u8 {
        var result: std.ArrayList(u8) = .empty;
        errdefer result.deinit(allocator);

        for (inlines) |inline_elem| {
            switch (inline_elem) {
                .text => |t| try result.appendSlice(allocator, t),
                .code => |c| try result.appendSlice(allocator, c),
                .italic => |e| {
                    const text = try inlineToPlainText(allocator, e);
                    defer allocator.free(text);
                    try result.appendSlice(allocator, text);
                },
                .bold => |s| {
                    const text = try inlineToPlainText(allocator, s);
                    defer allocator.free(text);
                    try result.appendSlice(allocator, text);
                },
                .strikethrough => |st| {
                    const text = try inlineToPlainText(allocator, st);
                    defer allocator.free(text);
                    try result.appendSlice(allocator, text);
                },
                .link => |l| {
                    const text = try inlineToPlainText(allocator, l.content);
                    defer allocator.free(text);
                    try result.appendSlice(allocator, text);
                },
                .image => |img| try result.appendSlice(allocator, img.alt),
            }
        }

        return try result.toOwnedSlice(allocator);
    }

    /// Clean up resources
    pub fn deinit(self: *Self) void {
        for (self.segments) |seg| {
            if (seg.link_url) |url| self.allocator.free(url);
            self.allocator.free(seg.text);
        }
        self.allocator.free(self.segments);
        self.allocator.destroy(self);
    }

    /// Draw the left border at a given row
    fn drawLeftBorder(self: *Self, ctx: DrawContext, x: usize, row: usize) void {
        if (self.left_border) |border| {
            const border_style = toStyle(self.base_style);
            var bi: usize = 0;
            var bcol: usize = 0;
            while (bi < border.len) {
                const bx = x + bcol;
                if (bx >= ctx.win.width) break;
                const seq_len = std.unicode.utf8ByteSequenceLength(border[bi]) catch 1;
                const bend = @min(bi + seq_len, border.len);
                ctx.win.writeCell(@intCast(bx), @intCast(row), .{
                    .char = .{ .grapheme = border[bi..bend] },
                    .style = border_style,
                });
                bcol += 1;
                bi = bend;
            }
        }
    }

    /// Draw the inline text widget
    pub fn draw(self: *Self, ctx: DrawContext, x: usize, y: usize) void {
        const content_x = x + self.left_border_width;
        var current_x = content_x;
        var current_y = y;

        // Draw initial left border
        if (self.left_border != null) {
            self.drawLeftBorder(ctx, x, current_y);
        }

        for (self.segments) |segment| {
            const seg_style = self.computeSegmentStyle(segment.style, ctx.theme);
            const vaxis_style = toStyle(seg_style);

            // Handle newlines
            if (std.mem.eql(u8, segment.text, "\n")) {
                current_y += 1;
                current_x = content_x;
                if (self.left_border != null) {
                    self.drawLeftBorder(ctx, x, current_y);
                }
                continue;
            }

            // Draw the segment text
            const max_width = if (ctx.win.width > current_x) ctx.win.width - current_x else 0;
            const lines_drawn = DrawUtils.drawTextWrapped(ctx.win, current_x, current_y, segment.text, vaxis_style, max_width);

            // Draw left border on wrapped lines
            if (self.left_border != null and lines_drawn > 1) {
                for (1..lines_drawn) |line_offset| {
                    self.drawLeftBorder(ctx, x, current_y + line_offset);
                }
            }

            // Update position
            if (lines_drawn > 1) {
                current_y += lines_drawn - 1;
            }
            current_x += segment.text.len;
            if (current_x >= ctx.win.width) {
                current_y += 1;
                current_x = content_x;
                if (self.left_border != null) {
                    self.drawLeftBorder(ctx, x, current_y);
                }
            }
        }
    }

    /// Compute the final style for a segment
    fn computeSegmentStyle(self: Self, seg_style: SegmentStyle, theme: Theme) ElementStyle {
        var result = self.base_style;

        if (seg_style.bold) {
            result.bold = true;
        }
        if (seg_style.italic) {
            result.italic = true;
        }
        if (seg_style.strikethrough) {
            result.strikethrough = true;
        }
        if (seg_style.code) {
            // Use code style from theme
            result = theme.code_block;
            result.bold = true;
        }

        return result;
    }

    /// Get the size of the widget
    pub fn getSize(self: *Self, constraints: Constraints) Size {
        const available_width = @min(constraints.max_width, 80);
        const content_width = if (available_width > self.left_border_width)
            available_width - self.left_border_width
        else
            1;

        // Concatenate all segment text to measure
        var total_text: std.ArrayList(u8) = .empty;
        defer total_text.deinit(self.allocator);

        for (self.segments) |seg| {
            total_text.appendSlice(self.allocator, seg.text) catch {};
        }

        const lines = DrawUtils.measureWrappedLines(total_text.items, content_width);
        return .{
            .width = @min(total_text.items.len + self.left_border_width, available_width),
            .height = lines,
        };
    }
};

// Tests
test "InlineTextWidget basic text" {
    const testing = std.testing;
    const allocator = testing.allocator;
    const ThemeMod = @import("../render/Theme.zig");

    const inlines = &[_]Inline{
        .{ .text = try allocator.dupe(u8, "Hello ") },
        .{ .text = try allocator.dupe(u8, "World") },
    };
    defer {
        for (inlines) |*inl| {
            inl.deinit(allocator);
        }
    }

    var widget = try InlineTextWidget.init(allocator, inlines, ThemeMod.darkTheme().paragraph, null);
    defer widget.deinit();

    try testing.expectEqual(@as(usize, 2), widget.segments.len);
}

test "InlineTextWidget with bold" {
    const testing = std.testing;
    const allocator = testing.allocator;
    const ThemeMod = @import("../render/Theme.zig");

    const bold_content = try allocator.alloc(Inline, 1);
    bold_content[0] = .{ .text = try allocator.dupe(u8, "bold text") };

    const inlines = &[_]Inline{
        .{ .text = try allocator.dupe(u8, "Hello ") },
        .{ .bold = bold_content },
    };
    defer {
        allocator.free(inlines[0].text);
        for (bold_content) |*inl| {
            inl.deinit(allocator);
        }
        allocator.free(inlines[1].bold);
    }

    var widget = try InlineTextWidget.init(allocator, inlines, ThemeMod.darkTheme().paragraph, null);
    defer widget.deinit();

    // Should have merged segments or at least the bold segment should be marked
    try testing.expect(widget.segments.len >= 1);
}
