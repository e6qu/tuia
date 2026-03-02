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
        // Get the opening line (e.g., "```zig" or "```")
        const open_line = self.current.text;
        self.advance();

        // Extract language from opening line (e.g., "```zig" -> "zig")
        const language = extractLanguage(open_line, self.allocator);
        errdefer if (language) |l| self.allocator.free(l);

        // Collect code content until closing ```
        var code_lines: std.ArrayList(u8) = .empty;
        defer code_lines.deinit(self.allocator);

        while (self.current.type != .eof and
            self.current.type != .end_slide and
            !isCodeBlockEnd(self.current.text))
        {
            // Append the line text
            try code_lines.appendSlice(self.allocator, self.current.text);
            try code_lines.append(self.allocator, '\n');
            self.advance();
        }

        // Skip the closing ``` if present
        if (isCodeBlockEnd(self.current.text)) {
            self.advance();
        }

        // Remove trailing newline
        const code = try code_lines.toOwnedSlice(self.allocator);
        const trimmed_code = if (code.len > 0 and code[code.len - 1] == '\n')
            try self.allocator.dupe(u8, code[0 .. code.len - 1])
        else
            code;
        if (trimmed_code.ptr != code.ptr) {
            self.allocator.free(code);
        }

        return .{ .code_block = .{
            .language = language,
            .code = trimmed_code,
        } };
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
                // Parse inline formatting within the text
                const inlines = try parseInlineContent(self.allocator, text);
                try content.appendSlice(self.allocator, inlines);
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

/// Extract language identifier from code block opener (e.g., "```zig" -> "zig")
fn extractLanguage(text: []const u8, allocator: std.mem.Allocator) ?[]const u8 {
    // Find the first backtick
    var i: usize = 0;
    while (i < text.len and text[i] != '`') {
        i += 1;
    }
    // Skip the backticks
    while (i < text.len and text[i] == '`') {
        i += 1;
    }
    // Skip whitespace
    while (i < text.len and (text[i] == ' ' or text[i] == '\t')) {
        i += 1;
    }
    // Collect language identifier
    const start = i;
    while (i < text.len and text[i] != ' ' and text[i] != '\t' and text[i] != '\n' and text[i] != '`') {
        i += 1;
    }
    if (i > start) {
        return allocator.dupe(u8, text[start..i]) catch null;
    }
    return null;
}

/// Check if a line is a code block end marker (```)
fn isCodeBlockEnd(text: []const u8) bool {
    var i: usize = 0;
    // Skip leading whitespace
    while (i < text.len and (text[i] == ' ' or text[i] == '\t')) {
        i += 1;
    }
    // Check for exactly 3 backticks
    if (i + 3 > text.len) return false;
    if (text[i] != '`' or text[i + 1] != '`' or text[i + 2] != '`') return false;
    // Make sure there's nothing else significant on the line
    i += 3;
    while (i < text.len) {
        if (text[i] == '\n' or text[i] == '\r') return true;
        if (text[i] != ' ' and text[i] != '\t') return false;
        i += 1;
    }
    return true;
}

