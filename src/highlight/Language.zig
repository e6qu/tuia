//! Language definitions for syntax highlighting
const std = @import("std");

/// Supported programming languages
pub const Language = enum {
    zig,
    python,
    javascript,
    typescript,
    c,
    cpp,
    rust,
    go,
    bash,
    json,
    markdown,
    unknown,

    const Self = @This();

    /// Get language from file extension
    pub fn fromExtension(ext: []const u8) Self {
        const map = std.StaticStringMap(Self).initComptime(.{
            .{ "zig", .zig },
            .{ "py", .python },
            .{ "js", .javascript },
            .{ "mjs", .javascript },
            .{ "ts", .typescript },
            .{ "mts", .typescript },
            .{ "c", .c },
            .{ "h", .c },
            .{ "cpp", .cpp },
            .{ "cc", .cpp },
            .{ "cxx", .cpp },
            .{ "hpp", .cpp },
            .{ "rs", .rust },
            .{ "go", .go },
            .{ "sh", .bash },
            .{ "bash", .bash },
            .{ "zsh", .bash },
            .{ "json", .json },
            .{ "md", .markdown },
            .{ "markdown", .markdown },
        });
        return map.get(ext) orelse .unknown;
    }

    /// Get language from markdown code block language identifier
    pub fn fromMarkdownTag(tag: []const u8) Self {
        return fromString(tag);
    }

    /// Get language from string identifier
    pub fn fromString(str: []const u8) Self {
        const map = std.StaticStringMap(Self).initComptime(.{
            .{ "zig", .zig },
            .{ "python", .python },
            .{ "py", .python },
            .{ "javascript", .javascript },
            .{ "js", .javascript },
            .{ "typescript", .typescript },
            .{ "ts", .typescript },
            .{ "c", .c },
            .{ "cpp", .cpp },
            .{ "c++", .cpp },
            .{ "rust", .rust },
            .{ "rs", .rust },
            .{ "go", .go },
            .{ "golang", .go },
            .{ "bash", .bash },
            .{ "sh", .bash },
            .{ "shell", .bash },
            .{ "zsh", .bash },
            .{ "json", .json },
            .{ "markdown", .markdown },
            .{ "md", .markdown },
        });
        return map.get(str) orelse .unknown;
    }

    /// Get the name of this language
    pub fn name(self: Self) []const u8 {
        return switch (self) {
            .zig => "Zig",
            .python => "Python",
            .javascript => "JavaScript",
            .typescript => "TypeScript",
            .c => "C",
            .cpp => "C++",
            .rust => "Rust",
            .go => "Go",
            .bash => "Bash",
            .json => "JSON",
            .markdown => "Markdown",
            .unknown => "Text",
        };
    }

    /// Check if this language has syntax highlighting support
    pub fn isSupported(self: Self) bool {
        return switch (self) {
            .zig, .python, .javascript, .typescript, .bash, .json => true,
            .c, .cpp, .rust, .go, .markdown, .unknown => false,
        };
    }
};

