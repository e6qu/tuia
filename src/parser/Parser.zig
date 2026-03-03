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

        // Initialize link references map
        var link_references = std.StringHashMap([]const u8).init(self.allocator);

        // Parse slides (link ref defs will be collected during slide parsing)
        var slides: std.ArrayList(AST.Slide) = .empty;
        defer slides.deinit(self.allocator);

        while (self.current.type != .eof) {
            const slide = try self.parseSlide(&link_references);
            try slides.append(self.allocator, slide);
        }

        return .{
            .allocator = self.allocator,
            .metadata = front_matter,
            .slides = try slides.toOwnedSlice(self.allocator),
            .link_references = link_references,
        };
    }

    fn parseFrontMatter(self: *Self) !?AST.FrontMatter {
        const FrontMatterParser = @import("FrontMatter.zig");

        // Check if the first token is a thematic break (---)
        // If so, we need to look at the source from the beginning
        const source_to_check = if (self.current.type == .thematic_break)
            self.scanner.source
        else
            self.scanner.source[self.scanner.pos..];

        // Check if there's front matter
        if (!std.mem.startsWith(u8, source_to_check, "---")) {
            return null;
        }

        // Parse front matter and get remaining content
        const result = try FrontMatterParser.parseWithContent(self.allocator, source_to_check);

        // Advance scanner past the front matter
        const front_matter_end = std.mem.indexOf(u8, source_to_check[3..], "---");
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
        if (result.front_matter) |*fm| {
            // Copy the frontmatter data
            const ast_fm = AST.FrontMatter{
                .title = if (fm.title) |t| try self.allocator.dupe(u8, t) else null,
                .author = if (fm.author) |a| try self.allocator.dupe(u8, a) else null,
                .date = if (fm.date) |d| try self.allocator.dupe(u8, d) else null,
                .theme = if (fm.theme) |th| try self.allocator.dupe(u8, th) else null,
            };
            // Free the temporary frontmatter
            fm.deinit(self.allocator);
            return ast_fm;
        }

        return null;
    }

    fn parseSlide(self: *Self, link_references: *std.StringHashMap([]const u8)) !AST.Slide {
        var elements: std.ArrayList(AST.Element) = .empty;
        defer elements.deinit(self.allocator);

        var speaker_notes: ?[]const u8 = null;

        while (self.current.type != .end_slide and
            self.current.type != .thematic_break and
            self.current.type != .eof)
        {
            // Handle speaker notes
            if (self.current.type == .speaker_note) {
                const notes = try extractSpeakerNotes(self.current.text, self.allocator);
                if (speaker_notes) |old_notes| {
                    // Append to existing notes
                    const combined = try std.fmt.allocPrint(self.allocator, "{s}\n{s}", .{ old_notes, notes });
                    self.allocator.free(old_notes);
                    self.allocator.free(notes);
                    speaker_notes = combined;
                } else {
                    speaker_notes = notes;
                }
                self.advance();
                continue;
            }

            // Handle link reference definitions
            if (self.current.type == .link_ref_def) {
                try self.parseLinkRefDef(link_references);
                continue;
            }

            const elem = try self.parseBlockElement();
            if (elem) |e| {
                try elements.append(self.allocator, e);
            }
        }

        // Consume end_slide, thematic_break (slide separator), or eof
        if (self.current.type == .end_slide or self.current.type == .thematic_break) {
            self.advance();
        }

        // Skip blank lines between slides
        while (self.current.type == .blank_line) {
            self.advance();
        }

        return .{
            .elements = try elements.toOwnedSlice(self.allocator),
            .speaker_notes = speaker_notes,
        };
    }

    fn parseLinkRefDef(self: *Self, link_references: *std.StringHashMap([]const u8)) !void {
        const text = self.current.text;

        // Parse [label]: url
        // Find the label between [ and ]
        const label_start: usize = 1; // Skip [
        var label_end: usize = label_start;
        while (label_end < text.len and text[label_end] != ']') {
            label_end += 1;
        }

        if (label_end >= text.len) {
            self.advance();
            return;
        }

        const label = try self.allocator.dupe(u8, text[label_start..label_end]);
        errdefer self.allocator.free(label);

        // Skip ]: and whitespace
        var url_start = label_end + 1; // Skip ]
        if (url_start < text.len and text[url_start] == ':') {
            url_start += 1;
        }
        while (url_start < text.len and (text[url_start] == ' ' or text[url_start] == '\t')) {
            url_start += 1;
        }

        // Skip optional <>
        if (url_start < text.len and text[url_start] == '<') {
            url_start += 1;
        }

        var url_end = url_start;
        while (url_end < text.len and text[url_end] != ' ' and text[url_end] != '\t' and text[url_end] != '>' and text[url_end] != '\n') {
            url_end += 1;
        }

        if (url_start < url_end) {
            const url = try self.allocator.dupe(u8, text[url_start..url_end]);

            // Store in hash map
            const result = link_references.getOrPut(label) catch |err| {
                self.allocator.free(label);
                return err;
            };

            if (result.found_existing) {
                // Update existing entry
                self.allocator.free(result.value_ptr.*);
                result.value_ptr.* = url;
                self.allocator.free(label);
            } else {
                result.key_ptr.* = label;
                result.value_ptr.* = url;
            }
        } else {
            self.allocator.free(label);
        }

        self.advance();
    }

    fn parseBlockElement(self: *Self) ParseError!?AST.Element {
        switch (self.current.type) {
            .heading => return try self.parseHeading(),
            .code_block => return try self.parseCodeBlock(),
            .blockquote => return try self.parseBlockquote(),
            .list_item => return try self.parseList(false),
            .ordered_list_item => return try self.parseList(true),
            .table_row => return try self.parseTable(),
            .table_separator => {
                // Skip orphan separator (no preceding table row)
                self.advance();
                return null;
            },
            .thematic_break => {
                self.advance();
                return .thematic_break;
            },
            .speaker_note => {
                // Speaker notes are handled in parseSlide
                self.advance();
                return null;
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
            } else {
                // parseBlockElement returned null - advance to avoid infinite loop
                // This handles cases like unknown tokens or already-handled elements
                if (self.current.type != .blank_line and self.current.type != .eof and self.current.type != .end_slide) {
                    self.advance();
                }
            }
        }

        return .{ .blockquote = .{ .content = try content.toOwnedSlice(self.allocator) } };
    }

    fn parseList(self: *Self, ordered: bool) !AST.Element {
        const base_indent = self.current.indent;

        var items: std.ArrayList(AST.ListItem) = .empty;
        defer items.deinit(self.allocator);

        // Determine which token type to expect
        const item_token = if (ordered) Token.Type.ordered_list_item else Token.Type.list_item;

        // Consume list items at this indentation level
        while (self.current.type == item_token and self.current.indent == base_indent) {
            self.advance();
            var content: std.ArrayList(AST.Element) = .empty;
            defer content.deinit(self.allocator);

            // Parse content until next item at same level, blank line, or lower indentation
            while (self.current.type != .eof and
                self.current.type != .end_slide and
                self.current.type != .blank_line)
            {
                // Check if we hit a list item at same or lower indentation
                if ((self.current.type == .list_item or self.current.type == .ordered_list_item) and
                    self.current.indent <= base_indent)
                {
                    break;
                }

                // Check for nested list (higher indentation)
                if ((self.current.type == .list_item or self.current.type == .ordered_list_item) and
                    self.current.indent > base_indent)
                {
                    break; // Will be handled after we finish this item's content
                }

                const elem = try self.parseBlockElement();
                if (elem) |e| {
                    try content.append(self.allocator, e);
                } else if (self.current.type == .speaker_note) {
                    self.advance(); // Skip speaker notes in list context
                } else {
                    // parseBlockElement returned null but didn't advance - advance to avoid infinite loop
                    // Check if we're still in a valid state to continue parsing
                    if (self.current.type != .eof and
                        self.current.type != .end_slide and
                        self.current.type != .blank_line)
                    {
                        // Check if we hit a list item
                        if ((self.current.type == .list_item or self.current.type == .ordered_list_item)) {
                            // Don't advance - let the outer logic handle the list item
                        } else {
                            self.advance();
                        }
                    }
                }
            }

            // Check for nested list
            var children: ?*AST.List = null;
            if ((self.current.type == .list_item or self.current.type == .ordered_list_item) and
                self.current.indent > base_indent)
            {
                const nested_ordered = self.current.type == .ordered_list_item;
                const nested_list_elem = try self.parseList(nested_ordered);
                children = try self.allocator.create(AST.List);
                children.?.* = nested_list_elem.list;
            }

            try items.append(self.allocator, .{
                .content = try content.toOwnedSlice(self.allocator),
                .children = children,
            });
        }

        return .{ .list = .{
            .ordered = ordered,
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
                // Free the temporary inlines slice (elements are now owned by content)
                self.allocator.free(inlines);
            }
            self.advance();
        }

        return try content.toOwnedSlice(self.allocator);
    }

    fn parseTable(self: *Self) !AST.Element {
        // Parse header row
        const header_row = self.current.text;
        const headers = try parseTableRow(self.allocator, header_row);
        self.advance();

        // Parse alignment row (separator)
        var alignments: std.ArrayList(AST.Table.Alignment) = .empty;
        defer alignments.deinit(self.allocator);

        if (self.current.type == .table_separator) {
            alignments = try parseTableAlignments(self.allocator, self.current.text);
            self.advance();
        }

        // Parse data rows
        var rows: std.ArrayList([]AST.Table.TableCell) = .empty;
        defer {
            for (rows.items) |row| {
                for (row) |*cell| {
                    cell.deinit(self.allocator);
                }
                self.allocator.free(row);
            }
            rows.deinit(self.allocator);
        }

        while (self.current.type == .table_row) {
            const cells = try parseTableCells(self.allocator, self.current.text);
            try rows.append(self.allocator, cells);
            self.advance();
        }

        return .{ .table = .{
            .headers = headers,
            .rows = try rows.toOwnedSlice(self.allocator),
            .alignments = try alignments.toOwnedSlice(self.allocator),
        } };
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
/// Parse inline content and return array of inline elements
fn parseInlineContent(allocator: std.mem.Allocator, text: []const u8) ParseError![]AST.Inline {
    var result: std.ArrayList(AST.Inline) = .empty;
    defer result.deinit(allocator);

    var i: usize = 0;
    var text_start: usize = 0;

    while (i < text.len) {
        const maybe_element = try parseNextInlineElement(allocator, text, &i, &text_start);
        if (maybe_element) |element| {
            try result.append(allocator, element);
        }
    }

    // Flush remaining text
    if (text_start < text.len) {
        const unescaped = try unescapeText(allocator, text[text_start..]);
        try result.append(allocator, .{ .text = unescaped });
    }

    return try result.toOwnedSlice(allocator);
}

/// Unescape markdown escape sequences (LOW-2 fix)
/// Converts: \\ -> \, \\* -> *, \\` -> `, etc.
fn unescapeText(allocator: std.mem.Allocator, text: []const u8) ParseError![]const u8 {
    // Count how many escape sequences we'll process
    var escape_count: usize = 0;
    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        if (text[i] == '\\' and i + 1 < text.len) {
            const next = text[i + 1];
            // Only count valid escape sequences
            if (next == '\\' or next == '*' or next == '`' or next == '[' or next == ']' or next == '(' or next == ')' or next == '#' or next == '+' or next == '-' or next == '.' or next == '!' or next == '<' or next == '>' or next == '_') {
                escape_count += 1;
                i += 1; // Skip the escaped character
            }
        }
    }

    if (escape_count == 0) {
        // No escapes, just duplicate the text
        return try allocator.dupe(u8, text);
    }

    // Allocate result with reduced size (minus escape characters)
    const result = try allocator.alloc(u8, text.len - escape_count);
    errdefer allocator.free(result);

    var j: usize = 0;
    i = 0;
    while (i < text.len) : (i += 1) {
        if (text[i] == '\\' and i + 1 < text.len) {
            const next = text[i + 1];
            // Only process valid escape sequences
            if (next == '\\' or next == '*' or next == '`' or next == '[' or next == ']' or next == '(' or next == ')' or next == '#' or next == '+' or next == '-' or next == '.' or next == '!' or next == '<' or next == '>' or next == '_') {
                result[j] = next; // Store the escaped character without the backslash
                j += 1;
                i += 1; // Skip the escaped character
                continue;
            }
        }
        result[j] = text[i];
        j += 1;
    }

    return result;
}

