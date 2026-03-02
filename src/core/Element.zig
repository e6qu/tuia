const std = @import("std");

/// Element represents a block-level element in a slide
pub const Element = union(enum) {
    heading: Heading,
    paragraph: Paragraph,
    code_block: CodeBlock,
    list: List,
    blockquote: Blockquote,
    image: Image,
    table: Table,
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
            else => {},
        }
    }
};

pub const Heading = struct {
    level: u8,
    text: []const u8,

    pub fn deinit(self: Heading, allocator: std.mem.Allocator) void {
        allocator.free(self.text);
    }
};

pub const Paragraph = struct {
    text: []const u8,

    pub fn deinit(self: Paragraph, allocator: std.mem.Allocator) void {
        allocator.free(self.text);
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
    text: []const u8,
    children: ?*List, // Nested list (if any)

    pub fn deinit(self: ListItem, allocator: std.mem.Allocator) void {
        allocator.free(self.text);
        if (self.children) |child_list| {
            child_list.deinit(allocator);
            allocator.destroy(child_list);
        }
    }
};

pub const Blockquote = struct {
    text: []const u8,

    pub fn deinit(self: Blockquote, allocator: std.mem.Allocator) void {
        allocator.free(self.text);
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
    headers: [][]const u8,
    rows: [][]TableCell,
    alignments: []Alignment,

    pub const Alignment = enum {
        left,
        center,
        right,
        default,
    };

    pub const TableCell = struct {
        text: []const u8,
    };

    pub fn deinit(self: Table, allocator: std.mem.Allocator) void {
        for (self.headers) |h| allocator.free(h);
        allocator.free(self.headers);

        for (self.rows) |row| {
            for (row) |cell| {
                allocator.free(cell.text);
            }
            allocator.free(row);
        }
        allocator.free(self.rows);

        allocator.free(self.alignments);
    }
};

// Tests
test "Element deinit" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const heading = Element{
        .heading = .{
            .level = 1,
            .text = try allocator.dupe(u8, "Title"),
        },
    };
    heading.deinit(allocator);
}
