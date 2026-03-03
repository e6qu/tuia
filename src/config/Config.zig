//! Configuration data structures for TUIA
const std = @import("std");

/// User configuration root
pub const Config = struct {
    /// Presentation settings
    presentation: PresentationConfig = .{},

    /// Theme settings
    theme: ThemeConfig = .{},

    /// Key bindings
    keys: KeyConfig = .{},

    /// Display settings
    display: DisplayConfig = .{},

    /// Export settings
    export_config: ExportConfig = .{},

    /// Code execution settings
    executor: ExecutorConfig = .{},

    /// File watching settings
    watch: WatchConfig = .{},

    const Self = @This();

    /// Merge another config into this one (other takes precedence)
    pub fn merge(self: *Self, other: Config) void {
        self.presentation.merge(other.presentation);
        self.theme.merge(other.theme);
        self.keys.merge(other.keys);
        self.display.merge(other.display);
        self.export_config.merge(other.export_config);
        self.executor.merge(other.executor);
        self.watch.merge(other.watch);
    }

    /// Create a copy with allocator
    pub fn clone(self: Self, allocator: std.mem.Allocator) !Config {
        var copy = self;
        copy.theme.name = try allocator.dupe(u8, self.theme.name);
        return copy;
    }

    /// Free allocated memory (for values that were allocated from parsing)
    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        // Free theme name if it's not the default static string
        // We check by comparing pointer values - if different from "dark" literal, it was allocated
        const default_name = "dark";
        if (self.theme.name.ptr != default_name.ptr) {
            allocator.free(self.theme.name);
        }
        // Free custom theme path if set
        if (self.theme.custom_theme_path) |path| {
            allocator.free(path);
        }
        // Note: export_config.output_dir is not typically allocated during parsing
    }

    /// Get default configuration
    pub fn defaults() Config {
        return .{};
    }
};

/// Presentation behavior settings
pub const PresentationConfig = struct {
    /// Auto-advance slides (0 = disabled)
    auto_advance_seconds: u32 = 0,

    /// Loop presentation
    loop: bool = false,

    /// Show slide numbers
    show_slide_numbers: bool = true,

    /// Show total slide count
    show_total_slides: bool = true,

    /// Default slide aspect ratio
    aspect_ratio: AspectRatio = .ratio_16_9,

    /// Merge with other config
    pub fn merge(self: *PresentationConfig, other: PresentationConfig) void {
        if (other.auto_advance_seconds != 0) self.auto_advance_seconds = other.auto_advance_seconds;
        if (other.loop) self.loop = true;
        if (!other.show_slide_numbers) self.show_slide_numbers = false;
        if (!other.show_total_slides) self.show_total_slides = false;
        if (other.aspect_ratio != .auto) self.aspect_ratio = other.aspect_ratio;
    }
};

/// Aspect ratio options
pub const AspectRatio = enum {
    auto,
    ratio_4_3,
    ratio_16_9,
    ratio_16_10,
    ratio_21_9,

    /// Parse aspect ratio from string
    pub fn fromString(str: []const u8) AspectRatio {
        if (std.mem.eql(u8, str, "4:3")) return .ratio_4_3;
        if (std.mem.eql(u8, str, "16:9")) return .ratio_16_9;
        if (std.mem.eql(u8, str, "16:10")) return .ratio_16_10;
        if (std.mem.eql(u8, str, "21:9")) return .ratio_21_9;
        return .auto;
    }
};

/// Theme configuration
pub const ThemeConfig = struct {
    /// Theme name ("dark", "light", or custom)
    name: []const u8 = "dark",

    /// Custom theme file path (optional)
    custom_theme_path: ?[]const u8 = null,

    /// Use terminal background
    use_terminal_background: bool = true,

    /// Merge with other config
    pub fn merge(self: *ThemeConfig, other: ThemeConfig) void {
        if (other.name.len > 0 and !std.mem.eql(u8, other.name, "dark")) {
            self.name = other.name;
        }
        if (other.custom_theme_path) |path| {
            self.custom_theme_path = path;
        }
        if (!other.use_terminal_background) {
            self.use_terminal_background = false;
        }
    }
};

/// Key binding configuration
pub const KeyConfig = struct {
    /// Navigation keys
    next_slide: []const u8 = "j",
    prev_slide: []const u8 = "k",
    first_slide: []const u8 = "gg",
    last_slide: []const u8 = "G",

    /// Action keys
    quit: []const u8 = "q",
    help: []const u8 = "?",

    /// Merge with other config
    pub fn merge(self: *KeyConfig, other: KeyConfig) void {
        if (other.next_slide.len > 0) self.next_slide = other.next_slide;
        if (other.prev_slide.len > 0) self.prev_slide = other.prev_slide;
        if (other.first_slide.len > 0) self.first_slide = other.first_slide;
        if (other.last_slide.len > 0) self.last_slide = other.last_slide;
        if (other.quit.len > 0) self.quit = other.quit;
        if (other.help.len > 0) self.help = other.help;
    }
};

