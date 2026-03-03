//! Configuration file parser for YAML format
const std = @import("std");
const Config = @import("Config.zig").Config;
const PresentationConfig = @import("Config.zig").PresentationConfig;
const ThemeConfig = @import("Config.zig").ThemeConfig;
const KeyConfig = @import("Config.zig").KeyConfig;
const DisplayConfig = @import("Config.zig").DisplayConfig;
const ExportConfig = @import("Config.zig").ExportConfig;
const ExecutorConfig = @import("Config.zig").ExecutorConfig;
const WatchConfig = @import("Config.zig").WatchConfig;

/// Parser for configuration files
pub const ConfigParser = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{ .allocator = allocator };
    }

    /// Parse configuration from YAML string
    pub fn parseString(self: Self, source: []const u8) !Config {
        var config: Config = .{};

        // Simple YAML-like parsing (key: value pairs and sections)
        var lines = std.mem.splitScalar(u8, source, '\n');
        var current_section: ?[]const u8 = null;

        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \t\r");

            // Skip empty lines and comments
            if (trimmed.len == 0 or trimmed[0] == '#') continue;

            // Check for section header (no leading whitespace, ends with colon)
            if (!std.mem.startsWith(u8, line, " ") and !std.mem.startsWith(u8, line, "\t")) {
                if (std.mem.endsWith(u8, trimmed, ":")) {
                    current_section = std.mem.trim(u8, trimmed, ":");
                    continue;
                }
            }

            // Parse key-value pair within section
            if (current_section) |section| {
                try self.parseKeyValue(&config, section, trimmed);
            }
        }

        return config;
    }

    /// Parse configuration from file
    pub fn parseFile(self: Self, path: []const u8) !Config {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const content = try file.readToEndAlloc(self.allocator, 1024 * 1024); // Max 1MB
        defer self.allocator.free(content);

        return try self.parseString(content);
    }

    /// Parse a key-value pair within a section
    fn parseKeyValue(self: Self, config: *Config, section: []const u8, line: []const u8) !void {
        // Find the colon separator
        const colon_pos = std.mem.indexOf(u8, line, ":");
        if (colon_pos == null) return;

        const key = std.mem.trim(u8, line[0..colon_pos.?], " \t");
        const value = std.mem.trim(u8, line[colon_pos.? + 1 ..], " \t'\"");

        // Parse based on section
        if (std.mem.eql(u8, section, "presentation")) {
            try self.parsePresentationKey(&config.presentation, key, value);
        } else if (std.mem.eql(u8, section, "theme")) {
            try self.parseThemeKey(&config.theme, key, value);
        } else if (std.mem.eql(u8, section, "keys")) {
            try self.parseKeysKey(&config.keys, key, value);
        } else if (std.mem.eql(u8, section, "display")) {
            try self.parseDisplayKey(&config.display, key, value);
        } else if (std.mem.eql(u8, section, "export")) {
            try self.parseExportKey(&config.export_config, key, value);
        } else if (std.mem.eql(u8, section, "executor")) {
            try self.parseExecutorKey(&config.executor, key, value);
        } else if (std.mem.eql(u8, section, "watch")) {
            try self.parseWatchKey(&config.watch, key, value);
        }
    }

    fn parsePresentationKey(_: Self, config: *PresentationConfig, key: []const u8, value: []const u8) !void {
        if (std.mem.eql(u8, key, "auto_advance_seconds")) {
            config.auto_advance_seconds = std.fmt.parseInt(u32, value, 10) catch 0;
        } else if (std.mem.eql(u8, key, "loop")) {
            config.loop = parseBool(value);
        } else if (std.mem.eql(u8, key, "show_slide_numbers")) {
            config.show_slide_numbers = parseBool(value);
        } else if (std.mem.eql(u8, key, "show_total_slides")) {
            config.show_total_slides = parseBool(value);
        } else if (std.mem.eql(u8, key, "aspect_ratio")) {
            config.aspect_ratio = @import("Config.zig").AspectRatio.fromString(value);
        }
    }

    fn parseThemeKey(self: Self, config: *ThemeConfig, key: []const u8, value: []const u8) !void {
        if (std.mem.eql(u8, key, "name")) {
            config.name = try self.allocator.dupe(u8, value);
        } else if (std.mem.eql(u8, key, "custom_theme_path")) {
            config.custom_theme_path = try self.allocator.dupe(u8, value);
        } else if (std.mem.eql(u8, key, "use_terminal_background")) {
            config.use_terminal_background = parseBool(value);
        }
    }

    fn parseKeysKey(self: Self, config: *KeyConfig, key: []const u8, value: []const u8) !void {
        const duped_value = try self.allocator.dupe(u8, value);

        if (std.mem.eql(u8, key, "next_slide")) {
            config.next_slide = duped_value;
        } else if (std.mem.eql(u8, key, "prev_slide")) {
            config.prev_slide = duped_value;
        } else if (std.mem.eql(u8, key, "first_slide")) {
            config.first_slide = duped_value;
        } else if (std.mem.eql(u8, key, "last_slide")) {
            config.last_slide = duped_value;
        } else if (std.mem.eql(u8, key, "quit")) {
            config.quit = duped_value;
        } else if (std.mem.eql(u8, key, "help")) {
            config.help = duped_value;
        } else {
            self.allocator.free(duped_value);
        }
    }

    fn parseDisplayKey(_: Self, config: *DisplayConfig, key: []const u8, value: []const u8) !void {
        if (std.mem.eql(u8, key, "min_width")) {
            config.min_width = std.fmt.parseInt(u16, value, 10) catch 40;
        } else if (std.mem.eql(u8, key, "min_height")) {
            config.min_height = std.fmt.parseInt(u16, value, 10) catch 10;
        } else if (std.mem.eql(u8, key, "truecolor")) {
            config.truecolor = parseBool(value);
        } else if (std.mem.eql(u8, key, "mouse")) {
            config.mouse = parseBool(value);
        } else if (std.mem.eql(u8, key, "unicode")) {
            config.unicode = std.meta.stringToEnum(@TypeOf(config.unicode), value) orelse config.unicode;
        }
    }

    fn parseExportKey(self: Self, config: *ExportConfig, key: []const u8, value: []const u8) !void {
        if (std.mem.eql(u8, key, "default_format")) {
            config.default_format = std.meta.stringToEnum(@TypeOf(config.default_format), value) orelse config.default_format;
        } else if (std.mem.eql(u8, key, "output_dir")) {
            config.output_dir = try self.allocator.dupe(u8, value);
        } else if (std.mem.eql(u8, key, "include_notes")) {
            config.include_notes = parseBool(value);
        } else if (std.mem.eql(u8, key, "self_contained")) {
            config.self_contained = parseBool(value);
        }
    }

    fn parseExecutorKey(_: Self, config: *ExecutorConfig, key: []const u8, value: []const u8) !void {
        if (std.mem.eql(u8, key, "timeout_seconds")) {
            config.timeout_seconds = std.fmt.parseInt(u32, value, 10) catch 30;
        } else if (std.mem.eql(u8, key, "max_output_size")) {
            config.max_output_size = std.fmt.parseInt(usize, value, 10) catch 1024 * 1024;
        }
    }

    fn parseWatchKey(_: Self, config: *WatchConfig, key: []const u8, value: []const u8) !void {
        if (std.mem.eql(u8, key, "enabled")) {
            config.enabled = parseBool(value);
        } else if (std.mem.eql(u8, key, "debounce_ms")) {
            config.debounce_ms = std.fmt.parseInt(u32, value, 10) catch 300;
        }
    }
};

