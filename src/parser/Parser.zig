const std = @import("std");
const Scanner = @import("Scanner.zig").Scanner;
const Token = @import("Token.zig").Token;
const AST = @import("AST.zig");

pub const ParseError = error{
    OutOfMemory,
    InvalidSyntax,
};

/// Parser builds an AST from markdown source
pub const Parser = struct {
    allocator: std.mem.Allocator,
    scanner: Scanner,
    current: Token,
    peeked: ?Token = null,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Self {
        var scanner = Scanner.init(source);
        const first_token = scanner.nextToken();
        return .{
            .allocator = allocator,
            .scanner = scanner,
            .current = first_token,
            .peeked = null,
        };
    }

    pub fn parse(self: *Self) !AST.Presentation {
        // Parse front matter if present
        const front_matter = try self.parseFrontMatter();

        // Parse slides
        var slides: std.ArrayList(AST.Slide) = .empty;
        defer slides.deinit(self.allocator);

        while (self.current.type != .eof) {
            const slide = try self.parseSlide();
            try slides.append(self.allocator, slide);
        }

        return .{
            .allocator = self.allocator,
            .metadata = front_matter,
            .slides = try slides.toOwnedSlice(self.allocator),
        };
    }

    fn parseFrontMatter(self: *Self) !?AST.FrontMatter {
        const FrontMatterParser = @import("FrontMatter.zig");
        
        // Get remaining source from current position
        const remaining_source = self.scanner.source[self.scanner.pos..];
        
        // Check if there's front matter
        if (!std.mem.startsWith(u8, remaining_source, "---")) {
            return null;
        }

        // Parse front matter and get remaining content
        const result = try FrontMatterParser.parseWithContent(self.allocator, remaining_source);
        
        // Advance scanner past the front matter
        const front_matter_end = std.mem.indexOf(u8, remaining_source[3..], "---");
        if (front_matter_end) |end| {
            // Skip past the second ---
            const skip_len = 3 + end + 3;
            for (0..skip_len) |_| {
                _ = self.scanner.nextToken();
            }
            // Update current token
            self.current = self.scanner.nextToken();
        }

        // Convert to AST.FrontMatter
        if (result.front_matter) |fm| {
            return AST.FrontMatter{
                .title = if (fm.title) |t| try self.allocator.dupe(u8, t) else null,
                .author = if (fm.author) |a| try self.allocator.dupe(u8, a) else null,
                .date = if (fm.date) |d| try self.allocator.dupe(u8, d) else null,
                .theme = if (fm.theme) |th| try self.allocator.dupe(u8, th) else null,
            };
        }

        return null;
    }

    fn parseSlide(self: *Self) !AST.Slide {
        var elements: std.ArrayList(AST.Element) = .empty;
        defer elements.deinit(self.allocator);

        while (self.current.type != .end_slide and self.current.type != .eof) {
            const elem = try self.parseBlockElement();
            if (elem) |e| {
                try elements.append(self.allocator, e);
            }
        }

        // Consume end_slide or eof
        if (self.current.type == .end_slide) {
            self.advance();
        }

        // Skip blank lines between slides
        while (self.current.type == .blank_line) {
            self.advance();
        }

        return .{
            .elements = try elements.toOwnedSlice(self.allocator),
        };
    }

    fn parseBlockElement(self: *Self) ParseError!?AST.Element {
        switch (self.current.type) {
            .heading => return try self.parseHeading(),
            .code_block => return try self.parseCodeBlock(),
            .blockquote => return try self.parseBlockquote(),
            .list_item => return try self.parseList(),
            .thematic_break => {
                self.advance();
                return .thematic_break;
            },
            .text, .paragraph => return try self.parseParagraph(),
            .blank_line => {
                self.advance();
                return null;
            },
            .end_slide, .eof => return null,
            else => {
                // Skip unknown tokens
                self.advance();
                return null;
            },
        }
    }

    fn parseHeading(self: *Self) !AST.Element {
        const text = self.current.text;
        const level = countHeadingLevel(text);
        self.advance();

        // Parse inline content
        const content = try self.parseInlineText();

        return .{ .heading = .{
            .level = level,
            .content = content,
        } };
    }

    fn parseParagraph(self: *Self) !AST.Element {
        const content = try self.parseInlineText();
        return .{ .paragraph = .{ .content = content } };
    }

    fn parseCodeBlock(self: *Self) !AST.Element {
        // For now, treat as paragraph (proper implementation later)
        self.advance();
        return .{ .paragraph = .{ .content = try self.parseInlineText() } };
    }

    fn parseBlockquote(self: *Self) ParseError!AST.Element {
        self.advance();
        var content: std.ArrayList(AST.Element) = .empty;
        defer content.deinit(self.allocator);

        while (self.current.type != .blank_line and self.current.type != .eof and self.current.type != .end_slide) {
            const elem = try self.parseBlockElement();
            if (elem) |e| {
                try content.append(self.allocator, e);
            }
        }

        return .{ .blockquote = .{ .content = try content.toOwnedSlice(self.allocator) } };
    }

    fn parseList(self: *Self) !AST.Element {
        var items: std.ArrayList(AST.ListItem) = .empty;
        defer items.deinit(self.allocator);

        // For now, just consume list items
        while (self.current.type == .list_item) {
            self.advance();
            var content: std.ArrayList(AST.Element) = .empty;
            defer content.deinit(self.allocator);

            // Parse until next list item or blank line
            while (self.current.type != .list_item and self.current.type != .blank_line and
                self.current.type != .eof and self.current.type != .end_slide)
            {
                const elem = try self.parseBlockElement();
                if (elem) |e| {
                    try content.append(self.allocator, e);
                }
            }

            try items.append(self.allocator, .{ .content = try content.toOwnedSlice(self.allocator) });
        }

        return .{ .list = .{
            .ordered = false,
            .items = try items.toOwnedSlice(self.allocator),
        } };
    }

    fn parseInlineText(self: *Self) ![]AST.Inline {
        var content: std.ArrayList(AST.Inline) = .empty;
        defer content.deinit(self.allocator);

        // For now, just create a single text node
        if (self.current.type == .text or self.current.type == .paragraph) {
            const text = std.mem.trim(u8, self.current.text, " \t\n");
            if (text.len > 0) {
                const copy = try self.allocator.dupe(u8, text);
                try content.append(self.allocator, .{ .text = copy });
            }
            self.advance();
        }

        return try content.toOwnedSlice(self.allocator);
    }

    fn advance(self: *Self) void {
        if (self.peeked) |token| {
            self.current = token;
            self.peeked = null;
        } else {
            self.current = self.scanner.nextToken();
        }
    }

    fn peek(self: *Self) Token {
        if (self.peeked == null) {
            self.peeked = self.scanner.nextToken();
        }
        return self.peeked.?;
    }
};

fn countHeadingLevel(text: []const u8) u8 {
    var count: u8 = 0;
    for (text) |c| {
        if (c == '#') count += 1 else break;
    }
    return @min(count, 6);
}

// Tests
test "Parser basic slide" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source = "# Title\n\nSome text\n\n<!-- end_slide -->";
    var parser = Parser.init(allocator, source);
    var presentation = try parser.parse();
    defer presentation.deinit();

    try testing.expectEqual(@as(usize, 1), presentation.slides.len);
    try testing.expectEqual(@as(usize, 2), presentation.slides[0].elements.len);
}

test "Parser multiple slides" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source =
        \\# Slide 1
        \\Content 1
        \\<!-- end_slide -->
        \\# Slide 2
        \\Content 2
    ;

    var parser = Parser.init(allocator, source);
    var presentation = try parser.parse();
    defer presentation.deinit();

    try testing.expectEqual(@as(usize, 2), presentation.slides.len);
}