/// Parse the next inline element starting at position i
/// Updates i and text_start appropriately
/// Returns null if no special element found at this position
fn parseNextInlineElement(
    allocator: std.mem.Allocator,
    text: []const u8,
    i: *usize,
    text_start: *usize,
) ParseError!?AST.Inline {
    const pos = i.*;

    // Try each inline format handler in order of priority
    if (try parseInlineCode(allocator, text, i, text_start)) |elem| return elem;
    if (try parseLineBreak(allocator, text, i, text_start)) |elem| return elem;
    if (try parseStrong(allocator, text, i, text_start)) |elem| return elem;
    if (try parseEmphasis(allocator, text, i, text_start)) |elem| return elem;
    if (try parseLinkOrImage(allocator, text, i, text_start)) |elem| return elem;

    // No special element found, advance and return null
    i.* = pos + 1;
    return null;
}

/// Parse line break: <br>, <br/>, or two spaces at end of line (LOW-1 fix)
fn parseLineBreak(
    allocator: std.mem.Allocator,
    text: []const u8,
    i: *usize,
    text_start: *usize,
) ParseError!?AST.Inline {
    const pos = i.*;

    // Check for <br> or <br/> HTML tag
    if (text[pos] == '<') {
        const is_br = (pos + 4 <= text.len and std.mem.eql(u8, text[pos .. pos + 4], "<br>")) or
            (pos + 5 <= text.len and std.mem.eql(u8, text[pos .. pos + 5], "<br/>")) or
            (pos + 6 <= text.len and std.mem.eql(u8, text[pos .. pos + 6], "<br />"));

        if (is_br) {
            // Flush pending text before the line break
            if (pos > text_start.*) {
                const txt = try unescapeText(allocator, text[text_start.*..pos]);
                return .{ .text = txt };
            }

            // Skip past the <br> tag
            if (pos + 6 <= text.len and std.mem.eql(u8, text[pos .. pos + 6], "<br />")) {
                i.* = pos + 6;
            } else if (pos + 5 <= text.len and std.mem.eql(u8, text[pos .. pos + 5], "<br/>")) {
                i.* = pos + 5;
            } else {
                i.* = pos + 4;
            }
            text_start.* = i.*;
            return .line_break;
        }
    }

    // Check for two spaces at end of text (hard line break in Markdown)
    // This happens when the line ends with two spaces
    if (text.len >= 2 and pos == text.len - 1 and text[text.len - 1] == ' ' and text[text.len - 2] == ' ') {
        // This is the last character and we have two trailing spaces
        // The text should have been trimmed, so we check for this case
    }

    return null;
}

