//! Code widget for rendering code blocks with syntax highlighting
const std = @import("std");
const vaxis = @import("vaxis");
const DrawContext = @import("Widget.zig").DrawContext;
const Constraints = @import("Widget.zig").Constraints;
const Size = @import("Widget.zig").Size;
const DrawUtils = @import("Widget.zig").DrawUtils;
const toVaxisStyle = @import("Widget.zig").toVaxisStyle;
const Highlighter = @import("../highlight/Highlighter.zig").Highlighter;
const Language = @import("../highlight/Language.zig").Language;
const Token = @import("../highlight/Token.zig").Token;
const TokenKind = @import("../highlight/Token.zig").TokenKind;

/// CodeWidget renders code blocks with optional syntax highlighting
pub const CodeWidget = struct {
    allocator: std.mem.Allocator,
    code: []const u8,
    language: ?[]const u8,
    tokens: ?[]Token,

    const Self = @This();

    /// Initialize code widget
    pub fn init(allocator: std.mem.Allocator, code: []const u8, language: ?[]const u8) !*Self {
        const self = try allocator.create(Self);

        // Copy code
        const code_copy = try allocator.dupe(u8, code);

        // Copy language if provided
        const lang_copy = if (language) |l| try allocator.dupe(u8, l) else null;

        self.* = .{
            .allocator = allocator,
            .code = code_copy,
            .language = lang_copy,
            .tokens = null,
        };

        // Tokenize for syntax highlighting
        try self.tokenize();

        return self;
    }

    /// Clean up resources
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.code);
        if (self.language) |l| self.allocator.free(l);
        if (self.tokens) |tokens| self.allocator.free(tokens);
        self.allocator.destroy(self);
    }

    /// Tokenize code for syntax highlighting
    fn tokenize(self: *Self) !void {
        const lang = self.detectLanguage();
        if (lang == .unknown) {
            self.tokens = null;
            return;
        }

        var highlighter = Highlighter.init(self.code, lang);
        self.tokens = try highlighter.tokenizeAll(self.allocator);
    }

    /// Detect language from language string
    fn detectLanguage(self: Self) Language {
        const lang_str = self.language orelse return .unknown;
        return Language.fromString(lang_str);
    }

    /// Draw the code widget
    pub fn draw(self: *Self, ctx: DrawContext, x: usize, y: usize) void {
        // Calculate dimensions
        const available_width = if (ctx.win.width > x + 2) ctx.win.width - x - 2 else 0;
        if (available_width == 0) return;

        // Draw border
        self.drawBorder(ctx, x, y, available_width);

        // Draw code content with highlighting
        self.drawCode(ctx, x + 1, y + 1, available_width - 2);
    }

    /// Get the size of the widget
    pub fn getSize(self: *Self, constraints: Constraints) Size {
        const available_width = @min(constraints.max_width, 80);

        // Calculate lines needed
        var lines: usize = 2; // Border padding
        var line_start: usize = 0;

        while (line_start < self.code.len) {
            const line_end = std.mem.indexOfScalarPos(u8, self.code, line_start, '\n') orelse self.code.len;
            const line_len = line_end - line_start;

            // Account for wrapping
            const wrapped_lines = @max(1, (line_len + available_width - 4 - 1) / (available_width - 4));
            lines += wrapped_lines;

            line_start = line_end + 1;
        }

        return .{
            .width = @min(available_width, 80),
            .height = lines,
        };
    }

    fn drawBorder(self: Self, ctx: DrawContext, x: usize, y: usize, width: usize) void {
        // Draw top border
        if (y < ctx.win.height) {
            for (0..width) |col| {
                if (x + col >= ctx.win.width) break;
                _ = ctx.win.writeCell(@intCast(x + col), @intCast(y), .{
                    .char = .{ .grapheme = "─" },
                    .style = .{ .fg = .{ .rgb = .{ 100, 100, 100 } } },
                });
            }
        }

        // Draw side borders
        const height = self.getHeight(width);
        for (1..height) |row| {
            const target_row = y + row;
            if (target_row >= ctx.win.height) break;

            // Left border
            if (x < ctx.win.width) {
                _ = ctx.win.writeCell(@intCast(x), @intCast(target_row), .{
                    .char = .{ .grapheme = "│" },
                    .style = .{ .fg = .{ .rgb = .{ 100, 100, 100 } } },
                });
            }

            // Right border
            if (x + width - 1 < ctx.win.width) {
                _ = ctx.win.writeCell(@intCast(x + width - 1), @intCast(target_row), .{
                    .char = .{ .grapheme = "│" },
                    .style = .{ .fg = .{ .rgb = .{ 100, 100, 100 } } },
                });
            }
        }

        // Draw bottom border
        const bottom_row = y + height - 1;
        if (bottom_row < ctx.win.height) {
            for (0..width) |col| {
                if (x + col >= ctx.win.width) break;
                _ = ctx.win.writeCell(@intCast(x + col), @intCast(bottom_row), .{
                    .char = .{ .grapheme = "─" },
                    .style = .{ .fg = .{ .rgb = .{ 100, 100, 100 } } },
                });
            }
        }

        // Corners
        if (y < ctx.win.height and x < ctx.win.width) {
            _ = ctx.win.writeCell(@intCast(x), @intCast(y), .{
                .char = .{ .grapheme = "┌" },
                .style = .{ .fg = .{ .rgb = .{ 100, 100, 100 } } },
            });
        }
        if (y < ctx.win.height and x + width - 1 < ctx.win.width) {
            _ = ctx.win.writeCell(@intCast(x + width - 1), @intCast(y), .{
                .char = .{ .grapheme = "┐" },
                .style = .{ .fg = .{ .rgb = .{ 100, 100, 100 } } },
            });
        }
        if (bottom_row < ctx.win.height and x < ctx.win.width) {
            _ = ctx.win.writeCell(@intCast(x), @intCast(bottom_row), .{
                .char = .{ .grapheme = "└" },
                .style = .{ .fg = .{ .rgb = .{ 100, 100, 100 } } },
            });
        }
        if (bottom_row < ctx.win.height and x + width - 1 < ctx.win.width) {
            _ = ctx.win.writeCell(@intCast(x + width - 1), @intCast(bottom_row), .{
                .char = .{ .grapheme = "┘" },
                .style = .{ .fg = .{ .rgb = .{ 100, 100, 100 } } },
            });
        }
    }

    fn drawCode(self: *Self, ctx: DrawContext, x: usize, y: usize, max_width: usize) void {
        if (self.tokens) |tokens| {
            self.drawHighlightedCode(ctx, x, y, max_width, tokens);
        } else {
            self.drawPlainCode(ctx, x, y, max_width);
        }
    }

    fn drawHighlightedCode(self: *Self, ctx: DrawContext, x: usize, y: usize, max_width: usize, tokens: []Token) void {
        _ = self;

        var row = y;
        var col = x;

        for (tokens) |token| {
            if (token.kind == .eof) break;

            const token_color = token.kind.defaultColor();
            const rgb = defaultColorToRgb(token_color);
            const style: vaxis.Style = if (rgb) |c| .{ .fg = c } else .{};

            for (token.text) |c| {
                if (c == '\n') {
                    row += 1;
                    col = x;
                    continue;
                }

                if (col >= x + max_width) {
                    row += 1;
                    col = x;
                }

                if (col < ctx.win.width and row < ctx.win.height) {
                    _ = ctx.win.writeCell(@intCast(col), @intCast(row), .{
                        .char = .{ .grapheme = &[_]u8{c} },
                        .style = style,
                    });
                    col += 1;
                }
            }
        }
    }

    fn drawPlainCode(self: *Self, ctx: DrawContext, x: usize, y: usize, max_width: usize) void {
        const code_style = toVaxisStyle(ctx.theme.code_block);

        var row = y;
        var col = x;

        for (self.code) |c| {
            if (c == '\n') {
                row += 1;
                col = x;
                continue;
            }

            if (col >= x + max_width) {
                row += 1;
                col = x;
            }

            if (col < ctx.win.width and row < ctx.win.height) {
                _ = ctx.win.writeCell(@intCast(col), @intCast(row), .{
                    .char = .{ .grapheme = &[_]u8{c} },
                    .style = code_style,
                });
                col += 1;
            }
        }
    }

    inline fn getHeight(self: Self, width: usize) usize {
        const content_width = if (width > 4) width - 4 else 1;
        var lines: usize = 2; // Top and bottom border

        var line_start: usize = 0;
        while (line_start < self.code.len) {
            const line_end = std.mem.indexOfScalarPos(u8, self.code, line_start, '\n') orelse self.code.len;
            const line_len = line_end - line_start;

            const wrapped_lines = @max(1, (line_len + content_width - 1) / content_width);
            lines += wrapped_lines;

            line_start = line_end + 1;
        }

        return lines;
    }

    fn defaultColorToRgb(color: @import("../highlight/Token.zig").DefaultColor) ?@import("vaxis").Cell.Color {
        return switch (color) {
            .default => null,
            .black => .{ .rgb = .{ 0, 0, 0 } },
            .red => .{ .rgb = .{ 205, 49, 49 } },
            .green => .{ .rgb = .{ 13, 188, 121 } },
            .yellow => .{ .rgb = .{ 229, 229, 16 } },
            .blue => .{ .rgb = .{ 36, 114, 200 } },
            .magenta => .{ .rgb = .{ 188, 63, 188 } },
            .cyan => .{ .rgb = .{ 17, 168, 205 } },
            .white => .{ .rgb = .{ 229, 229, 229 } },
            .bright_black => .{ .rgb = .{ 102, 102, 102 } },
            .bright_red => .{ .rgb = .{ 241, 76, 76 } },
            .bright_green => .{ .rgb = .{ 35, 209, 139 } },
            .bright_yellow => .{ .rgb = .{ 245, 245, 67 } },
            .bright_blue => .{ .rgb = .{ 59, 142, 234 } },
            .bright_magenta => .{ .rgb = .{ 214, 112, 214 } },
            .bright_cyan => .{ .rgb = .{ 41, 184, 219 } },
            .bright_white => .{ .rgb = .{ 255, 255, 255 } },
        };
    }
};

test "CodeWidget basic" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const code = "const x = 42;";
    var widget = try CodeWidget.init(allocator, code, "zig");
    defer widget.deinit();

    try testing.expectEqualStrings(code, widget.code);
    try testing.expect(widget.language != null);
    try testing.expectEqualStrings("zig", widget.language.?);
    try testing.expect(widget.tokens != null);
}

test "CodeWidget without language" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const code = "some plain text";
    var widget = try CodeWidget.init(allocator, code, null);
    defer widget.deinit();

    try testing.expectEqualStrings(code, widget.code);
    try testing.expect(widget.language == null);
}

test "CodeWidget size calculation" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const code = "line1\nline2\nline3";
    var widget = try CodeWidget.init(allocator, code, null);
    defer widget.deinit();

    const size = widget.getSize(.{ .max_width = 80 });
    try testing.expect(size.width > 0);
    try testing.expect(size.height >= 5); // 3 lines + borders
}
