//! Configuration manager for loading and managing settings
const std = @import("std");
const Config = @import("Config.zig").Config;
const ConfigParser = @import("ConfigParser.zig").ConfigParser;

/// Configuration manager handles loading and merging configs
pub const ConfigManager = struct {
    allocator: std.mem.Allocator,
    config: Config,
    loaded_paths: std.ArrayList([]const u8),
    is_dirty: bool = false,

    const Self = @This();

    /// Config file names to search for
    const CONFIG_FILES = &[_][]const u8{
        "tuia.yaml",
        "tuia.yml",
        ".tuiarc",
        ".tuia.yaml",
    };

    /// Config directories to search (relative to home)
    const CONFIG_DIRS = &[_][]const u8{
        ".config/tuia",
        ".tuia",
    };

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .config = Config.defaults(),
            .loaded_paths = std.ArrayList([]const u8).empty,
        };
    }

    pub fn deinit(self: *Self) void {
        // Clean up config allocations
        self.config.deinit(self.allocator);
        // Clean up loaded paths
        for (self.loaded_paths.items) |path| {
            self.allocator.free(path);
        }
        self.loaded_paths.deinit(self.allocator);
    }

    /// Get current configuration
    pub fn getConfig(self: Self) Config {
        return self.config;
    }

    /// Load configuration from all standard locations
    pub fn loadDefault(self: *Self) !void {
        // 1. Load built-in defaults (already set)

        // 2. Load system config
        if (try self.findSystemConfig()) |path| {
            try self.loadFile(path);
            self.allocator.free(path);
        }

        // 3. Load user config
        if (try self.findUserConfig()) |path| {
            try self.loadFile(path);
            self.allocator.free(path);
        }

        // 4. Load project config (current directory)
        if (try self.findProjectConfig()) |path| {
            try self.loadFile(path);
            self.allocator.free(path);
        }
    }

    /// Load configuration from a specific file
    pub fn loadFile(self: *Self, path: []const u8) !void {
        const parser = ConfigParser.init(self.allocator);
        const new_config = try parser.parseFile(path);

        // Merge with existing config
        self.config.merge(new_config);

        // Track loaded path
        const path_copy = try self.allocator.dupe(u8, path);
        try self.loaded_paths.append(path_copy);

        self.is_dirty = true;
    }

    /// Load configuration from string
    pub fn loadString(self: *Self, source: []const u8) !void {
        const parser = ConfigParser.init(self.allocator);
        const new_config = try parser.parseString(source);

        self.config.merge(new_config);
        self.is_dirty = true;
    }

    /// Apply command-line overrides
    pub fn applyOverrides(self: *Self, overrides: ConfigOverrides) !void {
        if (overrides.theme) |theme| {
            self.config.theme.name = try self.allocator.dupe(u8, theme);
        }
        if (overrides.loop) |loop| {
            self.config.presentation.loop = loop;
        }
        if (overrides.auto_advance) |seconds| {
            self.config.presentation.auto_advance_seconds = seconds;
        }
        if (overrides.timeout) |seconds| {
            self.config.executor.timeout_seconds = seconds;
        }

        self.is_dirty = true;
    }

    /// Reset to defaults
    pub fn reset(self: *Self) void {
        self.config = Config.defaults();
        self.is_dirty = true;
    }

    /// Find system-wide configuration file
    fn findSystemConfig(_: Self) !?[]const u8 {
        // On most systems, system config would be in /etc
        // For now, skip system config
        return null;
    }

    /// Find user configuration file
    fn findUserConfig(self: Self) !?[]const u8 {
        const home = std.posix.getenv("HOME") orelse return null;

        for (CONFIG_DIRS) |dir| {
            for (CONFIG_FILES) |file| {
                const path = try std.fs.path.join(self.allocator, &.{ home, dir, file });
                errdefer self.allocator.free(path);

                // Check if file exists
                std.fs.accessAbsolute(path, .{}) catch continue;
                return path;
            }
        }

        return null;
    }

    /// Find project configuration in current directory
    fn findProjectConfig(self: Self) !?[]const u8 {
        for (CONFIG_FILES) |file| {
            // Check current directory
            std.fs.cwd().access(file, .{}) catch continue;

            // Get absolute path
            const cwd = try std.fs.cwd().realpathAlloc(self.allocator, ".");
            defer self.allocator.free(cwd);

            return try std.fs.path.join(self.allocator, &.{ cwd, file });
        }

        return null;
    }

    /// Get list of loaded config files
    pub fn getLoadedPaths(self: Self) []const []const u8 {
        return self.loaded_paths.items;
    }

    /// Check if configuration has been modified
    pub fn isDirty(self: Self) bool {
        return self.is_dirty;
    }

    /// Create a sample configuration file
    pub fn createSampleConfig(self: Self, path: []const u8) !void {
        _ = self;
        const sample =
            "# TUIA Configuration File\n" ++
            "# See documentation for all available options\n" ++
            "\n" ++
            "presentation:\n" ++
            "  auto_advance_seconds: 0\n" ++
            "  loop: false\n" ++
            "  show_slide_numbers: true\n" ++
            "  show_total_slides: true\n" ++
            "\n" ++
            "theme:\n" ++
            "  name: dark\n" ++
            "\n" ++
            "keys:\n" ++
            "  next_slide: j\n" ++
            "  prev_slide: k\n" ++
            "  first_slide: gg\n" ++
            "  last_slide: G\n" ++
            "  quit: q\n" ++
            "  help: \"?\"\n" ++
            "\n" ++
            "display:\n" ++
            "  min_width: 40\n" ++
            "  min_height: 10\n" ++
            "  truecolor: true\n" ++
            "  mouse: true\n" ++
            "  unicode: full\n" ++
            "\n" ++
            "export:\n" ++
            "  default_format: html\n" ++
            "  output_dir: ./output\n" ++
            "  include_notes: false\n" ++
            "\n" ++
            "executor:\n" ++
            "  timeout_seconds: 30\n" ++
            "  max_output_size: 1048576\n" ++
            "\n" ++
            "watch:\n" ++
            "  enabled: true\n" ++
            "  debounce_ms: 300\n";

        const file = try std.fs.cwd().createFile(path, .{});
        defer file.close();

        try file.writeAll(sample);
    }
};