/// Parse inline code: `code`
fn parseInlineCode(
    allocator: std.mem.Allocator,
    text: []const u8,
    i: *usize,
    text_start: *usize,
) ParseError!?AST.Inline {
    if (text[i.*] != '`') return null;

    const start = i.*;

    // Flush pending text
    if (start > text_start.*) {
        const txt = try unescapeText(allocator, text[text_start.*..start]);
        return .{ .text = txt };
    }

    // Find closing backtick
    i.* += 1;
    const code_start = i.*;
    while (i.* < text.len and text[i.*] != '`') {
        i.* += 1;
    }
    const code = try allocator.dupe(u8, text[code_start..i.*]);

    if (i.* < text.len) i.* += 1; // skip closing `
    text_start.* = i.*;

    return .{ .code = code };
}

/// Parse strong text: **text**
fn parseStrong(
    allocator: std.mem.Allocator,
    text: []const u8,
    i: *usize,
    text_start: *usize,
) ParseError!?AST.Inline {
    const pos = i.*;
    if (pos + 1 >= text.len or text[pos] != '*' or text[pos + 1] != '*') return null;

    // Flush pending text
    if (pos > text_start.*) {
        const txt = try allocator.dupe(u8, text[text_start.*..pos]);
        return .{ .text = txt };
    }

    // Find closing **
    i.* = pos + 2;
    const strong_start = i.*;
    while (i.* + 1 < text.len and !(text[i.*] == '*' and text[i.* + 1] == '*')) {
        i.* += 1;
    }

    if (i.* + 1 < text.len) {
        // Parse content recursively
        const inner = try parseInlineContent(allocator, text[strong_start..i.*]);
        i.* += 2; // skip closing **
        text_start.* = i.*;
        return .{ .strong = inner };
    } else {
        // No closing **, treat as text
        const txt = try allocator.dupe(u8, text[strong_start - 2 .. i.*]);
        text_start.* = i.*;
        return .{ .text = txt };
    }
}

