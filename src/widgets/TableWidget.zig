//! Table widget for rendering markdown tables with box-drawing borders
const std = @import("std");
const tui = @import("../tui/root.zig");
const DrawContext = @import("Widget.zig").DrawContext;
const Constraints = @import("Widget.zig").Constraints;
const Size = @import("Widget.zig").Size;
const DrawUtils = @import("Widget.zig").DrawUtils;
const toStyle = @import("Widget.zig").toStyle;
const Table = @import("../core/Element.zig").Table;
const Inline = @import("../core/Element.zig").Inline;
const inlineToPlainText = @import("../core/Element.zig").inlineToPlainText;

pub const Alignment = Table.Alignment;

/// TableWidget renders a table with box-drawing borders
pub const TableWidget = struct {
    allocator: std.mem.Allocator,
    header_texts: [][]const u8,
    cell_texts: [][]const u8,
    col_widths: []usize,
    alignments: []Alignment,
    num_cols: usize,
    num_rows: usize,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, table: Table) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        const num_cols = if (table.headers.len > 0) table.headers.len else 1;
        const num_rows = table.rows.len;

        // Convert header cells to plain text
        const header_texts = try allocator.alloc([]const u8, num_cols);
        var headers_inited: usize = 0;
        errdefer {
            for (header_texts[0..headers_inited]) |t| allocator.free(t);
            allocator.free(header_texts);
        }

        if (table.headers.len > 0) {
            for (table.headers, 0..) |cell, i| {
                header_texts[i] = try inlineToPlainText(allocator, cell.content);
                headers_inited += 1;
            }
        } else {
            header_texts[0] = try allocator.dupe(u8, "(empty)");
            headers_inited = 1;
        }

        // Convert row cells to plain text (flat array: row * num_cols + col)
        const cell_texts = try allocator.alloc([]const u8, num_rows * num_cols);
        var cells_inited: usize = 0;
        errdefer {
            for (cell_texts[0..cells_inited]) |t| allocator.free(t);
            allocator.free(cell_texts);
        }

        for (table.rows, 0..) |row, r| {
            for (0..num_cols) |c| {
                const idx = r * num_cols + c;
                if (c < row.len) {
                    cell_texts[idx] = try inlineToPlainText(allocator, row[c].content);
                } else {
                    cell_texts[idx] = try allocator.dupe(u8, "");
                }
                cells_inited += 1;
            }
        }

        // Compute column widths
        const col_widths = try allocator.alloc(usize, num_cols);
        for (0..num_cols) |c| {
            var max_len: usize = DrawUtils.utf8VisualLen(header_texts[c]);
            for (0..num_rows) |r| {
                const cell_len = DrawUtils.utf8VisualLen(cell_texts[r * num_cols + c]);
                max_len = @max(max_len, cell_len);
            }
            col_widths[c] = max_len + 2; // 1 space padding each side
        }

        // Copy/pad alignments
        const alignments = try allocator.alloc(Alignment, num_cols);
        for (0..num_cols) |c| {
            alignments[c] = if (c < table.alignments.len) table.alignments[c] else .default;
        }

        self.* = .{
            .allocator = allocator,
            .header_texts = header_texts,
            .cell_texts = cell_texts,
            .col_widths = col_widths,
            .alignments = alignments,
            .num_cols = num_cols,
            .num_rows = num_rows,
        };
        return self;
    }

    pub fn deinit(self: *Self) void {
        for (self.header_texts) |t| self.allocator.free(t);
        self.allocator.free(self.header_texts);
        for (self.cell_texts) |t| self.allocator.free(t);
        self.allocator.free(self.cell_texts);
        self.allocator.free(self.col_widths);
        self.allocator.free(self.alignments);
        self.allocator.destroy(self);
    }

    pub fn draw(self: *Self, ctx: DrawContext, x: usize, y: usize) void {
        const border_style = tui.Style{ .fg = .{ .rgb = .{ 100, 100, 100 } } };
        const header_style = toStyle(ctx.theme.strong);
        const text_style = toStyle(ctx.theme.paragraph);

        var row = y;

        // Top border: ┌──┬──┐
        self.drawHorizontalRule(ctx.win, x, row, "┌", "┬", "┐", border_style);
        row += 1;

        // Header row
        self.drawDataRow(ctx.win, x, row, self.header_texts, header_style, border_style);
        row += 1;

        // Separator: ├──┼──┤
        self.drawHorizontalRule(ctx.win, x, row, "├", "┼", "┤", border_style);
        row += 1;

        // Data rows
        for (0..self.num_rows) |r| {
            const start = r * self.num_cols;
            const end = start + self.num_cols;
            self.drawDataRow(ctx.win, x, row, self.cell_texts[start..end], text_style, border_style);
            row += 1;
        }

        // Bottom border: └──┴──┘
        self.drawHorizontalRule(ctx.win, x, row, "└", "┴", "┘", border_style);
    }

    fn drawHorizontalRule(self: *Self, win: tui.Window, x: usize, y: usize, left: []const u8, mid: []const u8, right: []const u8, style: tui.Style) void {
        if (y >= win.height) return;

        var col = x;
        if (col >= win.width) return;

        // Left corner
        win.writeCell(@intCast(col), @intCast(y), .{
            .char = .{ .grapheme = left },
            .style = style,
        });
        col += 1;

        for (0..self.num_cols) |c| {
            // Fill column width with ─
            for (0..self.col_widths[c]) |_| {
                if (col >= win.width) return;
                win.writeCell(@intCast(col), @intCast(y), .{
                    .char = .{ .grapheme = "─" },
                    .style = style,
                });
                col += 1;
            }

            // Mid or right corner
            if (col >= win.width) return;
            const corner = if (c == self.num_cols - 1) right else mid;
            win.writeCell(@intCast(col), @intCast(y), .{
                .char = .{ .grapheme = corner },
                .style = style,
            });
            col += 1;
        }
    }

    fn drawDataRow(self: *Self, win: tui.Window, x: usize, y: usize, texts: []const []const u8, text_style: tui.Style, border_style: tui.Style) void {
        if (y >= win.height) return;

        var col = x;
        if (col >= win.width) return;

        // Left border
        win.writeCell(@intCast(col), @intCast(y), .{
            .char = .{ .grapheme = "│" },
            .style = border_style,
        });
        col += 1;

        for (0..self.num_cols) |c| {
            const text = if (c < texts.len) texts[c] else "";
            const content_width = self.col_widths[c] - 2; // minus padding
            const text_len = DrawUtils.utf8VisualLen(text);
            const padding = if (content_width > text_len) content_width - text_len else 0;

            // Compute left/right padding based on alignment
            var left_pad: usize = 0;
            var right_pad: usize = 0;
            switch (self.alignments[c]) {
                .right => {
                    left_pad = padding;
                    right_pad = 0;
                },
                .center => {
                    left_pad = padding / 2;
                    right_pad = padding - left_pad;
                },
                else => { // left, default
                    left_pad = 0;
                    right_pad = padding;
                },
            }

            // Leading space
            if (col < win.width) {
                win.writeCell(@intCast(col), @intCast(y), .{
                    .char = .{ .grapheme = " " },
                    .style = text_style,
                });
                col += 1;
            }

            // Left padding
            for (0..left_pad) |_| {
                if (col >= win.width) return;
                win.writeCell(@intCast(col), @intCast(y), .{
                    .char = .{ .grapheme = " " },
                    .style = text_style,
                });
                col += 1;
            }

            // Text content (UTF-8 aware)
            var ti: usize = 0;
            while (ti < text.len) {
                if (col >= win.width) return;
                const seq_len = std.unicode.utf8ByteSequenceLength(text[ti]) catch 1;
                const tend = @min(ti + seq_len, text.len);
                win.writeCell(@intCast(col), @intCast(y), .{
                    .char = .{ .grapheme = text[ti..tend] },
                    .style = text_style,
                });
                col += 1;
                ti = tend;
            }

            // Right padding
            for (0..right_pad) |_| {
                if (col >= win.width) return;
                win.writeCell(@intCast(col), @intCast(y), .{
                    .char = .{ .grapheme = " " },
                    .style = text_style,
                });
                col += 1;
            }

            // Trailing space
            if (col < win.width) {
                win.writeCell(@intCast(col), @intCast(y), .{
                    .char = .{ .grapheme = " " },
                    .style = text_style,
                });
                col += 1;
            }

            // Column separator
            if (col >= win.width) return;
            win.writeCell(@intCast(col), @intCast(y), .{
                .char = .{ .grapheme = "│" },
                .style = border_style,
            });
            col += 1;
        }
    }

    pub fn getSize(self: *Self, constraints: Constraints) Size {
        // width = (num_cols + 1) separators + sum(col_widths)
        var total_width: usize = self.num_cols + 1;
        for (self.col_widths) |w| {
            total_width += w;
        }
        // height = top border + header + separator + bottom border + data rows
        const total_height: usize = self.num_rows + 4;

        return .{
            .width = @min(total_width, constraints.max_width),
            .height = @min(total_height, constraints.max_height),
        };
    }
};