/// Parse boolean from string
fn parseBool(value: []const u8) bool {
    // Check common true values (case-insensitive)
    if (value.len >= 16) return false;

    var lower_buf: [16]u8 = undefined;
    @memset(&lower_buf, 0);

    for (value, 0..) |c, i| {
        lower_buf[i] = std.ascii.toLower(c);
    }

    const lower = std.mem.trim(u8, &lower_buf, "\x00");
    return std.mem.eql(u8, lower, "true") or
        std.mem.eql(u8, lower, "yes") or
        std.mem.eql(u8, lower, "1") or
        std.mem.eql(u8, lower, "on");
}

/// Configuration parse errors
pub const ParseError = error{
    InvalidSyntax,
    UnknownSection,
    UnknownKey,
    InvalidValue,
    OutOfMemory,
};

test "ConfigParser basic" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const parser = ConfigParser.init(allocator);

    const yaml =
        "# TUIA Configuration\n" ++
        "presentation:\n" ++
        "  loop: true\n" ++
        "  show_slide_numbers: false\n" ++
        "theme:\n" ++
        "  name: light\n" ++
        "executor:\n" ++
        "  timeout_seconds: 60\n";

    var config = try parser.parseString(yaml);
    defer config.deinit(allocator);

    try testing.expect(config.presentation.loop);
    try testing.expect(!config.presentation.show_slide_numbers);
    try testing.expectEqualStrings("light", config.theme.name);
    try testing.expectEqual(@as(u32, 60), config.executor.timeout_seconds);
}

test "ConfigParser all sections" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const parser = ConfigParser.init(allocator);

    const yaml =
        "presentation:\n" ++
        "  auto_advance_seconds: 10\n" ++
        "  loop: true\n" ++
        "  aspect_ratio: 16:9\n" ++
        "display:\n" ++
        "  min_width: 80\n" ++
        "  truecolor: false\n" ++
        "  unicode: basic\n" ++
        "watch:\n" ++
        "  enabled: false\n" ++
        "  debounce_ms: 500\n";

    var config = try parser.parseString(yaml);
    defer config.deinit(allocator);

    try testing.expectEqual(@as(u32, 10), config.presentation.auto_advance_seconds);
    try testing.expect(config.presentation.loop);
    try testing.expectEqual(@as(u16, 80), config.display.min_width);
    try testing.expect(!config.display.truecolor);
    try testing.expect(!config.watch.enabled);
    try testing.expectEqual(@as(u32, 500), config.watch.debounce_ms);
}
