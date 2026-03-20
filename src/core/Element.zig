const std = @import("std");

/// Inline represents inline text formatting
pub const Inline = union(enum) {
    text: []const u8,
    bold: []Inline,
    italic: []Inline,
    strikethrough: []Inline,
    code: []const u8,
    link: Link,
    image: Image,

    pub fn deinit(self: Inline, allocator: std.mem.Allocator) void {
        switch (self) {
            .text => |t| allocator.free(t),
            .bold => |b| {
                for (b) |*item| item.deinit(allocator);
                allocator.free(b);
            },
            .italic => |i| {
                for (i) |*item| item.deinit(allocator);
                allocator.free(i);
            },
            .strikethrough => |st| {
                for (st) |*item| item.deinit(allocator);
                allocator.free(st);
            },
            .code => |c| allocator.free(c),
            .link => |l| {
                for (l.content) |*item| item.deinit(allocator);
                allocator.free(l.content);
                allocator.free(l.url);
            },
            .image => |img| {
                allocator.free(img.alt);
                allocator.free(img.url);
            },
        }
    }
};

/// Extract the first text content from inline elements (non-allocating)
/// Returns the first .text found, or null if none exists
pub fn extractFirstText(inlines: []const Inline) ?[]const u8 {
    for (inlines) |inline_elem| {
        switch (inline_elem) {
            .text => |t| return t,
            .bold => |b| if (extractFirstText(b)) |t| return t,
            .italic => |i| if (extractFirstText(i)) |t| return t,
            .strikethrough => |st| if (extractFirstText(st)) |t| return t,
            .link => |l| if (extractFirstText(l.content)) |t| return t,
            else => {},
        }
    }
    return null;
}

/// Convert inline content to plain text (allocating)
/// Concatenates all text content from inline elements
pub fn inlineToPlainText(allocator: std.mem.Allocator, inlines: []const Inline) ![]const u8 {
    var result: std.ArrayList(u8) = .empty;
    errdefer result.deinit(allocator);

    for (inlines) |inline_elem| {
        switch (inline_elem) {
            .text => |t| try result.appendSlice(allocator, t),
            .code => |c| try result.appendSlice(allocator, c),
            .bold => |b| {
                const text = try inlineToPlainText(allocator, b);
                defer allocator.free(text);
                try result.appendSlice(allocator, text);
            },
            .italic => |i| {
                const text = try inlineToPlainText(allocator, i);
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

/// Link inline element
pub const Link = struct {
    content: []Inline,
    url: []const u8,
};

/// Element represents a block-level element in a slide
pub const Element = union(enum) {
    heading: Heading,
    paragraph: Paragraph,
    code_block: CodeBlock,
    list: List,
    blockquote: Blockquote,
    image: Image,
    table: Table,
    media: Media,
    thematic_break,

    pub fn deinit(self: Element, allocator: std.mem.Allocator) void {
        switch (self) {
            .heading => |h| h.deinit(allocator),
            .paragraph => |p| p.deinit(allocator),
            .code_block => |cb| cb.deinit(allocator),
            .list => |l| l.deinit(allocator),
            .blockquote => |bq| bq.deinit(allocator),
            .image => |img| img.deinit(allocator),
            .table => |t| t.deinit(allocator),
            .media => |m| m.deinit(allocator),
            else => {},
        }
    }
};

pub const Heading = struct {
    level: u8,
    content: []Inline, // Styled inline content

    pub fn deinit(self: Heading, allocator: std.mem.Allocator) void {
        for (self.content) |*item| item.deinit(allocator);
        allocator.free(self.content);
    }
};

pub const Paragraph = struct {
    content: []Inline, // Styled inline content

    pub fn deinit(self: Paragraph, allocator: std.mem.Allocator) void {
        for (self.content) |*item| item.deinit(allocator);
        allocator.free(self.content);
    }
};

pub const CodeBlock = struct {
    language: ?[]const u8,
    code: []const u8,

    pub fn deinit(self: CodeBlock, allocator: std.mem.Allocator) void {
        if (self.language) |l| allocator.free(l);
        allocator.free(self.code);
    }
};

pub const List = struct {
    ordered: bool,
    items: []ListItem,

    pub fn deinit(self: List, allocator: std.mem.Allocator) void {
        for (self.items) |item| {
            item.deinit(allocator);
        }
        allocator.free(self.items);
    }
};

pub const ListItem = struct {
    content: []Inline, // Styled inline content
    children: ?*List, // Nested list (if any)

    pub fn deinit(self: ListItem, allocator: std.mem.Allocator) void {
        for (self.content) |*item| item.deinit(allocator);
        allocator.free(self.content);
        if (self.children) |child_list| {
            child_list.deinit(allocator);
            allocator.destroy(child_list);
        }
    }
};

pub const Blockquote = struct {
    content: []Inline, // Styled inline content

    pub fn deinit(self: Blockquote, allocator: std.mem.Allocator) void {
        for (self.content) |*item| item.deinit(allocator);
        allocator.free(self.content);
    }
};

pub const Image = struct {
    alt: []const u8,
    url: []const u8,

    pub fn deinit(self: Image, allocator: std.mem.Allocator) void {
        allocator.free(self.alt);
        allocator.free(self.url);
    }
};

pub const Table = struct {
    headers: []TableCell,
    rows: [][]TableCell,
    alignments: []Alignment,

    pub const Alignment = enum {
        left,
        center,
        right,
        default,
    };

    pub const TableCell = struct {
        content: []Inline,

        pub fn deinit(self: TableCell, allocator: std.mem.Allocator) void {
            for (self.content) |*item| item.deinit(allocator);
            allocator.free(self.content);
        }
    };

    pub fn deinit(self: Table, allocator: std.mem.Allocator) void {
        for (self.headers) |h| h.deinit(allocator);
        allocator.free(self.headers);

        for (self.rows) |row| {
            for (row) |cell| {
                cell.deinit(allocator);
            }
            allocator.free(row);
        }
        allocator.free(self.rows);

        allocator.free(self.alignments);
    }
};

/// Media element for audio/video
pub const Media = struct {
    /// File path or URL
    url: []const u8,
    /// Media type
    media_type: MediaType,
    /// Display title/caption
    title: ?[]const u8,
    /// Auto-play on slide load
    autoplay: bool,
    /// Loop playback
    loop: bool,
    /// Show controls
    controls: bool,

    pub const MediaType = enum {
        audio,
        video,
    };

    pub fn deinit(self: Media, allocator: std.mem.Allocator) void {
        allocator.free(self.url);
        if (self.title) |t| allocator.free(t);
    }
};

// Tests
test "Element deinit" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const content = try allocator.alloc(Inline, 1);
    content[0] = .{ .text = try allocator.dupe(u8, "Title") };

    const heading = Element{
        .heading = .{
            .level = 1,
            .content = content,
        },
    };
    heading.deinit(allocator);
}