// Tests
test "TableWidget init/deinit" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Create a 2x2 table
    var headers: [2]Table.TableCell = undefined;
    const h1_content = try allocator.alloc(Inline, 1);
    h1_content[0] = .{ .text = try allocator.dupe(u8, "Name") };
    headers[0] = .{ .content = h1_content };

    const h2_content = try allocator.alloc(Inline, 1);
    h2_content[0] = .{ .text = try allocator.dupe(u8, "Age") };
    headers[1] = .{ .content = h2_content };

    // Create rows
    var row1: [2]Table.TableCell = undefined;
    const r1c1 = try allocator.alloc(Inline, 1);
    r1c1[0] = .{ .text = try allocator.dupe(u8, "Alice") };
    row1[0] = .{ .content = r1c1 };
    const r1c2 = try allocator.alloc(Inline, 1);
    r1c2[0] = .{ .text = try allocator.dupe(u8, "30") };
    row1[1] = .{ .content = r1c2 };

    var row2: [2]Table.TableCell = undefined;
    const r2c1 = try allocator.alloc(Inline, 1);
    r2c1[0] = .{ .text = try allocator.dupe(u8, "Bob") };
    row2[0] = .{ .content = r2c1 };
    const r2c2 = try allocator.alloc(Inline, 1);
    r2c2[0] = .{ .text = try allocator.dupe(u8, "25") };
    row2[1] = .{ .content = r2c2 };

    const rows_data = try allocator.alloc([]Table.TableCell, 2);
    rows_data[0] = try allocator.dupe(Table.TableCell, &row1);
    rows_data[1] = try allocator.dupe(Table.TableCell, &row2);

    const aligns = try allocator.alloc(Alignment, 2);
    aligns[0] = .left;
    aligns[1] = .right;

    const table = Table{
        .headers = try allocator.dupe(Table.TableCell, &headers),
        .rows = rows_data,
        .alignments = aligns,
    };
    defer table.deinit(allocator);

    var widget = try TableWidget.init(allocator, table);
    defer widget.deinit();

    try testing.expectEqual(@as(usize, 2), widget.num_cols);
    try testing.expectEqual(@as(usize, 2), widget.num_rows);
}

