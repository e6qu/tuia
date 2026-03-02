//! YAML front matter parser for markdown files
const std = @import("std");

/// FrontMatter represents YAML metadata at the start of a markdown file
pub const FrontMatter = struct {
    title: ?[]const u8 = null,
    author: ?[]const u8 = null,
    date: ?[]const u8 = null,
    theme: ?[]const u8 = null,

    const Self = @This();

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        if (self.title) |t| allocator.free(t);
        if (self.author) |a| allocator.free(a);
        if (self.date) |d| allocator.free(d);
        if (self.theme) |th| allocator.free(th);
    }
};

/// Parse YAML front matter from markdown source
/// Front matter is delimited by --- at the start and end
pub fn parse(allocator: std.mem.Allocator, source: []const u8) !?FrontMatter {
    // Check if source starts with ---
    if (!std.mem.startsWith(u8, source, "---")) {
        return null;
    }

    // Find the end of front matter (second ---)
    const after_first_delim = source[3..]; // Skip first ---
    const end_pos = std.mem.indexOf(u8, after_first_delim, "---");

    if (end_pos == null) {
        return null; // No closing delimiter
    }

    const yaml_content = after_first_delim[0..end_pos.?];

    var front_matter = FrontMatter{};
    errdefer front_matter.deinit(allocator);

    // Parse each line as key: value
    var lines = std.mem.splitScalar(u8, yaml_content, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len == 0) continue;
        if (std.mem.startsWith(u8, trimmed, "#")) continue; // Skip comments

        // Find colon separator
        const colon_pos = std.mem.indexOf(u8, trimmed, ":");
        if (colon_pos == null) continue;

        const key = std.mem.trim(u8, trimmed[0..colon_pos.?], " \t");
        var value = std.mem.trim(u8, trimmed[colon_pos.? + 1 ..], " \t");

        // Remove quotes if present
        if (value.len >= 2 and
            ((value[0] == '"' and value[value.len - 1] == '"') or
                (value[0] == '\'' and value[value.len - 1] == '\'')))
        {
            value = value[1 .. value.len - 1];
        }

        // Store value based on key
        if (std.mem.eql(u8, key, "title")) {
            front_matter.title = try allocator.dupe(u8, value);
        } else if (std.mem.eql(u8, key, "author")) {
            front_matter.author = try allocator.dupe(u8, value);
        } else if (std.mem.eql(u8, key, "date")) {
            front_matter.date = try allocator.dupe(u8, value);
        } else if (std.mem.eql(u8, key, "theme")) {
            front_matter.theme = try allocator.dupe(u8, value);
        }
    }

    return front_matter;
}

/// Parse front matter and return remaining content after front matter
pub fn parseWithContent(allocator: std.mem.Allocator, source: []const u8) !struct { front_matter: ?FrontMatter, content: []const u8 } {
    // Check if source starts with ---
    if (!std.mem.startsWith(u8, source, "---")) {
        return .{ .front_matter = null, .content = source };
    }

    // Find the end of front matter (second ---)
    const after_first_delim = source[3..]; // Skip first ---
    const end_pos = std.mem.indexOf(u8, after_first_delim, "---");

    if (end_pos == null) {
        return .{ .front_matter = null, .content = source };
    }

    const content_start = 3 + end_pos.? + 3; // First --- + content + second ---
    const remaining_content = if (content_start < source.len)
        source[content_start..]
    else
        "";

    const fm = try parse(allocator, source);

    return .{
        .front_matter = fm,
        .content = remaining_content,
    };
}

test "parse simple front matter" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source = "---\ntitle: My Presentation\nauthor: John Doe\ndate: 2024-01-15\ntheme: dark\n---\n# Slide 1";

    const result = try parse(allocator, source);
    try testing.expect(result != null);

    const fm = result.?;
    defer fm.deinit(allocator);

    try testing.expectEqualStrings("My Presentation", fm.title.?);
    try testing.expectEqualStrings("John Doe", fm.author.?);
    try testing.expectEqualStrings("2024-01-15", fm.date.?);
    try testing.expectEqualStrings("dark", fm.theme.?);
}

test "parse front matter with quotes" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source = "---\ntitle: \"My Title\"\nauthor: 'Jane Doe'\n---\nContent here";

    const result = try parse(allocator, source);
    try testing.expect(result != null);

    const fm = result.?;
    defer fm.deinit(allocator);

    try testing.expectEqualStrings("My Title", fm.title.?);
    try testing.expectEqualStrings("Jane Doe", fm.author.?);
}

test "no front matter" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source = "# Just a regular markdown file";

    const result = try parse(allocator, source);
    try testing.expect(result == null);
}

test "parseWithContent" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source = "---\ntitle: Test\n---\n# First Slide\nContent here";

    const result = try parseWithContent(allocator, source);
    defer if (result.front_matter) |fm| fm.deinit(allocator);

    try testing.expect(result.front_matter != null);
    try testing.expectEqualStrings("Test", result.front_matter.?.title.?);
    try testing.expect(std.mem.containsAtLeast(u8, result.content, 1, "# First Slide"));
}