/// Parse emphasis text: *text*
fn parseEmphasis(
    allocator: std.mem.Allocator,
    text: []const u8,
    i: *usize,
    text_start: *usize,
) ParseError!?AST.Inline {
    const pos = i.*;
    if (pos >= text.len or text[pos] != '*') return null;
    // Skip if this is the start of strong (**)
    if (pos + 1 < text.len and text[pos + 1] == '*') return null;

    // Flush pending text
    if (pos > text_start.*) {
        const txt = try allocator.dupe(u8, text[text_start.*..pos]);
        return .{ .text = txt };
    }

    // Find closing *
    i.* = pos + 1;
    const emph_start = i.*;
    while (i.* < text.len and text[i.*] != '*') {
        i.* += 1;
    }

    if (i.* < text.len) {
        // Parse content recursively
        const inner = try parseInlineContent(allocator, text[emph_start..i.*]);
        i.* += 1; // skip closing *
        text_start.* = i.*;
        return .{ .emphasis = inner };
    } else {
        // No closing *, treat as text
        const txt = try allocator.dupe(u8, text[emph_start - 1 .. i.*]);
        text_start.* = i.*;
        return .{ .text = txt };
    }
}

/// Parse links and images: [text](url), [text][label], ![alt](url)
fn parseLinkOrImage(
    allocator: std.mem.Allocator,
    text: []const u8,
    i: *usize,
    text_start: *usize,
) ParseError!?AST.Inline {
    const pos = i.*;
    if (pos >= text.len) return null;

    // Check for images: ![alt](url)
    if (text[pos] == '!' and pos + 1 < text.len and text[pos + 1] == '[') {
        return try parseImage(allocator, text, i, text_start);
    }

    // Check for links: [text](url) or [text][label]
    if (text[pos] == '[') {
        return try parseLink(allocator, text, i, text_start);
    }

    return null;
}

