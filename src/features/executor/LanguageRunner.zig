//! Language-specific runners for code execution
const std = @import("std");

/// Supported programming languages
pub const Language = enum {
    bash,
    python,
    javascript,
    zig,
    rust,
    go,
    lua,
    ruby,

    /// Get language from string identifier
    pub fn fromString(str: []const u8) ?Language {
        const map = std.StaticStringMap(Language).initComptime(.{
            .{ "bash", .bash },
            .{ "sh", .bash },
            .{ "shell", .bash },
            .{ "python", .python },
            .{ "python3", .python },
            .{ "py", .python },
            .{ "javascript", .javascript },
            .{ "js", .javascript },
            .{ "node", .javascript },
            .{ "zig", .zig },
            .{ "rust", .rust },
            .{ "rs", .rust },
            .{ "go", .go },
            .{ "golang", .go },
            .{ "lua", .lua },
            .{ "ruby", .ruby },
            .{ "rb", .ruby },
        });
        return map.get(str);
    }

    /// Get display name
    pub fn displayName(self: Language) []const u8 {
        return switch (self) {
            .bash => "Bash",
            .python => "Python",
            .javascript => "JavaScript",
            .zig => "Zig",
            .rust => "Rust",
            .go => "Go",
            .lua => "Lua",
            .ruby => "Ruby",
        };
    }
};

/// Runner provides language-specific execution logic
pub const Runner = struct {
    language: Language,

    const Self = @This();

    /// Get runner for a specific language
    pub fn forLanguage(language: Language) Self {
        return .{ .language = language };
    }

    /// Check if the language runtime is available
    pub fn isAvailable(self: Self) bool {
        return switch (self.language) {
            .bash => commandExists("bash") or commandExists("sh"),
            .python => commandExists("python3") or commandExists("python"),
            .javascript => commandExists("node"),
            .zig => commandExists("zig"),
            .rust => commandExists("rustc"),
            .go => commandExists("go"),
            .lua => commandExists("lua") or commandExists("lua5.3") or commandExists("lua5.4"),
            .ruby => commandExists("ruby"),
        };
    }

    /// Get the file extension for this language
    pub fn fileExtension(self: Self) []const u8 {
        return switch (self.language) {
            .bash => "sh",
            .python => "py",
            .javascript => "js",
            .zig => "zig",
            .rust => "rs",
            .go => "go",
            .lua => "lua",
            .ruby => "rb",
        };
    }

    /// Build command to execute file
    pub fn buildCommand(self: Self, allocator: std.mem.Allocator, file_path: []const u8) ![]const [:0]const u8 {
        return switch (self.language) {
            .bash => {
                const shell: [:0]const u8 = if (commandExists("bash")) "bash" else "sh";
                const args = try allocator.alloc([:0]const u8, 2);
                args[0] = try allocator.dupeZ(u8, shell);
                args[1] = try allocator.dupeZ(u8, file_path);
                return args;
            },
            .python => {
                const python: [:0]const u8 = if (commandExists("python3")) "python3" else "python";
                const args = try allocator.alloc([:0]const u8, 2);
                args[0] = try allocator.dupeZ(u8, python);
                args[1] = try allocator.dupeZ(u8, file_path);
                return args;
            },
            .javascript => {
                const args = try allocator.alloc([:0]const u8, 2);
                args[0] = try allocator.dupeZ(u8, "node");
                args[1] = try allocator.dupeZ(u8, file_path);
                return args;
            },
            .zig => {
                const args = try allocator.alloc([:0]const u8, 3);
                args[0] = try allocator.dupeZ(u8, "zig");
                args[1] = try allocator.dupeZ(u8, "run");
                args[2] = try allocator.dupeZ(u8, file_path);
                return args;
            },
            .rust => {
                const args = try allocator.alloc([:0]const u8, 2);
                args[0] = try allocator.dupeZ(u8, "rustc");
                args[1] = try allocator.dupeZ(u8, file_path);
                // Note: This would need more logic for running compiled binary
                return args;
            },
            .go => {
                const args = try allocator.alloc([:0]const u8, 3);
                args[0] = try allocator.dupeZ(u8, "go");
                args[1] = try allocator.dupeZ(u8, "run");
                args[2] = try allocator.dupeZ(u8, file_path);
                return args;
            },
            .lua => {
                const lua: [:0]const u8 = findLuaCommand() orelse "lua";
                const args = try allocator.alloc([:0]const u8, 2);
                args[0] = try allocator.dupeZ(u8, lua);
                args[1] = try allocator.dupeZ(u8, file_path);
                return args;
            },
            .ruby => {
                const args = try allocator.alloc([:0]const u8, 2);
                args[0] = try allocator.dupeZ(u8, "ruby");
                args[1] = try allocator.dupeZ(u8, file_path);
                return args;
            },
        };
    }

    /// Get default template code for this language
    pub fn getTemplate(self: Self) []const u8 {
        return switch (self.language) {
            .bash => "#!/bin/bash\n# Your bash code here\necho \"Hello, World!\"",
            .python => "# Your Python code here\nprint(\"Hello, World!\")",
            .javascript => "// Your JavaScript code here\nconsole.log(\"Hello, World!\");",
            .zig => "const std = @import(\"std\");\n\npub fn main() !void {\n    const stdout = std.io.getStdOut().writer();\n    try stdout.print(\"Hello, World!\\n\", .{});\n}",
            .rust => "fn main() {\n    println!(\"Hello, World!\");\n}",
            .go => "package main\n\nimport \"fmt\"\n\nfunc main() {\n    fmt.Println(\"Hello, World!\")\n}",
            .lua => "-- Your Lua code here\nprint(\"Hello, World!\")",
            .ruby => "# Your Ruby code here\nputs \"Hello, World!\"",
        };
    }
};