/// Command-line configuration overrides
pub const ConfigOverrides = struct {
    theme: ?[]const u8 = null,
    loop: ?bool = null,
    auto_advance: ?u32 = null,
    timeout: ?u32 = null,

    pub fn hasOverrides(self: ConfigOverrides) bool {
        return self.theme != null or
            self.loop != null or
            self.auto_advance != null or
            self.timeout != null;
    }
};

test "ConfigManager defaults" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var manager = ConfigManager.init(allocator);
    defer manager.deinit();

    const config = manager.getConfig();

    try testing.expectEqualStrings("dark", config.theme.name);
    try testing.expect(config.display.truecolor);
    try testing.expectEqual(@as(u32, 30), config.executor.timeout_seconds);
}

test "ConfigManager loadString" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var manager = ConfigManager.init(allocator);
    defer manager.deinit();

    const yaml =
        "theme:\n" ++
        "  name: light\n" ++
        "presentation:\n" ++
        "  loop: true\n";

    try manager.loadString(yaml);

    const config = manager.getConfig();
    try testing.expectEqualStrings("light", config.theme.name);
    try testing.expect(config.presentation.loop);
    try testing.expect(manager.isDirty());
}

test "ConfigManager applyOverrides" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var manager = ConfigManager.init(allocator);
    defer manager.deinit();

    const overrides = ConfigOverrides{
        .theme = "monokai",
        .timeout = 120,
    };

    try manager.applyOverrides(overrides);

    const config = manager.getConfig();
    try testing.expectEqualStrings("monokai", config.theme.name);
    try testing.expectEqual(@as(u32, 120), config.executor.timeout_seconds);
}