/// Parse inline markdown content (bold, italic, code, links)
fn parseInlineContent(allocator: std.mem.Allocator, text: []const u8) ![]AST.Inline {
    var result: std.ArrayList(AST.Inline) = .empty;
    defer result.deinit(allocator);

    var i: usize = 0;
    var text_start: usize = 0;

    while (i < text.len) {
        // Check for inline code: `code`
        if (text[i] == '`') {
            // Flush pending text
            if (i > text_start) {
                const txt = try allocator.dupe(u8, text[text_start..i]);
                try result.append(allocator, .{ .text = txt });
            }

            // Find closing backtick
            i += 1;
            const code_start = i;
            while (i < text.len and text[i] != '`') {
                i += 1;
            }
            const code = try allocator.dupe(u8, text[code_start..i]);
            try result.append(allocator, .{ .code = code });

            if (i < text.len) i += 1; // skip closing `
            text_start = i;
            continue;
        }

        // Check for strong: **text**
        if (text[i] == '*' and i + 1 < text.len and text[i + 1] == '*') {
            // Flush pending text
            if (i > text_start) {
                const txt = try allocator.dupe(u8, text[text_start..i]);
                try result.append(allocator, .{ .text = txt });
            }

            // Find closing **
            i += 2;
            const strong_start = i;
            while (i + 1 < text.len and !(text[i] == '*' and text[i + 1] == '*')) {
                i += 1;
            }

            if (i + 1 < text.len) {
                // Parse content recursively
                const inner = try parseInlineContent(allocator, text[strong_start..i]);
                try result.append(allocator, .{ .strong = inner });
                i += 2; // skip closing **
            } else {
                // No closing **, treat as text
                const txt = try allocator.dupe(u8, text[strong_start - 2..i]);
                try result.append(allocator, .{ .text = txt });
            }
            text_start = i;
            continue;
        }

        // Check for emphasis: *text*
        if (text[i] == '*') {
            // Flush pending text
            if (i > text_start) {
                const txt = try allocator.dupe(u8, text[text_start..i]);
                try result.append(allocator, .{ .text = txt });
            }

            // Find closing *
            i += 1;
            const emph_start = i;
            while (i < text.len and text[i] != '*') {
                i += 1;
            }

            if (i < text.len) {
                // Parse content recursively
                const inner = try parseInlineContent(allocator, text[emph_start..i]);
                try result.append(allocator, .{ .emphasis = inner });
                i += 1; // skip closing *
            } else {
                // No closing *, treat as text
                const txt = try allocator.dupe(u8, text[emph_start - 1..i]);
                try result.append(allocator, .{ .text = txt });
            }
            text_start = i;
            continue;
        }

        // Check for links: [text](url)
        if (text[i] == '[') {
            // Find closing ]
            var j = i + 1;
            while (j < text.len and text[j] != ']') {
                j += 1;
            }

            // Check for ( following ]
            if (j + 1 < text.len and text[j] == ']' and text[j + 1] == '(') {
                // Flush pending text
                if (i > text_start) {
                    const txt = try allocator.dupe(u8, text[text_start..i]);
                    try result.append(allocator, .{ .text = txt });
                }

                const link_text = text[i + 1 .. j];
                j += 2; // skip ](

                // Find closing )
                const url_start = j;
                while (j < text.len and text[j] != ')') {
                    j += 1;
                }
                const url = try allocator.dupe(u8, text[url_start..j]);
                errdefer allocator.free(url);

                // Parse link text
                const inner = try parseInlineContent(allocator, link_text);
                errdefer {
                    for (inner) |*inl| {
                        inl.deinit(allocator);
                    }
                    allocator.free(inner);
                }

                try result.append(allocator, .{ .link = .{
                    .text = inner,
                    .url = url,
                } });

                if (j < text.len) j += 1; // skip )
                i = j;
                text_start = i;
                continue;
            }
        }

        // Check for images: ![alt](url)
        if (text[i] == '!' and i + 1 < text.len and text[i + 1] == '[') {
            // Find closing ]
            var j = i + 2;
            while (j < text.len and text[j] != ']') {
                j += 1;
            }

            // Check for ( following ]
            if (j + 1 < text.len and text[j] == ']' and text[j + 1] == '(') {
                // Flush pending text
                if (i > text_start) {
                    const txt = try allocator.dupe(u8, text[text_start..i]);
                    try result.append(allocator, .{ .text = txt });
                }

                const alt_text = text[i + 2 .. j];
                j += 2; // skip ](

                // Find closing )
                const url_start = j;
                while (j < text.len and text[j] != ')') {
                    j += 1;
                }
                const url = try allocator.dupe(u8, text[url_start..j]);
                errdefer allocator.free(url);

                const alt = try allocator.dupe(u8, alt_text);
                errdefer allocator.free(alt);

                try result.append(allocator, .{ .image = .{
                    .alt = alt,
                    .url = url,
                } });

                if (j < text.len) j += 1; // skip )
                i = j;
                text_start = i;
                continue;
            }
        }

        i += 1;
    }

    // Flush remaining text
    if (text_start < text.len) {
        const txt = try allocator.dupe(u8, text[text_start..]);
        try result.append(allocator, .{ .text = txt });
    }

    return try result.toOwnedSlice(allocator);
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

test "Parser code block with language" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source =
        \\# Code Example
        \\```zig
        \\const x = 42;
        \\print(x);
        \\```
        \\<!-- end_slide -->
    ;

    var parser = Parser.init(allocator, source);
    var presentation = try parser.parse();
    defer presentation.deinit();

    try testing.expectEqual(@as(usize, 1), presentation.slides.len);
    try testing.expectEqual(@as(usize, 2), presentation.slides[0].elements.len);

    // Check that the second element is a code block
    const code_block = presentation.slides[0].elements[1].code_block;
    try testing.expectEqualStrings("zig", code_block.language.?);
    try testing.expectEqualStrings("const x = 42;\nprint(x);", code_block.code);
}