/// Check if a command exists in PATH
fn commandExists(cmd: []const u8) bool {
    const path = std.posix.getenv("PATH") orelse return false;

    // Use a fixed-size buffer on the stack
    var buf: [1024]u8 = undefined;

    var path_iter = std.mem.splitScalar(u8, path, ':');
    while (path_iter.next()) |dir| {
        // Check if path fits in buffer
        if (dir.len + 1 + cmd.len >= buf.len) continue;

        // Build path manually
        @memcpy(buf[0..dir.len], dir);
        buf[dir.len] = '/';
        @memcpy(buf[dir.len + 1 .. dir.len + 1 + cmd.len], cmd);
        const full_path = buf[0 .. dir.len + 1 + cmd.len];

        // Check if file exists and is executable using access
        if (std.fs.accessAbsolute(full_path, .{})) {
            return true;
        } else |_| {
            continue;
        }
    }

    return false;
}

/// Find available lua command
fn findLuaCommand() ?[:0]const u8 {
    const candidates = [_][:0]const u8{ "lua5.4", "lua5.3", "lua" };
    for (candidates) |cmd| {
        if (commandExists(cmd)) return cmd;
    }
    return null;
}

/// Get list of available languages
pub fn getAvailableLanguages(allocator: std.mem.Allocator) ![]Language {
    var languages = std.ArrayList(Language).init(allocator);
    defer languages.deinit();

    const all_languages = std.enums.values(Language);
    for (all_languages) |lang| {
        const runner = Runner.forLanguage(lang);
        if (runner.isAvailable()) {
            try languages.append(lang);
        }
    }

    return languages.toOwnedSlice();
}

test "Language.fromString" {
    const testing = std.testing;

    try testing.expectEqual(Language.bash, Language.fromString("bash").?);
    try testing.expectEqual(Language.bash, Language.fromString("sh").?);
    try testing.expectEqual(Language.python, Language.fromString("python").?);
    try testing.expectEqual(Language.python, Language.fromString("py").?);
    try testing.expectEqual(Language.javascript, Language.fromString("js").?);
    try testing.expectEqual(Language.zig, Language.fromString("zig").?);
    try testing.expect(Language.fromString("unknown") == null);
}

test "Runner.fileExtension" {
    const testing = std.testing;

    try testing.expectEqualStrings("sh", Runner.forLanguage(.bash).fileExtension());
    try testing.expectEqualStrings("py", Runner.forLanguage(.python).fileExtension());
    try testing.expectEqualStrings("js", Runner.forLanguage(.javascript).fileExtension());
}

test "Runner.getTemplate" {
    const testing = std.testing;

    const bash_template = Runner.forLanguage(.bash).getTemplate();
    try testing.expect(std.mem.containsAtLeast(u8, bash_template, 1, "Hello"));

    const python_template = Runner.forLanguage(.python).getTemplate();
    try testing.expect(std.mem.containsAtLeast(u8, python_template, 1, "Hello"));
}