/// Language-specific keyword sets
pub const Keywords = struct {
    /// Zig keywords
    pub const zig = std.StaticStringMap(void).initComptime(.{
        .{"addrspace"},   .{"align"},    .{"allowzero"}, .{"and"},         .{"anyframe"},
        .{"anytype"},     .{"asm"},      .{"async"},     .{"await"},       .{"break"},
        .{"callconv"},    .{"catch"},    .{"comptime"},  .{"const"},       .{"continue"},
        .{"defer"},       .{"else"},     .{"enum"},      .{"errdefer"},    .{"error"},
        .{"export"},      .{"extern"},   .{"fn"},        .{"for"},         .{"if"},
        .{"inline"},      .{"noalias"},  .{"nosuspend"}, .{"opaque"},      .{"or"},
        .{"orelse"},      .{"packed"},   .{"pub"},       .{"resume"},      .{"return"},
        .{"linksection"}, .{"struct"},   .{"suspend"},   .{"switch"},      .{"test"},
        .{"threadlocal"}, .{"try"},      .{"union"},     .{"unreachable"}, .{"usingnamespace"},
        .{"var"},         .{"volatile"}, .{"while"},
    });

    /// Python keywords
    pub const python = std.StaticStringMap(void).initComptime(.{
        .{"False"},    .{"None"},    .{"True"},  .{"and"},   .{"as"},
        .{"assert"},   .{"async"},   .{"await"}, .{"break"}, .{"class"},
        .{"continue"}, .{"def"},     .{"del"},   .{"elif"},  .{"else"},
        .{"except"},   .{"finally"}, .{"for"},   .{"from"},  .{"global"},
        .{"if"},       .{"import"},  .{"in"},    .{"is"},    .{"lambda"},
        .{"nonlocal"}, .{"not"},     .{"or"},    .{"pass"},  .{"raise"},
        .{"return"},   .{"try"},     .{"while"}, .{"with"},  .{"yield"},
    });

    /// JavaScript/TypeScript keywords
    pub const javascript = std.StaticStringMap(void).initComptime(.{
        .{"break"},      .{"case"},     .{"catch"},   .{"class"},  .{"const"},
        .{"continue"},   .{"debugger"}, .{"default"}, .{"delete"}, .{"do"},
        .{"else"},       .{"export"},   .{"extends"}, .{"false"},  .{"finally"},
        .{"for"},        .{"function"}, .{"if"},      .{"import"}, .{"in"},
        .{"instanceof"}, .{"new"},      .{"null"},    .{"return"}, .{"super"},
        .{"switch"},     .{"this"},     .{"throw"},   .{"true"},   .{"try"},
        .{"typeof"},     .{"var"},      .{"void"},    .{"while"},  .{"with"},
        .{"let"},        .{"static"},   .{"yield"},   .{"await"},  .{"async"},
    });

    /// TypeScript-specific keywords (in addition to JavaScript)
    pub const typescript_extra = std.StaticStringMap(void).initComptime(.{
        .{"interface"}, .{"type"},     .{"namespace"},  .{"module"},    .{"declare"},
        .{"abstract"},  .{"readonly"}, .{"implements"}, .{"enum"},      .{"private"},
        .{"protected"}, .{"public"},   .{"get"},        .{"set"},       .{"unknown"},
        .{"never"},     .{"any"},      .{"number"},     .{"string"},    .{"boolean"},
        .{"symbol"},    .{"bigint"},   .{"object"},     .{"undefined"},
    });

    /// Bash keywords
    pub const bash = std.StaticStringMap(void).initComptime(.{
        .{"if"},       .{"then"},  .{"else"},     .{"elif"},     .{"fi"},
        .{"case"},     .{"in"},    .{"esac"},     .{"for"},      .{"do"},
        .{"done"},     .{"while"}, .{"until"},    .{"function"}, .{"return"},
        .{"exit"},     .{"break"}, .{"continue"}, .{"shift"},    .{"source"},
        .{"."},        .{"eval"},  .{"exec"},     .{"export"},   .{"local"},
        .{"readonly"}, .{"unset"}, .{"true"},     .{"false"},
    });

    /// Check if a word is a keyword for the given language
    pub fn isKeyword(language: Language, word: []const u8) bool {
        return switch (language) {
            .zig => zig.has(word),
            .python => python.has(word),
            .javascript => javascript.has(word),
            .typescript => javascript.has(word) or typescript_extra.has(word),
            .bash => bash.has(word),
            else => false,
        };
    }

    /// Check if a word is a type keyword
    pub fn isTypeKeyword(language: Language, word: []const u8) bool {
        const types = switch (language) {
            .zig => std.StaticStringMap(void).initComptime(.{
                .{"i8"},       .{"i16"},          .{"i32"},      .{"i64"},        .{"i128"},        .{"isize"},
                .{"u8"},       .{"u16"},          .{"u32"},      .{"u64"},        .{"u128"},        .{"usize"},
                .{"f16"},      .{"f32"},          .{"f64"},      .{"f128"},       .{"bool"},        .{"void"},
                .{"noreturn"}, .{"type"},         .{"anyerror"}, .{"c_short"},    .{"c_ushort"},    .{"c_int"},
                .{"c_uint"},   .{"c_long"},       .{"c_ulong"},  .{"c_longlong"}, .{"c_ulonglong"}, .{"c_char"},
                .{"c_double"}, .{"c_longdouble"},
            }),
            .python => std.StaticStringMap(void).initComptime(.{
                .{"int"},       .{"float"},      .{"str"},    .{"bool"},      .{"list"},
                .{"dict"},      .{"tuple"},      .{"set"},    .{"frozenset"}, .{"bytes"},
                .{"bytearray"}, .{"memoryview"}, .{"object"}, .{"type"},
            }),
            else => return false,
        };
        return types.has(word);
    }

    /// Check if a word is a constant
    pub fn isConstant(language: Language, word: []const u8) bool {
        const constants = switch (language) {
            .zig => std.StaticStringMap(void).initComptime(.{
                .{"true"}, .{"false"}, .{"null"}, .{"undefined"},
            }),
            .python => std.StaticStringMap(void).initComptime(.{
                .{"True"}, .{"False"}, .{"None"},
            }),
            .javascript, .typescript => std.StaticStringMap(void).initComptime(.{
                .{"true"}, .{"false"}, .{"null"}, .{"undefined"}, .{"Infinity"}, .{"NaN"},
            }),
            else => return false,
        };
        return constants.has(word);
    }
};

test "Language from extension" {
    const testing = std.testing;

    try testing.expectEqual(Language.zig, Language.fromExtension("zig"));
    try testing.expectEqual(Language.python, Language.fromExtension("py"));
    try testing.expectEqual(Language.javascript, Language.fromExtension("js"));
    try testing.expectEqual(Language.typescript, Language.fromExtension("ts"));
    try testing.expectEqual(Language.unknown, Language.fromExtension("unknown"));
}

test "Language from markdown tag" {
    const testing = std.testing;

    try testing.expectEqual(Language.zig, Language.fromMarkdownTag("zig"));
    try testing.expectEqual(Language.python, Language.fromMarkdownTag("python"));
    try testing.expectEqual(Language.python, Language.fromMarkdownTag("py"));
    try testing.expectEqual(Language.bash, Language.fromMarkdownTag("bash"));
    try testing.expectEqual(Language.bash, Language.fromMarkdownTag("shell"));
}

test "Keyword detection" {
    const testing = std.testing;

    try testing.expect(Keywords.isKeyword(.zig, "fn"));
    try testing.expect(Keywords.isKeyword(.zig, "const"));
    try testing.expect(!Keywords.isKeyword(.zig, "not_a_keyword"));

    try testing.expect(Keywords.isKeyword(.python, "def"));
    try testing.expect(Keywords.isKeyword(.python, "class"));

    try testing.expect(Keywords.isKeyword(.javascript, "function"));
    try testing.expect(Keywords.isKeyword(.javascript, "const"));
}
