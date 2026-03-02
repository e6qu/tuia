//! Parser for speaker notes in markdown
const std = @import("std");
const Note = @import("../core/Note.zig").Note;
const NotesCollection = @import("../core/Note.zig").NotesCollection;

/// Parser for extracting speaker notes from markdown content
pub const NoteParser = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Common note comment patterns
    const NOTE_START = "<!-- note";
    const NOTE_END_SIMPLE = "-->";
    const NOTE_END_EXPLICIT = "<!-- endnote -->";

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
        };
    }

    /// Parse notes from markdown content and associate with slides
    /// Returns a NotesCollection with notes indexed by slide number
    pub fn parseNotes(self: Self, content: []const u8) !NotesCollection {
        var collection = NotesCollection.init(self.allocator);
        errdefer collection.deinit(self.allocator);

        var slide_index: usize = 0;
        var pos: usize = 0;

        while (pos < content.len) {
            // Find next note comment
            const note_start = std.mem.indexOfPos(u8, content, pos, NOTE_START);
            if (note_start == null) break;

            const start_idx = note_start.?;

            // Find end of note comment
            const end_idx = blk: {
                // Try explicit end first
                if (std.mem.indexOfPos(u8, content, start_idx, NOTE_END_EXPLICIT)) |end| {
                    break :blk end;
                }
                // Fall back to simple end
                if (std.mem.indexOfPos(u8, content, start_idx, NOTE_END_SIMPLE)) |end| {
                    break :blk end + NOTE_END_SIMPLE.len;
                }
                break :blk content.len;
            };

            // Extract note content
            const note_content = self.extractNoteContent(content[start_idx..end_idx]);
            if (note_content.len > 0) {
                try collection.setNote(self.allocator, slide_index, note_content);
            }

            // Move past this note
            pos = end_idx;

            // Count slide separators between notes to track slide index
            const slide_sep = std.mem.indexOfPos(u8, content, start_idx, "<!-- end_slide -->");
            if (slide_sep) |sep| {
                if (sep < end_idx) {
                    slide_index += 1;
                }
            }
        }

        return collection;
    }

    /// Extract note content from a note comment
    fn extractNoteContent(_: Self, comment: []const u8) []const u8 {
        // Remove <!-- note and -->
        var start: usize = NOTE_START.len;

        // Skip optional colon or space after "note"
        if (start < comment.len and (comment[start] == ':' or comment[start] == ' ')) {
            start += 1;
            // Skip additional spaces
            while (start < comment.len and comment[start] == ' ') {
                start += 1;
            }
        }

        // Find end of content (before --> or <!-- endnote -->)
        var end = comment.len;
        if (std.mem.endsWith(u8, comment, NOTE_END_SIMPLE)) {
            end = comment.len - NOTE_END_SIMPLE.len;
        } else if (std.mem.endsWith(u8, comment, NOTE_END_EXPLICIT)) {
            end = std.mem.indexOf(u8, comment, NOTE_END_EXPLICIT) orelse comment.len;
        }

        // Trim whitespace
        while (start < end and std.ascii.isWhitespace(comment[start])) {
            start += 1;
        }
        while (end > start and std.ascii.isWhitespace(comment[end - 1])) {
            end -= 1;
        }

        return comment[start..end];
    }

    /// Parse notes from a specific slide's content
    pub fn parseSlideNotes(self: Self, slide_content: []const u8) !?Note {
        const content = self.extractFirstNote(slide_content);
        if (content.len == 0) return null;

        return try Note.init(self.allocator, content);
    }

    /// Extract the first note from content
    fn extractFirstNote(_: Self, content: []const u8) []const u8 {
        const start = std.mem.indexOf(u8, content, NOTE_START) orelse return "";

        // Find end of comment
        const end = blk: {
            if (std.mem.indexOfPos(u8, content, start, NOTE_END_EXPLICIT)) |e| {
                break :blk e;
            }
            if (std.mem.indexOfPos(u8, content, start, NOTE_END_SIMPLE)) |e| {
                break :blk e + NOTE_END_SIMPLE.len;
            }
            break :blk content.len;
        };

        const comment = content[start..end];

        // Extract content after "<!-- note" and before end
        var content_start = NOTE_START.len;
        if (content_start < comment.len and (comment[content_start] == ':' or comment[content_start] == ' ')) {
            content_start += 1;
            while (content_start < comment.len and comment[content_start] == ' ') {
                content_start += 1;
            }
        }

        var content_end = comment.len;
        if (std.mem.endsWith(u8, comment, NOTE_END_SIMPLE)) {
            content_end = comment.len - NOTE_END_SIMPLE.len;
        } else if (std.mem.indexOf(u8, comment, NOTE_END_EXPLICIT)) |e| {
            content_end = e;
        }

        // Trim
        while (content_start < content_end and std.ascii.isWhitespace(comment[content_start])) {
            content_start += 1;
        }
        while (content_end > content_start and std.ascii.isWhitespace(comment[content_end - 1])) {
            content_end -= 1;
        }

        return comment[content_start..content_end];
    }
};

test "NoteParser extract note content" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const parser = NoteParser.init(allocator);

    // Simple note
    const content1 = "<!-- note: Remember to mention key points -->";
    const note1 = try parser.parseSlideNotes(content1);
    defer if (note1) |n| n.deinit(allocator);
    try testing.expect(note1 != null);
    try testing.expectEqualStrings("Remember to mention key points", note1.?.getContent());

    // Note without colon
    const content2 = "<!-- note Don't forget the demo -->";
    const note2 = try parser.parseSlideNotes(content2);
    defer if (note2) |n| n.deinit(allocator);
    try testing.expect(note2 != null);
    try testing.expectEqualStrings("Don't forget the demo", note2.?.getContent());
}

test "NoteParser no note" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const parser = NoteParser.init(allocator);

    const content = "# Slide Title\n\nSome content";
    const note = try parser.parseSlideNotes(content);
    try testing.expect(note == null);
}

test "NoteParser multiline note" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const parser = NoteParser.init(allocator);

    const content =
        \\<!-- note
        \\Line 1 of notes
        \\Line 2 of notes
        \\<!-- endnote -->
    ;

    const note = try parser.parseSlideNotes(content);
    defer if (note) |n| n.deinit(allocator);
    try testing.expect(note != null);
    try testing.expect(std.mem.containsAtLeast(u8, note.?.getContent(), 1, "Line 1"));
    try testing.expect(std.mem.containsAtLeast(u8, note.?.getContent(), 1, "Line 2"));
}