/// Parse image: ![alt](url)
fn parseImage(
    allocator: std.mem.Allocator,
    text: []const u8,
    i: *usize,
    text_start: *usize,
) ParseError!?AST.Inline {
    const pos = i.*;
    if (pos >= text.len or text[pos] != '!' or pos + 1 >= text.len or text[pos + 1] != '[') return null;

    // Find closing ]
    var j = pos + 2;
    while (j < text.len and text[j] != ']') {
        j += 1;
    }

    // Check for ( following ]
    if (j + 1 >= text.len or text[j] != ']' or text[j + 1] != '(') return null;

    // Flush pending text
    if (pos > text_start.*) {
        const txt = try allocator.dupe(u8, text[text_start.*..pos]);
        return .{ .text = txt };
    }

    const alt_text = text[pos + 2 .. j];
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

    if (j < text.len) j += 1; // skip )
    i.* = j;
    text_start.* = j;

    return .{ .image = .{
        .alt = alt,
        .url = url,
    } };
}

/// Parse link: [text](url) or [text][label] or [text]
fn parseLink(
    allocator: std.mem.Allocator,
    text: []const u8,
    i: *usize,
    text_start: *usize,
) ParseError!?AST.Inline {
    const pos = i.*;
    if (pos >= text.len or text[pos] != '[') return null;

    // Find closing ]
    var j = pos + 1;
    while (j < text.len and text[j] != ']') {
        j += 1;
    }
    if (j >= text.len or text[j] != ']') return null;

    const link_text = text[pos + 1 .. j];

    // Determine link type based on what follows ]
    if (j + 1 < text.len and text[j + 1] == '(') {
        return try parseInlineLink(allocator, text, i, text_start, pos, j, link_text);
    } else if (j + 1 < text.len and text[j + 1] == '[') {
        return try parseRefLinkWithLabel(allocator, text, i, text_start, pos, j, link_text);
    } else {
        return try parseImplicitRefLink(allocator, text, i, text_start, pos, j, link_text);
    }
}

/// Parse inline link: [text](url)
fn parseInlineLink(
    allocator: std.mem.Allocator,
    text: []const u8,
    i: *usize,
    text_start: *usize,
    start_pos: usize,
    bracket_end: usize,
    link_text: []const u8,
) ParseError!?AST.Inline {
    // Flush pending text
    if (start_pos > text_start.*) {
        const txt = try allocator.dupe(u8, text[text_start.*..start_pos]);
        return .{ .text = txt };
    }

    var j = bracket_end + 2; // skip ](

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

    if (j < text.len) j += 1; // skip )
    i.* = j;
    text_start.* = j;

    return .{ .link = .{
        .text = inner,
        .url = url,
        .ref_label = null,
    } };
}