test "TableWidget getSize" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Create a simple 1-col table
    var headers: [1]Table.TableCell = undefined;
    const h_content = try allocator.alloc(Inline, 1);
    h_content[0] = .{ .text = try allocator.dupe(u8, "Header") };
    headers[0] = .{ .content = h_content };

    var row1: [1]Table.TableCell = undefined;
    const r_content = try allocator.alloc(Inline, 1);
    r_content[0] = .{ .text = try allocator.dupe(u8, "Data") };
    row1[0] = .{ .content = r_content };

    const rows_data = try allocator.alloc([]Table.TableCell, 1);
    rows_data[0] = try allocator.dupe(Table.TableCell, &row1);

    const aligns = try allocator.alloc(Alignment, 0);

    const table = Table{
        .headers = try allocator.dupe(Table.TableCell, &headers),
        .rows = rows_data,
        .alignments = aligns,
    };
    defer table.deinit(allocator);

    var widget = try TableWidget.init(allocator, table);
    defer widget.deinit();

    const size = widget.getSize(.{ .max_width = 80, .max_height = 40 });
    // 1 col: width = 2 separators + col_width(Header=6 + 2 padding = 8) = 10
    try testing.expectEqual(@as(usize, 10), size.width);
    // height = 1 row + 4 = 5
    try testing.expectEqual(@as(usize, 5), size.height);
}

test "TableWidget empty rows" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var headers: [2]Table.TableCell = undefined;
    const h1 = try allocator.alloc(Inline, 1);
    h1[0] = .{ .text = try allocator.dupe(u8, "A") };
    headers[0] = .{ .content = h1 };
    const h2 = try allocator.alloc(Inline, 1);
    h2[0] = .{ .text = try allocator.dupe(u8, "B") };
    headers[1] = .{ .content = h2 };

    const rows_data = try allocator.alloc([]Table.TableCell, 0);
    const aligns = try allocator.alloc(Alignment, 0);

    const table = Table{
        .headers = try allocator.dupe(Table.TableCell, &headers),
        .rows = rows_data,
        .alignments = aligns,
    };
    defer table.deinit(allocator);

    var widget = try TableWidget.init(allocator, table);
    defer widget.deinit();

    try testing.expectEqual(@as(usize, 2), widget.num_cols);
    try testing.expectEqual(@as(usize, 0), widget.num_rows);

    const size = widget.getSize(.{ .max_width = 80, .max_height = 40 });
    // height = 0 rows + 4 = 4
    try testing.expectEqual(@as(usize, 4), size.height);
}

test "TableWidget col widths" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Header "Hi" (2 chars), cell "Hello" (5 chars) -> col_width should be 7 (5+2 padding)
    var headers: [1]Table.TableCell = undefined;
    const hc = try allocator.alloc(Inline, 1);
    hc[0] = .{ .text = try allocator.dupe(u8, "Hi") };
    headers[0] = .{ .content = hc };

    var row1: [1]Table.TableCell = undefined;
    const rc = try allocator.alloc(Inline, 1);
    rc[0] = .{ .text = try allocator.dupe(u8, "Hello") };
    row1[0] = .{ .content = rc };

    const rows_data = try allocator.alloc([]Table.TableCell, 1);
    rows_data[0] = try allocator.dupe(Table.TableCell, &row1);

    const aligns = try allocator.alloc(Alignment, 0);

    const table = Table{
        .headers = try allocator.dupe(Table.TableCell, &headers),
        .rows = rows_data,
        .alignments = aligns,
    };
    defer table.deinit(allocator);

    var widget = try TableWidget.init(allocator, table);
    defer widget.deinit();

    // col_width = max(2, 5) + 2 = 7
    try testing.expectEqual(@as(usize, 7), widget.col_widths[0]);
}
