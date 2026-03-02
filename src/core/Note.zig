//! Speaker note model
const std = @import("std");

/// Speaker note for a slide
pub const Note = struct {
    /// Note content (markdown)
    content: []const u8,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, content: []const u8) !Self {
        return .{
            .content = try allocator.dupe(u8, content),
        };
    }

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        allocator.free(self.content);
    }

    /// Get note content as a slice
    pub fn getContent(self: Self) []const u8 {
        return self.content;
    }

    /// Check if note is empty
    pub fn isEmpty(self: Self) bool {
        return self.content.len == 0;
    }
};

/// Collection of notes for a presentation
pub const NotesCollection = struct {
    /// Map from slide index to notes
    /// Using an ArrayList where index is slide index
    notes: std.ArrayList(?Note),

    const Self = @This();

    pub fn init(_: std.mem.Allocator) Self {
        return .{
            .notes = .empty,
        };
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        for (self.notes.items) |maybe_note| {
            if (maybe_note) |note| {
                note.deinit(allocator);
            }
        }
        self.notes.deinit(allocator);
    }

    /// Set notes for a specific slide
    pub fn setNote(self: *Self, allocator: std.mem.Allocator, slide_index: usize, content: []const u8) !void {
        // Ensure array is large enough
        while (self.notes.items.len <= slide_index) {
            try self.notes.append(allocator, null);
        }

        // Free existing note if any
        if (self.notes.items[slide_index]) |old_note| {
            old_note.deinit(allocator);
        }

        // Set new note
        self.notes.items[slide_index] = try Note.init(allocator, content);
    }

    /// Get notes for a specific slide
    pub fn getNote(self: Self, slide_index: usize) ?Note {
        if (slide_index >= self.notes.items.len) return null;
        return self.notes.items[slide_index];
    }

    /// Check if a slide has notes
    pub fn hasNote(self: Self, slide_index: usize) bool {
        if (slide_index >= self.notes.items.len) return false;
        return self.notes.items[slide_index] != null;
    }

    /// Get total number of slides with notes
    pub fn count(self: Self) usize {
        var result: usize = 0;
        for (self.notes.items) |maybe_note| {
            if (maybe_note != null) result += 1;
        }
        return result;
    }
};

test "Note basic operations" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const note = try Note.init(allocator, "This is a speaker note");
    defer note.deinit(allocator);

    try testing.expectEqualStrings("This is a speaker note", note.getContent());
    try testing.expect(!note.isEmpty());
}

test "NotesCollection" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var collection = NotesCollection.init(allocator);
    defer collection.deinit(allocator);

    // Add notes for slide 0
    try collection.setNote(allocator, 0, "First slide notes");
    try testing.expect(collection.hasNote(0));
    try testing.expectEqual(@as(usize, 1), collection.count());

    // Get note
    const note = collection.getNote(0).?;
    try testing.expectEqualStrings("First slide notes", note.getContent());

    // Slide 1 has no notes
    try testing.expect(!collection.hasNote(1));
    try testing.expect(collection.getNote(1) == null);

    // Add notes for slide 5 (sparse)
    try collection.setNote(allocator, 5, "Sixth slide notes");
    try testing.expect(collection.hasNote(5));
    try testing.expectEqual(@as(usize, 2), collection.count());

    // Update existing note
    try collection.setNote(allocator, 0, "Updated first slide notes");
    const updated = collection.getNote(0).?;
    try testing.expectEqualStrings("Updated first slide notes", updated.getContent());
}