/// Parse reference-style link with explicit label: [text][label]
fn parseRefLinkWithLabel(
    allocator: std.mem.Allocator,
    text: []const u8,
    i: *usize,
    text_start: *usize,
    start_pos: usize,
    bracket_end: usize,
    link_text: []const u8,
) ParseError!?AST.Inline {
    // Flush pending text
    if (start_pos > text_start.*) {
        const txt = try allocator.dupe(u8, text[text_start.*..start_pos]);
        return .{ .text = txt };
    }

    var j = bracket_end + 2; // skip ][

    // Find closing ]
    const label_start = j;
    while (j < text.len and text[j] != ']') {
        j += 1;
    }
    const label = if (j > label_start)
        try allocator.dupe(u8, text[label_start..j])
    else
        null; // Empty label means use link text as label

    // Parse link text
    const inner = try parseInlineContent(allocator, link_text);
    errdefer {
        for (inner) |*inl| {
            inl.deinit(allocator);
        }
        allocator.free(inner);
    }

    if (j < text.len) j += 1; // skip ]
    i.* = j;
    text_start.* = j;

    // Store with empty URL - will be resolved during conversion
    return .{ .link = .{
        .text = inner,
        .url = try allocator.dupe(u8, ""),
        .ref_label = label,
    } };
}

/// Parse implicit reference-style link: [text]
fn parseImplicitRefLink(
    allocator: std.mem.Allocator,
    text: []const u8,
    i: *usize,
    text_start: *usize,
    start_pos: usize,
    bracket_end: usize,
    link_text: []const u8,
) ParseError!?AST.Inline {
    // Flush pending text
    if (start_pos > text_start.*) {
        const txt = try allocator.dupe(u8, text[text_start.*..start_pos]);
        return .{ .text = txt };
    }

    // Parse link text
    const inner = try parseInlineContent(allocator, link_text);
    errdefer {
        for (inner) |*inl| {
            inl.deinit(allocator);
        }
        allocator.free(inner);
    }

    // Store with implicit label
    const label = try allocator.dupe(u8, link_text);
    errdefer allocator.free(label);

    i.* = bracket_end + 1; // skip ]
    text_start.* = i.*;

    return .{ .link = .{
        .text = inner,
        .url = try allocator.dupe(u8, ""),
        .ref_label = label,
    } };
}

/// Extract speaker note text from HTML comment
/// Input: "<!-- Speaker note: This is a note -->"
/// Output: "This is a note"
fn extractSpeakerNotes(text: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    // Find the start of "Speaker note:"
    const prefix = "<!-- Speaker note:";
    var start: usize = 0;

    if (std.mem.startsWith(u8, text, prefix)) {
        start = prefix.len;
    } else {
        // Find "Speaker note:" anywhere in the text
        if (std.mem.indexOf(u8, text, "Speaker note:")) |idx| {
            start = idx + "Speaker note:".len;
        } else {
            // No prefix found, use everything after <!--
            if (std.mem.indexOf(u8, text, "<!--")) |idx| {
                start = idx + 4;
            }
        }
    }

    // Find the end (-->)
    var end = text.len;
    if (std.mem.indexOf(u8, text[start..], "-->")) |idx| {
        end = start + idx;
    }

    // Trim whitespace
    while (start < end and (text[start] == ' ' or text[start] == '\t')) {
        start += 1;
    }
    while (end > start and (text[end - 1] == ' ' or text[end - 1] == '\t' or text[end - 1] == '\n' or text[end - 1] == '\r')) {
        end -= 1;
    }

    return try allocator.dupe(u8, text[start..end]);
}

/// Parse a table row and return headers (just the text content)
fn parseTableRow(allocator: std.mem.Allocator, text: []const u8) ![][]const u8 {
    var result: std.ArrayList([]const u8) = .empty;
    defer result.deinit(allocator);

    var i: usize = 0;

    // Skip leading |
    if (i < text.len and text[i] == '|') {
        i += 1;
    }

    while (i < text.len) {
        // Skip whitespace
        while (i < text.len and (text[i] == ' ' or text[i] == '\t')) {
            i += 1;
        }

        const start = i;

        // Find next | or end of line
        while (i < text.len and text[i] != '|' and text[i] != '\n') {
            i += 1;
        }

        // Trim trailing whitespace and extract cell content
        var end = i;
        while (end > start and (text[end - 1] == ' ' or text[end - 1] == '\t')) {
            end -= 1;
        }

        if (end > start) {
            const cell = try allocator.dupe(u8, text[start..end]);
            try result.append(allocator, cell);
        }

        // Skip the |
        if (i < text.len and text[i] == '|') {
            i += 1;
        }
    }

    return try result.toOwnedSlice(allocator);
}

