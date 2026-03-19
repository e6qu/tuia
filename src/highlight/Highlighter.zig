//! Simple syntax highlighter for code blocks
const std = @import("std");
const Token = @import("Token.zig").Token;
const TokenKind = @import("Token.zig").TokenKind;
const Language = @import("Language.zig").Language;
const Keywords = @import("Language.zig").Keywords;

/// Highlighter tokenizes source code for syntax highlighting
pub const Highlighter = struct {
    source: []const u8,
    language: Language,
    pos: usize = 0,

    const Self = @This();

    pub fn init(source: []const u8, language: Language) Self {
        return .{
            .source = source,
            .language = language,
            .pos = 0,
        };
    }

    /// Tokenize the entire source and return all tokens
    pub fn tokenizeAll(self: *Self, allocator: std.mem.Allocator) ![]Token {
        var tokens: std.ArrayList(Token) = .empty;
        defer tokens.deinit(allocator);

        while (true) {
            const tok = self.nextToken();
            try tokens.append(allocator, tok);
            if (tok.kind == .eof) break;
        }

        return tokens.toOwnedSlice(allocator);
    }

    /// Get the next token
    pub fn nextToken(self: *Self) Token {
        // Emit whitespace as its own token so code rendering preserves spacing
        if (self.pos < self.source.len and std.ascii.isWhitespace(self.source[self.pos])) {
            const start = self.pos;
            while (self.pos < self.source.len and std.ascii.isWhitespace(self.source[self.pos])) {
                self.pos += 1;
            }
            return Token.init(.whitespace, self.source[start..self.pos], start, self.pos);
        }

        if (self.pos >= self.source.len) {
            return Token.init(.eof, "", self.pos, self.pos);
        }

        const c = self.source[self.pos];

        // Comments (language-specific)
        if (self.language == .zig or self.language == .c or self.language == .cpp or self.language == .rust or self.language == .go) {
            if (c == '/' and self.peek(1) == '/') {
                return self.readLineComment();
            }
        }
        if (self.language == .python or self.language == .bash) {
            if (c == '#') {
                return self.readLineComment();
            }
        }

        // String literals
        if (c == '"' or c == '\'' or c == '`') {
            return self.readString(c);
        }

        // Numbers
        if (std.ascii.isDigit(c) or (c == '.' and std.ascii.isDigit(self.peek(1)))) {
            return self.readNumber();
        }

        // Identifiers and keywords
        if (std.ascii.isAlphabetic(c) or c == '_') {
            return self.readIdentifier();
        }

        // Operators and delimiters
        return self.readOperatorOrDelimiter();
    }

    /// Read a line comment
    fn readLineComment(self: *Self) Token {
        const start = self.pos;
        while (self.pos < self.source.len and self.source[self.pos] != '\n') {
            self.pos += 1;
        }
        return Token.init(.comment, self.source[start..self.pos], start, self.pos);
    }

    /// Read a string literal
    fn readString(self: *Self, quote: u8) Token {
        const start = self.pos;
        self.pos += 1; // consume opening quote

        while (self.pos < self.source.len) {
            const c = self.source[self.pos];
            if (c == '\\') {
                self.pos += 2; // skip escape sequence
                continue;
            }
            if (c == quote) {
                self.pos += 1;
                break;
            }
            self.pos += 1;
        }

        return Token.init(.string, self.source[start..self.pos], start, self.pos);
    }

    /// Read a number literal
    fn readNumber(self: *Self) Token {
        const start = self.pos;

        // Integer part
        while (self.pos < self.source.len and std.ascii.isDigit(self.source[self.pos])) {
            self.pos += 1;
        }

        // Decimal part
        if (self.pos < self.source.len and self.source[self.pos] == '.') {
            self.pos += 1;
            while (self.pos < self.source.len and std.ascii.isDigit(self.source[self.pos])) {
                self.pos += 1;
            }
        }

        // Exponent
        if (self.pos < self.source.len and (self.source[self.pos] == 'e' or self.source[self.pos] == 'E')) {
            self.pos += 1;
            if (self.pos < self.source.len and (self.source[self.pos] == '+' or self.source[self.pos] == '-')) {
                self.pos += 1;
            }
            while (self.pos < self.source.len and std.ascii.isDigit(self.source[self.pos])) {
                self.pos += 1;
            }
        }

        // Zig-specific number suffixes
        if (self.language == .zig) {
            while (self.pos < self.source.len and (std.ascii.isAlphabetic(self.source[self.pos]) or self.source[self.pos] == '_')) {
                self.pos += 1;
            }
        }

        return Token.init(.number, self.source[start..self.pos], start, self.pos);
    }

    /// Read an identifier or keyword
    fn readIdentifier(self: *Self) Token {
        const start = self.pos;

        while (self.pos < self.source.len and (std.ascii.isAlphanumeric(self.source[self.pos]) or self.source[self.pos] == '_')) {
            self.pos += 1;
        }

        const text = self.source[start..self.pos];
        const kind = self.classifyIdentifier(text);

        return Token.init(kind, text, start, self.pos);
    }

    /// Classify an identifier as keyword, type, constant, or regular identifier
    fn classifyIdentifier(self: Self, text: []const u8) TokenKind {
        if (Keywords.isKeyword(self.language, text)) {
            return .keyword;
        }
        if (Keywords.isTypeKeyword(self.language, text)) {
            return .keyword_type;
        }
        if (Keywords.isConstant(self.language, text)) {
            return .keyword_constant;
        }
        return .identifier;
    }

    /// Read an operator or delimiter
    fn readOperatorOrDelimiter(self: *Self) Token {
        const start = self.pos;
        const c = self.source[self.pos];
        self.pos += 1;

        // Multi-character operators
        if (self.pos < self.source.len) {
            const next = self.source[self.pos];
            const two_char = &[_]u8{ c, next };

            const multi_ops = [_][]const u8{
                "==", "!=", "<=", ">=", "+=", "-=",  "*=", "/=",
                "%=", "&=", "|=", "^=", "<<", ">>",  "&&", "||",
                "++", "--", "->", "=>", "..", "...",
            };

            for (multi_ops) |op| {
                if (std.mem.eql(u8, two_char, op)) {
                    self.pos += 1;
                    return Token.init(.operator, self.source[start..self.pos], start, self.pos);
                }
            }
        }

        // Single-character classification
        const kind: TokenKind = switch (c) {
            '(', ')', '[', ']', '{', '}' => .bracket,
            ',', ';', ':', '.' => .delimiter,
            '+', '-', '*', '/', '%', '=', '<', '>', '!', '&', '|', '^', '~' => .operator,
            else => .unknown,
        };

        return Token.init(kind, self.source[start..self.pos], start, self.pos);
    }

    /// Peek at a character ahead without advancing
    fn peek(self: Self, offset: usize) u8 {
        const idx = self.pos + offset;
        if (idx >= self.source.len) return 0;
        return self.source[idx];
    }
};

