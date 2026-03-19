//! Widget for displaying speaker notes
const std = @import("std");
const tui = @import("../tui/root.zig");
const Note = @import("../core/Note.zig").Note;
const Theme = @import("../render/Theme.zig").Theme;

/// NoteWidget displays speaker notes for the current slide
pub const NoteWidget = struct {
    allocator: std.mem.Allocator,
    note: ?Note = null,
    visible: bool = true,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .note = null,
            .visible = true,
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.note) |note| {
            note.deinit(self.allocator);
        }
    }

    /// Set the note to display
    pub fn setNote(self: *Self, note: ?Note) void {
        if (self.note) |old_note| {
            old_note.deinit(self.allocator);
        }
        self.note = note;
    }

    /// Clear the current note
    pub fn clearNote(self: *Self) void {
        if (self.note) |note| {
            note.deinit(self.allocator);
            self.note = null;
        }
    }

    /// Toggle visibility
    pub fn toggle(self: *Self) void {
        self.visible = !self.visible;
    }

    /// Show the widget
    pub fn show(self: *Self) void {
        self.visible = true;
    }

    /// Hide the widget
    pub fn hide(self: *Self) void {
        self.visible = false;
    }

    /// Check if there's a note to display
    pub fn hasNote(self: Self) bool {
        return self.note != null and !self.note.?.isEmpty();
    }

    /// Draw the note widget
    pub fn draw(self: Self, win: tui.Window, theme: Theme) void {
        if (!self.visible) return;
        if (!self.hasNote()) {
            self.drawEmpty(win, theme);
            return;
        }

        const content = self.note.?.getContent();

        // Draw border/top line
        for (0..win.width) |col| {
            const cell = win.cellIndex(.{ .row = 0, .col = @intCast(col) });
            win.setCell(cell, .{
                .char = .{ .grapheme = "─" },
                .style = .{
                    .fg = theme.thematic_break.fg,
                },
            });
        }

        // Draw "Notes:" label
        const label = "Notes: ";
        for (label, 0..) |char, i| {
            if (i >= win.width) break;
            const cell = win.cellIndex(.{ .row = 1, .col = @intCast(i) });
            win.setCell(cell, .{
                .char = .{ .grapheme = tui.Cell.grapheme(char) },
                .style = .{
                    .fg = theme.heading3.fg,
                    .bold = true,
                },
            });
        }

        // Draw note content (word wrapped)
        const text_start_col = 0;
        var row: usize = 2;
        var col: usize = text_start_col;

        var word_start: usize = 0;
        var in_word = false;

        for (content) |char| {
            if (row >= win.height) break;

            if (std.ascii.isWhitespace(char)) {
                if (in_word) {
                    // End of word - write it
                    const word = content[word_start .. @intFromPtr(&char) - @intFromPtr(content.ptr)];
                    if (col + word.len > win.width and col > text_start_col) {
                        row += 1;
                        col = text_start_col;
                        if (row >= win.height) break;
                    }
                    in_word = false;
                }

                if (char == '\n') {
                    row += 1;
                    col = text_start_col;
                } else {
                    // Add space if not at start of line
                    if (col < win.width and col > text_start_col) {
                        col += 1;
                    }
                }
            } else {
                if (!in_word) {
                    word_start = @intFromPtr(&char) - @intFromPtr(content.ptr);
                    in_word = true;
                }
                if (col < win.width) {
                    const cell = win.cellIndex(.{ .row = @intCast(row), .col = @intCast(col) });
                    win.setCell(cell, .{
                        .char = .{ .grapheme = tui.Cell.grapheme(char) },
                        .style = .{
                            .fg = theme.paragraph.fg,
                        },
                    });
                    col += 1;
                }
            }
        }
    }

    /// Draw empty state when no notes
    fn drawEmpty(_: Self, win: tui.Window, theme: Theme) void {
        const msg = "No notes for this slide";
        const start_col = @divTrunc(win.width, 2) - @divTrunc(msg.len, 2);

        // Draw border
        for (0..win.width) |col| {
            const cell = win.cellIndex(.{ .row = 0, .col = @intCast(col) });
            win.setCell(cell, .{
                .char = .{ .grapheme = "─" },
                .style = .{
                    .fg = theme.thematic_break.fg,
                },
            });
        }

        // Draw message
        for (msg, 0..) |char, i| {
            const col = start_col + i;
            if (col >= win.width) break;
            const cell = win.cellIndex(.{ .row = 1, .col = @intCast(col) });
            win.setCell(cell, .{
                .char = .{ .grapheme = tui.Cell.grapheme(char) },
                .style = .{
                    .fg = theme.bright_black,
                    .italic = true,
                },
            });
        }
    }

    /// Get minimum height needed
    pub fn getMinHeight(_: Self) usize {
        return 3; // Border + label + at least one line
    }

    /// Get preferred height based on content
    pub fn getPreferredHeight(self: Self, width: usize) usize {
        if (!self.hasNote()) return 3;

        const content = self.note.?.getContent();
        var lines: usize = 1;
        var line_len: usize = 0;

        for (content) |char| {
            if (char == '\n') {
                lines += 1;
                line_len = 0;
            } else {
                line_len += 1;
                if (line_len >= width) {
                    lines += 1;
                    line_len = 0;
                }
            }
        }

        return @max(3, lines + 2); // +2 for border and label
    }
};

test "NoteWidget basic" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var widget = NoteWidget.init(allocator);
    defer widget.deinit();

    try testing.expect(!widget.hasNote());

    // Set a note
    const note = try Note.init(allocator, "Test note content");
    widget.setNote(note);

    try testing.expect(widget.hasNote());
    try testing.expectEqualStrings("Test note content", widget.note.?.getContent());

    // Clear note
    widget.clearNote();
    try testing.expect(!widget.hasNote());
}

test "NoteWidget visibility" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var widget = NoteWidget.init(allocator);
    defer widget.deinit();

    try testing.expect(widget.visible);

    widget.toggle();
    try testing.expect(!widget.visible);

    widget.show();
    try testing.expect(widget.visible);

    widget.hide();
    try testing.expect(!widget.visible);
}

test "NoteWidget preferred height" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var widget = NoteWidget.init(allocator);
    defer widget.deinit();

    // Empty note
    try testing.expectEqual(@as(usize, 3), widget.getPreferredHeight(80));

    // Short note
    const note = try Note.init(allocator, "Short note");
    widget.setNote(note);
    try testing.expect(widget.getPreferredHeight(80) >= 3);
}
