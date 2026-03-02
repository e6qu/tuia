const std = @import("std");

/// AST types for parsed markdown
pub const Presentation = struct {
    allocator: std.mem.Allocator,
    metadata: ?FrontMatter,
    slides: []Slide,
    link_references: std.StringHashMap([]const u8),

    pub fn deinit(self: *Presentation) void {
        for (self.slides) |*slide| {
            slide.deinit(self.allocator);
        }
        self.allocator.free(self.slides);
        if (self.metadata) |*fm| {
            fm.deinit(self.allocator);
        }
        // Free all link reference keys and values
        var it = self.link_references.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.*);
        }
        self.link_references.deinit();
    }
};

pub const FrontMatter = struct {
    title: ?[]const u8,
    author: ?[]const u8,
    date: ?[]const u8,
    theme: ?[]const u8,

    pub fn deinit(self: *FrontMatter, allocator: std.mem.Allocator) void {
        if (self.title) |t| allocator.free(t);
        if (self.author) |a| allocator.free(a);
        if (self.date) |d| allocator.free(d);
        if (self.theme) |th| allocator.free(th);
    }
};

pub const Slide = struct {
    elements: []Element,
    speaker_notes: ?[]const u8,

    pub fn deinit(self: *Slide, allocator: std.mem.Allocator) void {
        for (self.elements) |*elem| {
            elem.deinit(allocator);
        }
        allocator.free(self.elements);
        if (self.speaker_notes) |notes| {
            allocator.free(notes);
        }
    }
};

pub const Element = union(enum) {
    heading: Heading,
    paragraph: Paragraph,
    code_block: CodeBlock,
    list: List,
    blockquote: Blockquote,
    table: Table,
    thematic_break,

    pub fn deinit(self: *Element, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .heading => |*h| h.deinit(allocator),
            .paragraph => |*p| p.deinit(allocator),
            .code_block => |*cb| cb.deinit(allocator),
            .list => |*l| l.deinit(allocator),
            .blockquote => |*bq| bq.deinit(allocator),
            .table => |*t| t.deinit(allocator),
            else => {},
        }
    }
};

pub const Heading = struct {
    level: u8, // 1-6
    content: []Inline,

    pub fn deinit(self: *Heading, allocator: std.mem.Allocator) void {
        for (self.content) |*inline_elem| {
            inline_elem.deinit(allocator);
        }
        allocator.free(self.content);
    }
};

pub const Paragraph = struct {
    content: []Inline,

    pub fn deinit(self: *Paragraph, allocator: std.mem.Allocator) void {
        for (self.content) |*inline_elem| {
            inline_elem.deinit(allocator);
        }
        allocator.free(self.content);
    }
};

pub const CodeBlock = struct {
    language: ?[]const u8,
    code: []const u8,

    pub fn deinit(self: *CodeBlock, allocator: std.mem.Allocator) void {
        if (self.language) |l| allocator.free(l);
        allocator.free(self.code);
    }
};

pub const List = struct {
    ordered: bool,
    items: []ListItem,

    pub fn deinit(self: *List, allocator: std.mem.Allocator) void {
        for (self.items) |*item| {
            item.deinit(allocator);
        }
        allocator.free(self.items);
    }
};

pub const ListItem = struct {
    content: []Element,
    children: ?*List, // Nested list (if any)

    pub fn deinit(self: *ListItem, allocator: std.mem.Allocator) void {
        for (self.content) |*elem| {
            elem.deinit(allocator);
        }
        allocator.free(self.content);
        if (self.children) |child_list| {
            child_list.deinit(allocator);
            allocator.destroy(child_list);
        }
    }
};

pub const Blockquote = struct {
    content: []Element,

    pub fn deinit(self: *Blockquote, allocator: std.mem.Allocator) void {
        for (self.content) |*elem| {
            elem.deinit(allocator);
        }
        allocator.free(self.content);
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
        content: []Inline,

        pub fn deinit(self: TableCell, allocator: std.mem.Allocator) void {
            for (self.content) |*inline_elem| {
                inline_elem.deinit(allocator);
            }
            allocator.free(self.content);
        }
    };

    pub fn deinit(self: *Table, allocator: std.mem.Allocator) void {
        for (self.headers) |h| allocator.free(h);
        allocator.free(self.headers);

        for (self.rows) |row| {
            for (row) |*cell| {
                cell.deinit(allocator);
            }
            allocator.free(row);
        }
        allocator.free(self.rows);

        allocator.free(self.alignments);
    }
};

// Inline elements

pub const Inline = union(enum) {
    text: []const u8,
    emphasis: []Inline,
    strong: []Inline,
    code: []const u8,
    link: Link,
    image: Image,
    line_break,

    pub fn deinit(self: *Inline, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .text => |t| allocator.free(t),
            .emphasis => |*e| {
                for (e.*) |*inline_elem| {
                    inline_elem.deinit(allocator);
                }
                allocator.free(e.*);
            },
            .strong => |*s| {
                for (s.*) |*inline_elem| {
                    inline_elem.deinit(allocator);
                }
                allocator.free(s.*);
            },
            .code => |c| allocator.free(c),
            .link => |*l| l.deinit(allocator),
            .image => |*i| i.deinit(allocator),
            else => {},
        }
    }
};

pub const Link = struct {
    text: []Inline,
    url: []const u8,
    ref_label: ?[]const u8, // For reference-style links [text][label] or [text][]

    pub fn deinit(self: *Link, allocator: std.mem.Allocator) void {
        for (self.text) |*inline_elem| {
            inline_elem.deinit(allocator);
        }
        allocator.free(self.text);
        allocator.free(self.url);
        if (self.ref_label) |label| allocator.free(label);
    }
};

pub const Image = struct {
    alt: []const u8,
    url: []const u8,

    pub fn deinit(self: *Image, allocator: std.mem.Allocator) void {
        allocator.free(self.alt);
        allocator.free(self.url);
    }
};