/// Display settings
pub const DisplayConfig = struct {
    /// Minimum terminal width
    min_width: u16 = 40,

    /// Minimum terminal height
    min_height: u16 = 10,

    /// Enable truecolor support
    truecolor: bool = true,

    /// Enable mouse support
    mouse: bool = true,

    /// Unicode support level
    unicode: UnicodeMode = .full,

    /// Merge with other config
    pub fn merge(self: *DisplayConfig, other: DisplayConfig) void {
        if (other.min_width > 0) self.min_width = other.min_width;
        if (other.min_height > 0) self.min_height = other.min_height;
        if (!other.truecolor) self.truecolor = false;
        if (!other.mouse) self.mouse = false;
        if (@intFromEnum(other.unicode) != 0) self.unicode = other.unicode;
    }
};

/// Unicode support modes
pub const UnicodeMode = enum {
    /// No unicode, ASCII only
    ascii,
    /// Basic unicode (box drawing)
    basic,
    /// Full unicode support
    full,
};

/// Export settings
pub const ExportConfig = struct {
    /// Default export format
    default_format: ExportFormat = .html,

    /// Output directory
    output_dir: []const u8 = "./output",

    /// Include speaker notes
    include_notes: bool = false,

    /// Self-contained output
    self_contained: bool = true,

    /// Merge with other config
    pub fn merge(self: *ExportConfig, other: ExportConfig) void {
        if (@intFromEnum(other.default_format) != 0) {
            self.default_format = other.default_format;
        }
        if (other.output_dir.len > 0) self.output_dir = other.output_dir;
        if (other.include_notes) self.include_notes = true;
        if (!other.self_contained) self.self_contained = false;
    }
};

/// Export format options
pub const ExportFormat = enum {
    html,
    pdf,
    revealjs,
};

/// Code execution settings
pub const ExecutorConfig = struct {
    /// Default timeout in seconds
    timeout_seconds: u32 = 30,

    /// Maximum output size in bytes
    max_output_size: usize = 1024 * 1024,

    /// Allowed languages (empty = all)
    allowed_languages: []const []const u8 = &.{},

    /// Merge with other config
    pub fn merge(self: *ExecutorConfig, other: ExecutorConfig) void {
        if (other.timeout_seconds != 30) self.timeout_seconds = other.timeout_seconds;
        if (other.max_output_size != 1024 * 1024) {
            self.max_output_size = other.max_output_size;
        }
        if (other.allowed_languages.len > 0) {
            self.allowed_languages = other.allowed_languages;
        }
    }
};

/// File watching settings
pub const WatchConfig = struct {
    /// Enable file watching
    enabled: bool = true,

    /// Debounce interval in milliseconds
    debounce_ms: u32 = 300,

    /// Ignore patterns
    ignore_patterns: []const []const u8 = &.{ ".git", "zig-cache", "zig-out" },

    /// Merge with other config
    pub fn merge(self: *WatchConfig, other: WatchConfig) void {
        if (!other.enabled) self.enabled = false;
        if (other.debounce_ms != 300) self.debounce_ms = other.debounce_ms;
        if (other.ignore_patterns.len > 0) {
            self.ignore_patterns = other.ignore_patterns;
        }
    }
};

test "Config defaults" {
    const testing = std.testing;

    const config = Config.defaults();

    try testing.expectEqual(@as(u32, 0), config.presentation.auto_advance_seconds);
    try testing.expect(config.presentation.show_slide_numbers);
    try testing.expectEqualStrings("dark", config.theme.name);
    try testing.expect(config.display.truecolor);
    try testing.expectEqual(@as(u32, 30), config.executor.timeout_seconds);
    try testing.expect(config.watch.enabled);
}

test "Config merge" {
    const testing = std.testing;

    var base = Config.defaults();
    const overlay = Config{
        .presentation = .{ .loop = true, .show_slide_numbers = false },
        .theme = .{ .name = "light" },
        .executor = .{ .timeout_seconds = 60 },
    };

    base.merge(overlay);

    try testing.expect(base.presentation.loop);
    try testing.expect(!base.presentation.show_slide_numbers);
    try testing.expectEqualStrings("light", base.theme.name);
    try testing.expectEqual(@as(u32, 60), base.executor.timeout_seconds);
}