/// Highlight source code and return highlighted lines
pub fn highlight(allocator: std.mem.Allocator, source: []const u8, language: Language) ![]Token {
    var highlighter = Highlighter.init(source, language);
    return highlighter.tokenizeAll(allocator);
}

test "Highlighter basic tokenization" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source = "const x = 42;";
    var highlighter = Highlighter.init(source, .zig);

    const tokens = try highlighter.tokenizeAll(allocator);
    defer allocator.free(tokens);

    // const, ' ', x, ' ', =, ' ', 42, ;, eof
    try testing.expectEqual(@as(usize, 9), tokens.len);
    try testing.expectEqual(TokenKind.keyword, tokens[0].kind);
    try testing.expectEqualStrings("const", tokens[0].text);
    try testing.expectEqual(TokenKind.whitespace, tokens[1].kind);
    try testing.expectEqual(TokenKind.identifier, tokens[2].kind);
    try testing.expectEqual(TokenKind.whitespace, tokens[3].kind);
    try testing.expectEqual(TokenKind.operator, tokens[4].kind);
    try testing.expectEqual(TokenKind.whitespace, tokens[5].kind);
    try testing.expectEqual(TokenKind.number, tokens[6].kind);
}

test "Highlighter string literals" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source = "\"hello world\"";
    var highlighter = Highlighter.init(source, .zig);

    const tokens = try highlighter.tokenizeAll(allocator);
    defer allocator.free(tokens);

    try testing.expectEqual(@as(usize, 2), tokens.len);
    try testing.expectEqual(TokenKind.string, tokens[0].kind);
    try testing.expectEqualStrings("\"hello world\"", tokens[0].text);
}

test "Highlighter comments" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source = "// this is a comment";
    var highlighter = Highlighter.init(source, .zig);

    const tokens = try highlighter.tokenizeAll(allocator);
    defer allocator.free(tokens);

    try testing.expectEqual(@as(usize, 2), tokens.len);
    try testing.expectEqual(TokenKind.comment, tokens[0].kind);
}

test "Highlighter Python" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const source = "def hello():\n    return 42";
    var highlighter = Highlighter.init(source, .python);

    const tokens = try highlighter.tokenizeAll(allocator);
    defer allocator.free(tokens);

    try testing.expectEqual(TokenKind.keyword, tokens[0].kind);
    try testing.expectEqualStrings("def", tokens[0].text);
}