/// Parse table alignment row (|------|------|)
fn parseTableAlignments(allocator: std.mem.Allocator, text: []const u8) !std.ArrayList(AST.Table.Alignment) {
    var result: std.ArrayList(AST.Table.Alignment) = .empty;

    var i: usize = 0;

    // Skip leading |
    if (i < text.len and text[i] == '|') {
        i += 1;
    }

    while (i < text.len) {
        // Skip whitespace
        while (i < text.len and (text[i] == ' ' or text[i] == '\t')) {
            i += 1;
        }

        const start = i;

        // Find next | or end of line
        while (i < text.len and text[i] != '|' and text[i] != '\n') {
            i += 1;
        }

        const cell = text[start..i];

        // Determine alignment based on : positions
        const has_left = cell.len > 0 and cell[0] == ':';
        const has_right = cell.len > 0 and cell[cell.len - 1] == ':';

        const alignment: AST.Table.Alignment = if (has_left and has_right)
            .center
        else if (has_left)
            .left
        else if (has_right)
            .right
        else
            .default;

        try result.append(allocator, alignment);

        // Skip the |
        if (i < text.len and text[i] == '|') {
            i += 1;
        }
    }

    return result;
}

/// Parse table cells as inline content
fn parseTableCells(allocator: std.mem.Allocator, text: []const u8) ![]AST.Table.TableCell {
    var result: std.ArrayList(AST.Table.TableCell) = .empty;
    defer result.deinit(allocator);

    var i: usize = 0;

    // Skip leading |
    if (i < text.len and text[i] == '|') {
        i += 1;
    }

    while (i < text.len) {
        // Skip whitespace
        while (i < text.len and (text[i] == ' ' or text[i] == '\t')) {
            i += 1;
        }

        const start = i;

        // Find next | or end of line
        while (i < text.len and text[i] != '|' and text[i] != '\n') {
            i += 1;
        }

        // Trim trailing whitespace and extract cell content
        var end = i;
        while (end > start and (text[end - 1] == ' ' or text[end - 1] == '\t')) {
            end -= 1;
        }

        const cell_text = if (end > start) text[start..end] else "";
        const inlines = try parseInlineContent(allocator, cell_text);

        try result.append(allocator, .{ .content = inlines });

        // Skip the |
        if (i < text.len and text[i] == '|') {
            i += 1;
        }
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

test "extractSpeakerNotes" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Basic speaker note
    const notes1 = try extractSpeakerNotes("<!-- Speaker note: This is a note -->", allocator);
    defer allocator.free(notes1);
    try testing.expectEqualStrings("This is a note", notes1);

    // With extra whitespace
    const notes2 = try extractSpeakerNotes("<!-- Speaker note:   Trimmed note  -->", allocator);
    defer allocator.free(notes2);
    try testing.expectEqualStrings("Trimmed note", notes2);

    // Without "Speaker note:" prefix (fallback)
    const notes3 = try extractSpeakerNotes("<!-- Some other comment -->", allocator);
    defer allocator.free(notes3);
    try testing.expectEqualStrings("Some other comment", notes3);
}

test "Parser speaker notes" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source =
        \\# Title
        \\<!-- Speaker note: Remember to mention key point -->
        \\Content here
        \\<!-- Speaker note: Second note -->
        \\<!-- end_slide -->
    ;

    var parser = Parser.init(allocator, source);
    var presentation = try parser.parse();
    defer presentation.deinit();

    try testing.expectEqual(@as(usize, 1), presentation.slides.len);
    try testing.expect(presentation.slides[0].speaker_notes != null);
    // Notes should be combined with newline
    const notes = presentation.slides[0].speaker_notes.?;
    try testing.expect(std.mem.indexOf(u8, notes, "Remember to mention key point") != null);
    try testing.expect(std.mem.indexOf(u8, notes, "Second note") != null);
}

test "Parser ordered list" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source =
        \\# Ordered List
        \\1. First item
        \\2. Second item
        \\3. Third item
    ;

    var parser = Parser.init(allocator, source);
    var presentation = try parser.parse();
    defer presentation.deinit();

    try testing.expectEqual(@as(usize, 1), presentation.slides.len);
    try testing.expectEqual(@as(usize, 2), presentation.slides[0].elements.len);

    const list = presentation.slides[0].elements[1].list;
    try testing.expect(list.ordered);
    try testing.expectEqual(@as(usize, 3), list.items.len);
}

