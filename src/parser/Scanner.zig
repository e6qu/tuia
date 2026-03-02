const std = @import("std");
const Token = @import("Token.zig").Token;

/// Scanner tokenizes markdown source
pub const Scanner = struct {
    source: []const u8,
    pos: usize,
    line: usize,
    col: usize,

    const Self = @This();

    pub fn init(source: []const u8) Self {
        return .{
            .source = source,
            .pos = 0,
            .line = 1,
            .col = 1,
        };
    }

    pub fn nextToken(self: *Self) Token {
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

        // Headings
        if (c == '#') {
            _ = self.countPrefix('#');
            self.skipWhitespace();
            return self.makeToken(.heading, start, line, col, indent);
        }

        // Thematic break / Front matter
        if (c == '-') {
            if (self.countPrefix('-') >= 2) {
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

        // Blank line
        if (c == '\n') {
            return self.makeToken(.blank_line, start, line, col, indent);
        }

        // Regular text - consume until end of line
        while (!self.isAtEnd() and self.peek() != '\n') {
            _ = self.advance();
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
};

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
