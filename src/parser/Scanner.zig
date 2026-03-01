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
        self.skipWhitespace();

        const start = self.pos;
        const line = self.line;
        const col = self.col;

        if (self.isAtEnd()) {
            return self.makeToken(.eof, start, line, col);
        }

        const c = self.advance();

        // Check for end_slide comment
        if (c == '<' and self.matchString("!--")) {
            if (self.matchString(" end_slide ")) {
                _ = self.consumeUntil("-->");
                return self.makeToken(.end_slide, start, line, col);
            }
            // Skip other HTML comments
            _ = self.consumeUntil("-->");
            return self.nextToken();
        }

        // Headings
        if (c == '#') {
            _ = self.countPrefix('#');
            self.skipWhitespace();
            return self.makeToken(.heading, start, line, col);
        }

        // Thematic break / Front matter
        if (c == '-') {
            if (self.countPrefix('-') >= 2) {
                return self.makeToken(.thematic_break, start, line, col);
            }
        }

        // Code block
        if (c == '`' and self.matchString("``")) {
            return self.makeToken(.code_block, start, line, col);
        }

        // Blockquote
        if (c == '>') {
            return self.makeToken(.blockquote, start, line, col);
        }

        // List item
        if (c == '-' or c == '*' or c == '+') {
            if (self.peek() == ' ' or self.peek() == '\t') {
                return self.makeToken(.list_item, start, line, col);
            }
        }

        // Numbered list
        if (std.ascii.isDigit(c)) {
            if (self.peek() == '.' and (self.peekAhead(1) == ' ' or self.peekAhead(1) == '\t')) {
                _ = self.advance(); // consume '.'
                return self.makeToken(.list_item, start, line, col);
            }
        }

        // Blank line
        if (c == '\n') {
            return self.makeToken(.blank_line, start, line, col);
        }

        // Regular text - consume until end of line
        while (!self.isAtEnd() and self.peek() != '\n') {
            _ = self.advance();
        }

        return self.makeToken(.text, start, line, col);
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

    fn makeToken(self: *Self, typ: Token.Type, start: usize, line: usize, col: usize) Token {
        return .{
            .type = typ,
            .text = self.source[start..self.pos],
            .line = line,
            .col = col,
        };
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
