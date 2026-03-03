//! Base widget interface and common types
const std = @import("std");
const vaxis = @import("vaxis");
const Theme = @import("../render/Theme.zig").Theme;
const Element = @import("../core/Element.zig").Element;
const Inline = @import("../core/Element.zig").Inline;
const inlineToPlainText = @import("../core/Element.zig").inlineToPlainText;

/// Draw context containing window and theme
pub const DrawContext = struct {
    win: vaxis.Window,
    theme: Theme,

    pub fn init(win: vaxis.Window, theme: Theme) DrawContext {
        return .{ .win = win, .theme = theme };
    }
};

/// Size constraints for widget layout
pub const Constraints = struct {
    min_width: usize = 0,
    max_width: usize = std.math.maxInt(usize),
    min_height: usize = 0,
    max_height: usize = std.math.maxInt(usize),
};

/// Widget size
pub const Size = struct {
    width: usize,
    height: usize,
};

/// Base Widget interface - all widgets implement this
pub const Widget = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    const VTable = struct {
        draw: *const fn (ptr: *anyopaque, ctx: DrawContext, x: usize, y: usize) void,
        getSize: *const fn (ptr: *anyopaque, constraints: Constraints) Size,
        destroy: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator) void,
    };

    pub fn init(ptr: anytype) Widget {
        const Ptr = @TypeOf(ptr);
        const ptr_info = @typeInfo(Ptr);

        std.debug.assert(ptr_info == .pointer);
        std.debug.assert(ptr_info.pointer.size == .one);

        const impl = struct {
            pub fn draw(p: *anyopaque, ctx: DrawContext, x: usize, y: usize) void {
                const self: Ptr = @ptrCast(@alignCast(p));
                return @call(.always_inline, ptr_info.pointer.child.draw, .{ self, ctx, x, y });
            }

            pub fn getSize(p: *anyopaque, constraints: Constraints) Size {
                const self: Ptr = @ptrCast(@alignCast(p));
                return @call(.always_inline, ptr_info.pointer.child.getSize, .{ self, constraints });
            }

            pub fn destroy(p: *anyopaque, _: std.mem.Allocator) void {
                const self: Ptr = @ptrCast(@alignCast(p));
                // Note: deinit is responsible for freeing self, not destroy
                @call(.always_inline, ptr_info.pointer.child.deinit, .{self});
            }
        };

        return .{
            .ptr = ptr,
            .vtable = &.{
                .draw = impl.draw,
                .getSize = impl.getSize,
                .destroy = impl.destroy,
            },
        };
    }

    /// Draw the widget at the specified position
    pub fn draw(self: Widget, ctx: DrawContext, x: usize, y: usize) void {
        return self.vtable.draw(self.ptr, ctx, x, y);
    }

    /// Get the size of the widget given constraints
    pub fn getSize(self: Widget, constraints: Constraints) Size {
        return self.vtable.getSize(self.ptr, constraints);
    }

    /// Destroy the widget and free its memory
    pub fn destroy(self: Widget, allocator: std.mem.Allocator) void {
        return self.vtable.destroy(self.ptr, allocator);
    }
};

/// Widget factory - creates widgets from elements
pub const WidgetFactory = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{ .allocator = allocator };
    }

    /// Create a widget from an element
    pub fn createWidget(self: Self, element: Element) !Widget {
        return switch (element) {
            .heading => |h| self.createHeadingWidget(h),
            .paragraph => |p| self.createParagraphWidget(p),
            .code_block => |cb| self.createCodeWidget(cb),
            .list => |l| self.createListWidget(l),
            .blockquote => |bq| self.createBlockquoteWidget(bq),
            .image => |img| self.createImageWidget(img),
            .table => |t| self.createTableWidget(t),
            .media => |m| self.createMediaWidget(m),
            .thematic_break => self.createThematicBreakWidget(),
        };
    }

    fn createHeadingWidget(self: Self, heading: @import("../core/Element.zig").Heading) !Widget {
        const TextWidget = @import("TextWidget.zig").TextWidget;
        const text = try inlineToPlainText(self.allocator, heading.content);
        defer self.allocator.free(text);
        const widget = try TextWidget.initHeading(self.allocator, text, heading.level);
        return Widget.init(widget);
    }

    fn createParagraphWidget(self: Self, paragraph: @import("../core/Element.zig").Paragraph) !Widget {
        const TextWidget = @import("TextWidget.zig").TextWidget;
        const text = try inlineToPlainText(self.allocator, paragraph.content);
        defer self.allocator.free(text);
        const widget = try TextWidget.initParagraph(self.allocator, text);
        return Widget.init(widget);
    }

    fn createCodeWidget(self: Self, code_block: @import("../core/Element.zig").CodeBlock) !Widget {
        const CodeWidget = @import("CodeWidget.zig").CodeWidget;
        const widget = try CodeWidget.init(self.allocator, code_block.code, code_block.language);
        return Widget.init(widget);
    }

    fn createListWidget(self: Self, list: @import("../core/Element.zig").List) !Widget {
        const ListWidget = @import("ListWidget.zig").ListWidget;
        const widget = try ListWidget.init(self.allocator, list);
        return Widget.init(widget);
    }

    fn createBlockquoteWidget(self: Self, blockquote: @import("../core/Element.zig").Blockquote) !Widget {
        const TextWidget = @import("TextWidget.zig").TextWidget;
        const text = try inlineToPlainText(self.allocator, blockquote.content);
        defer self.allocator.free(text);
        const widget = try TextWidget.initBlockquote(self.allocator, text);
        return Widget.init(widget);
    }

    fn createImageWidget(self: Self, image: @import("../core/Element.zig").Image) !Widget {
        const ImageWidget = @import("ImageWidget.zig").ImageWidget;
        const widget = try ImageWidget.init(self.allocator, image.url, image.alt);
        return Widget.init(widget);
    }

    fn createThematicBreakWidget(self: Self) !Widget {
        const TextWidget = @import("TextWidget.zig").TextWidget;
        const widget = try TextWidget.initThematicBreak(self.allocator);
        return Widget.init(widget);
    }

    fn createTableWidget(self: Self, table: @import("../core/Element.zig").Table) !Widget {
        // For now, render as text representation
        _ = table;
        const TextWidget = @import("TextWidget.zig").TextWidget;
        const widget = try TextWidget.initParagraph(self.allocator, "[Table: render not yet implemented]");
        return Widget.init(widget);
    }

    fn createMediaWidget(self: Self, media: @import("../core/Element.zig").Media) !Widget {
        const TextWidget = @import("TextWidget.zig").TextWidget;
        const label = try std.fmt.allocPrint(self.allocator, "[{s}: {s}]", .{
            @tagName(media.media_type),
            std.fs.path.basename(media.url),
        });
        defer self.allocator.free(label);
        const widget = try TextWidget.initParagraph(self.allocator, label);
        return Widget.init(widget);
    }
};

