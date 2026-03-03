const std = @import("std");
const Token = @import("Token.zig").Token;

/// Scanner tokenizes markdown source
pub const Scanner = struct {
    source: []const u8,
    pos: usize,
    line: usize,
    col: usize,
    pending_line_break: bool, // LOW-1: track hard line breaks (two spaces at EOL)

    const Self = @This();

    pub fn init(source: []const u8) Self {
        return .{
            .source = source,
            .pos = 0,
            .line = 1,
            .col = 1,
            .pending_line_break = false,
        };
    }

    pub fn nextToken(self: *Self) Token {
        // LOW-1 fix: If we have a pending line break from two spaces, emit it now
        if (self.pending_line_break) {
            self.pending_line_break = false;
            // Consume the newline that follows the two spaces
            if (!self.isAtEnd() and self.source[self.pos] == @as(u8, '\n')) {
                _ = self.advance(); // consume newline
            }
            return self.makeToken(.line_break, self.pos, self.line, self.col, 0);
        }

        // Calculate indentation at start of line before skipping whitespace
        const indent = self.calculateIndent();

        self.skipWhitespace();

        const start = self.pos;
        const line = self.line;
        const col = self.col;

        if (self.isAtEnd()) {
            return self.makeToken(.eof, start, line, col, indent);
        }

        const c = self.advance();

        // Check for HTML comments (end_slide or speaker notes)
        if (c == '<' and self.matchString("!--")) {
            // Check for end_slide comment
            if (self.peek() == ' ' and self.pos + 10 <= self.source.len and
                std.mem.eql(u8, self.source[self.pos..][0..10], " end_slide "))
            {
                _ = self.consumeUntil("-->");
                return self.makeToken(.end_slide, start, line, col, indent);
            }
            // Check for speaker note comment
            if (self.peek() == ' ' and self.pos + 14 <= self.source.len and
                std.mem.eql(u8, self.source[self.pos..][0..14], " Speaker note:"))
            {
                _ = self.consumeUntil("-->");
                return self.makeToken(.speaker_note, start, line, col, indent);
            }
            // Skip other HTML comments
            _ = self.consumeUntil("-->");
            return self.nextToken();
        }

        // Check for link reference definition [ref]: url
        if (c == '[' and self.isLinkRefDef()) {
            // Consume until end of line
            while (!self.isAtEnd() and self.peek() != '\n') {
                _ = self.advance();
            }
            return self.makeToken(.link_ref_def, start, line, col, indent);
        }

        // Headings
        if (c == '#') {
            _ = self.countPrefix('#');
            self.skipWhitespace();
            return self.makeToken(.heading, start, line, col, indent);
        }

        // Thematic break / Front matter (---, ***, ___)
        if (c == '-') {
            if (self.countPrefix('-') >= 2) {
                return self.makeToken(.thematic_break, start, line, col, indent);
            }
        }
        if (c == '*') {
            if (self.countPrefix('*') >= 2) {
                return self.makeToken(.thematic_break, start, line, col, indent);
            }
        }
        if (c == '_') {
            if (self.countPrefix('_') >= 2) {
                return self.makeToken(.thematic_break, start, line, col, indent);
            }
        }

        // Code block
        if (c == '`' and self.matchString("``")) {
            return self.makeToken(.code_block, start, line, col, indent);
        }

        // Blockquote
        if (c == '>') {
            return self.makeToken(.blockquote, start, line, col, indent);
        }

        // List item
        if (c == '-' or c == '*' or c == '+') {
            if (self.peek() == ' ' or self.peek() == '\t') {
                return self.makeToken(.list_item, start, line, col, indent);
            }
        }

        // Numbered list (ordered)
        if (std.ascii.isDigit(c)) {
            if (self.peek() == '.' and (self.peekAhead(1) == ' ' or self.peekAhead(1) == '\t')) {
                _ = self.advance(); // consume '.'
                return self.makeToken(.ordered_list_item, start, line, col, indent);
            }
        }

        // Table row (starts with |)
        if (c == '|') {
            // Consume the entire line
            while (!self.isAtEnd() and self.peek() != '\n') {
                _ = self.advance();
            }
            const line_text = self.source[start..self.pos];

            // Check if this is a separator row (|-----|-----|)
            if (isTableSeparator(line_text)) {
                return self.makeToken(.table_separator, start, line, col, indent);
            }

            return self.makeToken(.table_row, start, line, col, indent);
        }

        // Blank line
        if (c == '\n') {
            return self.makeToken(.blank_line, start, line, col, indent);
        }

        // Regular text - consume until end of line
        while (!self.isAtEnd() and self.peek() != '\n') {
            _ = self.advance();
        }

        // LOW-1 fix: Check for hard line break (two spaces at end of line)
        const text_end = self.pos;
        const has_hard_break = text_end >= start + 2 and
            self.source[text_end - 1] == ' ' and
            self.source[text_end - 2] == ' ';

        if (has_hard_break) {
            // Count trailing spaces (need at least 2)
            var space_count: usize = 0;
            var i = text_end;
            while (i > start and self.source[i - 1] == ' ') {
                space_count += 1;
                i -= 1;
            }

            if (space_count >= 2) {
                // Move position back to before the trailing spaces
                self.pos = text_end - space_count;
                self.col -= space_count;
                self.pending_line_break = true;
                return self.makeToken(.text, start, line, col, indent);
            }
        }

        return self.makeToken(.text, start, line, col, indent);
    }

    fn isAtEnd(self: *Self) bool {
        return self.pos >= self.source.len;
    }

    fn advance(self: *Self) u8 {
        const c = self.source[self.pos];
        self.pos += 1;
        if (c == '\n') {
            self.line += 1;
            self.col = 1;
        } else {
            self.col += 1;
        }
        return c;
    }

    fn peek(self: *Self) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.pos];
    }

    fn peekAhead(self: *Self, n: usize) u8 {
        if (self.pos + n >= self.source.len) return 0;
        return self.source[self.pos + n];
    }

    fn matchString(self: *Self, str: []const u8) bool {
        if (self.pos + str.len > self.source.len) return false;
        if (std.mem.eql(u8, self.source[self.pos..][0..str.len], str)) {
            for (str) |_| _ = self.advance();
            return true;
        }
        return false;
    }

    fn countPrefix(self: *Self, char: u8) usize {
        var count: usize = 0;
        while (self.peek() == char) {
            _ = self.advance();
            count += 1;
        }
        return count;
    }

    fn skipWhitespace(self: *Self) void {
        while (!self.isAtEnd() and (self.peek() == ' ' or self.peek() == '\t')) {
            _ = self.advance();
        }
    }

    fn consumeUntil(self: *Self, delimiter: []const u8) []const u8 {
        const start = self.pos;
        while (!self.isAtEnd()) {
            if (self.pos + delimiter.len <= self.source.len and
                std.mem.eql(u8, self.source[self.pos..][0..delimiter.len], delimiter))
            {
                for (delimiter) |_| _ = self.advance();
                break;
            }
            _ = self.advance();
        }
        return self.source[start..self.pos];
    }

    fn makeToken(self: *Self, typ: Token.Type, start: usize, line: usize, col: usize, indent: usize) Token {
        return .{
            .type = typ,
            .text = self.source[start..self.pos],
            .line = line,
            .col = col,
            .indent = indent,
        };
    }

    fn calculateIndent(self: *Self) usize {
        // Save current position
        const saved_pos = self.pos;
        const saved_col = self.col;

        var indent: usize = 0;

        // Only calculate indent if we're at the start of a line
        if (saved_col == 1) {
            while (self.pos < self.source.len) {
                const c = self.source[self.pos];
                if (c == ' ') {
                    indent += 1;
                    self.pos += 1;
                } else if (c == '\t') {
                    indent += 4; // Tab = 4 spaces
                    self.pos += 1;
                } else {
                    break;
                }
            }
        }

        // Restore position (we only wanted to peek)
        self.pos = saved_pos;
        // Don't restore col since we didn't actually advance

        return indent;
    }

    /// Check if current position is a link reference definition
    /// Pattern: [label]: url
    fn isLinkRefDef(self: *Self) bool {
        const saved_pos = self.pos;
        defer self.pos = saved_pos;

        // Already consumed '[', so check what follows
        // Find closing ']'
        var found_close: bool = false;
        while (self.pos < self.source.len) {
            const ch = self.source[self.pos];
            if (ch == ']') {
                found_close = true;
                self.pos += 1;
                break;
            }
            if (ch == '\n' or ch == '[') {
                // Not a valid link ref def
                return false;
            }
            self.pos += 1;
        }

        if (!found_close) return false;

        // Check for ':'
        if (self.pos >= self.source.len or self.source[self.pos] != ':') {
            return false;
        }

        return true;
    }
};

