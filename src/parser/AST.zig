const std = @import("std");

/// AST types for parsed markdown
pub const Presentation = struct {
    allocator: std.mem.Allocator,
    metadata: ?FrontMatter,
    slides: []Slide,

    pub fn deinit(self: *Presentation) void {
        for (self.slides) |*slide| {
            slide.deinit(self.allocator);
        }
        self.allocator.free(self.slides);
        if (self.metadata) |*fm| {
            fm.deinit(self.allocator);
        }
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

    pub fn deinit(self: *Slide, allocator: std.mem.Allocator) void {
        for (self.elements) |*elem| {
            elem.deinit(allocator);
        }
        allocator.free(self.elements);
    }
};

pub const Element = union(enum) {
    heading: Heading,
    paragraph: Paragraph,
    code_block: CodeBlock,
    list: List,
    blockquote: Blockquote,
    thematic_break,

    pub fn deinit(self: *Element, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .heading => |*h| h.deinit(allocator),
            .paragraph => |*p| p.deinit(allocator),
            .code_block => |*cb| cb.deinit(allocator),
            .list => |*l| l.deinit(allocator),
            .blockquote => |*bq| bq.deinit(allocator),
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

    pub fn deinit(self: *ListItem, allocator: std.mem.Allocator) void {
        for (self.content) |*elem| {
            elem.deinit(allocator);
        }
        allocator.free(self.content);
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

    pub fn deinit(self: *Link, allocator: std.mem.Allocator) void {
        for (self.text) |*inline_elem| {
            inline_elem.deinit(allocator);
        }
        allocator.free(self.text);
        allocator.free(self.url);
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