/// Utility functions for widget drawing
pub const DrawUtils = struct {
    /// Fill a rectangular area with a character and style
    pub fn fill(win: vaxis.Window, x: usize, y: usize, width: usize, height: usize, char: []const u8, style: vaxis.Style) void {
        for (0..height) |row| {
            const target_row = y + row;
            if (target_row >= win.height) continue;

            for (0..width) |col| {
                const target_col = x + col;
                if (target_col >= win.width) continue;

                _ = win.writeCell(@intCast(target_col), @intCast(target_row), .{
                    .char = .{ .grapheme = char },
                    .style = style,
                });
            }
        }
    }

    /// Draw text at a position, wrapping if necessary
    pub fn drawText(win: vaxis.Window, x: usize, y: usize, text: []const u8, style: vaxis.Style, max_width: usize) usize {
        var col = x;
        var row = y;

        for (text) |char| {
            if (char == '\n') {
                row += 1;
                col = x;
                continue;
            }

            if (col >= x + max_width or col >= win.width) {
                row += 1;
                col = x;
                if (row >= win.height) break;
            }

            if (col < win.width and row < win.height) {
                _ = win.writeCell(@intCast(col), @intCast(row), .{
                    .char = .{ .grapheme = &[_]u8{char} },
                    .style = style,
                });
                col += 1;
            }
        }

        return row - y + 1; // Return number of lines used
    }

    /// Draw text with word wrapping
    pub fn drawTextWrapped(win: vaxis.Window, x: usize, y: usize, text: []const u8, style: vaxis.Style, max_width: usize) usize {
        var row: usize = y;
        var line_start: usize = 0;

        while (line_start < text.len and row < win.height) {
            // Find the end of this line
            var line_end = line_start;
            var last_space: ?usize = null;

            while (line_end < text.len and line_end - line_start < max_width) {
                if (text[line_end] == ' ') {
                    last_space = line_end;
                } else if (text[line_end] == '\n') {
                    line_end += 1;
                    break;
                }
                line_end += 1;
            }

            // If we went past max_width, back up to last space
            if (line_end - line_start > max_width) {
                if (last_space) |space| {
                    if (space > line_start) {
                        line_end = space + 1;
                    }
                }
            }

            // Draw the line
            const line = text[line_start..line_end];
            for (line, 0..) |char, col| {
                if (x + col >= win.width) break;
                if (char != '\n' and char != '\r') {
                    _ = win.writeCell(@intCast(x + col), @intCast(row), .{
                        .char = .{ .grapheme = &[_]u8{char} },
                        .style = style,
                    });
                }
            }

            line_start = line_end;
            row += 1;
        }

        return row - y;
    }

    /// Calculate how many lines text will take when wrapped
    pub fn measureWrappedLines(text: []const u8, max_width: usize) usize {
        if (text.len == 0 or max_width == 0) return 1;

        var lines: usize = 1;
        var line_start: usize = 0;

        while (line_start < text.len) {
            var line_end = line_start;
            var last_space: ?usize = null;

            while (line_end < text.len and line_end - line_start < max_width) {
                if (text[line_end] == ' ') {
                    last_space = line_end;
                } else if (text[line_end] == '\n') {
                    line_end += 1;
                    break;
                }
                line_end += 1;
            }

            if (line_end - line_start > max_width) {
                if (last_space) |space| {
                    if (space > line_start) {
                        line_end = space + 1;
                    }
                }
            }

            line_start = line_end;
            if (line_start < text.len) {
                lines += 1;
            }
        }

        return lines;
    }
};

/// Convert theme ElementStyle to vaxis Style
pub fn toVaxisStyle(element_style: @import("../render/Theme.zig").ElementStyle) vaxis.Style {
    var style: vaxis.Style = .{};

    if (element_style.fg) |fg| {
        if (@import("../render/Theme.zig").Theme.toRgb(fg)) |rgb| {
            style.fg = .{ .rgb = rgb };
        }
    }

    if (element_style.bg) |bg| {
        if (@import("../render/Theme.zig").Theme.toRgb(bg)) |rgb| {
            style.bg = .{ .rgb = rgb };
        }
    }

    style.bold = element_style.bold orelse false;
    style.italic = element_style.italic orelse false;
    if (element_style.underline orelse false) {
        style.ul_style = .single;
    }

    return style;
}