/// Check if a line is a table separator (|-----|-----|)
fn isTableSeparator(text: []const u8) bool {
    // Must start with |
    if (text.len < 2 or text[0] != '|') return false;

    var has_dash = false;
    for (text[1..]) |c| {
        if (c == '|') {
            // Found another pipe, continue
            continue;
        } else if (c == '-' or c == ':' or c == ' ') {
            // Separator characters
            if (c == '-') has_dash = true;
        } else if (c == '\n' or c == '\r') {
            // End of line
            break;
        } else {
            // Found non-separator character
            return false;
        }
    }

    return has_dash;
}

// Tests
test "Scanner basic tokens" {
    const testing = std.testing;

    var scanner = Scanner.init("# Heading\n\nParagraph\n");

    const t1 = scanner.nextToken();
    try testing.expectEqual(.heading, t1.type);

    const t2 = scanner.nextToken();
    try testing.expectEqual(.blank_line, t2.type);

    const t3 = scanner.nextToken();
    try testing.expectEqual(.text, t3.type);
}

test "Scanner end_slide" {
    const testing = std.testing;

    var scanner = Scanner.init("<!-- end_slide -->");
    const t = scanner.nextToken();
    try testing.expectEqual(.end_slide, t.type);
}

test "Scanner thematic break variations" {
    const testing = std.testing;

    // Test --- (already supported)
    var scanner1 = Scanner.init("---");
    const t1 = scanner1.nextToken();
    try testing.expectEqual(.thematic_break, t1.type);

    // Test *** (LOW-3 fix)
    var scanner2 = Scanner.init("***");
    const t2 = scanner2.nextToken();
    try testing.expectEqual(.thematic_break, t2.type);

    // Test ___ (LOW-3 fix)
    var scanner3 = Scanner.init("___");
    const t3 = scanner3.nextToken();
    try testing.expectEqual(.thematic_break, t3.type);
}

test "Scanner hard line break (two spaces)" {
    const testing = std.testing;

    // Test hard line break with two spaces at end of line (LOW-1 fix)
    var scanner = Scanner.init("Line one  \nLine two");

    const t1 = scanner.nextToken();
    try testing.expectEqual(.text, t1.type);
    try testing.expectEqualStrings("Line one", t1.text);

    const t2 = scanner.nextToken();
    try testing.expectEqual(.line_break, t2.type);

    const t3 = scanner.nextToken();
    try testing.expectEqual(.text, t3.type);
    try testing.expectEqualStrings("Line two", t3.text);
}