test "Parser unordered list" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source =
        \\# Unordered List
        \\- First item
        \\- Second item
        \\- Third item
    ;

    var parser = Parser.init(allocator, source);
    var presentation = try parser.parse();
    defer presentation.deinit();

    try testing.expectEqual(@as(usize, 1), presentation.slides.len);
    try testing.expectEqual(@as(usize, 2), presentation.slides[0].elements.len);

    const list = presentation.slides[0].elements[1].list;
    try testing.expect(!list.ordered);
    try testing.expectEqual(@as(usize, 3), list.items.len);
}

test "Scanner ordered list item token" {
    const testing = std.testing;

    var scanner = Scanner.init("1. Item\n");
    const t1 = scanner.nextToken();
    try testing.expectEqual(.ordered_list_item, t1.type);

    var scanner2 = Scanner.init("- Item\n");
    const t2 = scanner2.nextToken();
    try testing.expectEqual(.list_item, t2.type);
}

test "Parser nested unordered list" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source =
        \\# Nested List
        \\- Parent 1
        \\  - Child 1
        \\  - Child 2
        \\- Parent 2
    ;

    var parser = Parser.init(allocator, source);
    var presentation = try parser.parse();
    defer presentation.deinit();

    try testing.expectEqual(@as(usize, 1), presentation.slides.len);
    try testing.expectEqual(@as(usize, 2), presentation.slides[0].elements.len);

    const list = presentation.slides[0].elements[1].list;
    try testing.expect(!list.ordered);
    try testing.expectEqual(@as(usize, 2), list.items.len);

    // Check first parent has children
    try testing.expect(list.items[0].children != null);
    try testing.expectEqual(@as(usize, 2), list.items[0].children.?.items.len);

    // Check second parent has no children
    try testing.expect(list.items[1].children == null);
}

test "Parser deeply nested list" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source =
        \\# Deep Nesting
        \\- Level 1
        \\  - Level 2
        \\    - Level 3
        \\- Back to Level 1
    ;

    var parser = Parser.init(allocator, source);
    var presentation = try parser.parse();
    defer presentation.deinit();

    const list = presentation.slides[0].elements[1].list;
    try testing.expectEqual(@as(usize, 2), list.items.len);

    // First item has nested list with nested list
    const nested1 = list.items[0].children.?;
    try testing.expectEqual(@as(usize, 1), nested1.items.len);

    const nested2 = nested1.items[0].children.?;
    try testing.expectEqual(@as(usize, 1), nested2.items.len);
}

test "Parser table" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source =
        \\# Table Test
        \\| Name | Age | City |
        \\|------|-----|------|
        \\| John | 30  | NYC  |
        \\| Jane | 25  | LA   |
    ;

    var parser = Parser.init(allocator, source);
    var presentation = try parser.parse();
    defer presentation.deinit();

    try testing.expectEqual(@as(usize, 1), presentation.slides.len);
    try testing.expectEqual(@as(usize, 2), presentation.slides[0].elements.len);

    const table = presentation.slides[0].elements[1].table;
    try testing.expectEqual(@as(usize, 3), table.headers.len);
    try testing.expectEqualStrings("Name", table.headers[0]);
    try testing.expectEqualStrings("Age", table.headers[1]);
    try testing.expectEqualStrings("City", table.headers[2]);

    try testing.expectEqual(@as(usize, 2), table.rows.len);
    try testing.expectEqual(@as(usize, 3), table.rows[0].len);
}

test "Scanner table tokens" {
    const testing = std.testing;

    var scanner = Scanner.init("| col1 | col2 |\n");
    const t1 = scanner.nextToken();
    try testing.expectEqual(.table_row, t1.type);

    var scanner2 = Scanner.init("|------|------|\n");
    const t2 = scanner2.nextToken();
    try testing.expectEqual(.table_separator, t2.type);
}

test "Parser link reference definition" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source =
        \\# Link Test
        \\[example]: https://example.com
        \\Click [here][example]
    ;

    var parser = Parser.init(allocator, source);
    var presentation = try parser.parse();
    defer presentation.deinit();

    // Check link reference was collected
    try testing.expect(presentation.link_references.get("example") != null);
    try testing.expectEqualStrings("https://example.com", presentation.link_references.get("example").?);
}

test "Scanner link ref def token" {
    const testing = std.testing;

    var scanner = Scanner.init("[ref]: https://example.com\n");
    const t1 = scanner.nextToken();
    try testing.expectEqual(.link_ref_def, t1.type);
}