test "Parser code block without language" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source =
        \\# Example
        \\```
        \\plain text
        \\more text
        \\```
    ;

    var parser = Parser.init(allocator, source);
    var presentation = try parser.parse();
    defer presentation.deinit();

    try testing.expectEqual(@as(usize, 1), presentation.slides.len);

    const code_block = presentation.slides[0].elements[1].code_block;
    try testing.expect(code_block.language == null);
    try testing.expectEqualStrings("plain text\nmore text", code_block.code);
}

test "extractLanguage helper" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // With language
    if (extractLanguage("```zig", allocator)) |lang| {
        defer allocator.free(lang);
        try testing.expectEqualStrings("zig", lang);
    } else {
        try testing.fail();
    }

    // With language and trailing spaces
    if (extractLanguage("```python  ", allocator)) |lang| {
        defer allocator.free(lang);
        try testing.expectEqualStrings("python", lang);
    } else {
        try testing.fail();
    }

    // Without language
    try testing.expect(extractLanguage("```", allocator) == null);

    // With leading spaces
    if (extractLanguage("  ```rust", allocator)) |lang| {
        defer allocator.free(lang);
        try testing.expectEqualStrings("rust", lang);
    } else {
        try testing.fail();
    }
}

test "isCodeBlockEnd helper" {
    const testing = std.testing;

    try testing.expect(isCodeBlockEnd("```"));
    try testing.expect(isCodeBlockEnd("```\n"));
    try testing.expect(isCodeBlockEnd("  ```"));
    try testing.expect(isCodeBlockEnd("```  "));
    try testing.expect(!isCodeBlockEnd("```zig"));
    try testing.expect(!isCodeBlockEnd("text"));
    try testing.expect(!isCodeBlockEnd(" ``"));
}

test "parseInlineContent bold" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const result = try parseInlineContent(allocator, "**bold text**");
    defer {
        for (result) |*r| {
            r.deinit(allocator);
        }
        allocator.free(result);
    }

    try testing.expectEqual(@as(usize, 1), result.len);
    try testing.expectEqualStrings("bold text", result[0].strong[0].text);
}

test "parseInlineContent italic" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const result = try parseInlineContent(allocator, "*italic text*");
    defer {
        for (result) |*r| {
            r.deinit(allocator);
        }
        allocator.free(result);
    }

    try testing.expectEqual(@as(usize, 1), result.len);
    try testing.expectEqualStrings("italic text", result[0].emphasis[0].text);
}

test "parseInlineContent inline code" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const result = try parseInlineContent(allocator, "`code here`");
    defer {
        for (result) |*r| {
            r.deinit(allocator);
        }
        allocator.free(result);
    }

    try testing.expectEqual(@as(usize, 1), result.len);
    try testing.expectEqualStrings("code here", result[0].code);
}

test "parseInlineContent link" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const result = try parseInlineContent(allocator, "[click here](https://example.com)");
    defer {
        for (result) |*r| {
            r.deinit(allocator);
        }
        allocator.free(result);
    }

    try testing.expectEqual(@as(usize, 1), result.len);
    try testing.expectEqualStrings("click here", result[0].link.text[0].text);
    try testing.expectEqualStrings("https://example.com", result[0].link.url);
}

test "parseInlineContent image" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const result = try parseInlineContent(allocator, "![alt text](image.png)");
    defer {
        for (result) |*r| {
            r.deinit(allocator);
        }
        allocator.free(result);
    }

    try testing.expectEqual(@as(usize, 1), result.len);
    try testing.expectEqualStrings("alt text", result[0].image.alt);
    try testing.expectEqualStrings("image.png", result[0].image.url);
}

test "parseInlineContent combined" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const result = try parseInlineContent(allocator, "Hello **bold** and *italic* world");
    defer {
        for (result) |*r| {
            r.deinit(allocator);
        }
        allocator.free(result);
    }

    try testing.expectEqual(@as(usize, 5), result.len);
    try testing.expectEqualStrings("Hello ", result[0].text);
    try testing.expectEqualStrings("bold", result[1].strong[0].text);
    try testing.expectEqualStrings(" and ", result[2].text);
    try testing.expectEqualStrings("italic", result[3].emphasis[0].text);
    try testing.expectEqualStrings(" world", result[4].text);
}
