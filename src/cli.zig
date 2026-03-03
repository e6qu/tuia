//! Command-line interface parsing for TUIA
const std = @import("std");
const root = @import("root.zig");
const config = @import("config/root.zig");
const Config = config.Config;
const ConfigOverrides = config.ConfigOverrides;

/// CLI options parsed from command line
pub const CliOptions = struct {
    /// Input file path
    file_path: ?[]const u8 = null,

    /// Show help
    help: bool = false,

    /// Show version
    version: bool = false,

    /// Create sample config
    init_config: bool = false,

    /// Config file path
    config_file: ?[]const u8 = null,

    /// Theme override
    theme: ?[]const u8 = null,

    /// Loop presentation
    loop: ?bool = null,

    /// Auto-advance seconds
    auto_advance: ?u32 = null,

    /// Execution timeout
    timeout: ?u32 = null,

    /// Export format
    export_format: ?[]const u8 = null,

    /// Output directory for export
    output_dir: ?[]const u8 = null,

    /// Get config overrides for manager
    pub fn getOverrides(self: CliOptions) ConfigOverrides {
        return .{
            .theme = self.theme,
            .loop = self.loop,
            .auto_advance = self.auto_advance,
            .timeout = self.timeout,
        };
    }

    /// Check if any overrides are set
    pub fn hasOverrides(self: CliOptions) bool {
        return self.theme != null or
            self.loop != null or
            self.auto_advance != null or
            self.timeout != null;
    }

    /// Check if this is an export operation
    pub fn isExport(self: CliOptions) bool {
        return self.export_format != null;
    }
};

/// Parse command-line arguments
pub fn parseArgs(allocator: std.mem.Allocator) !CliOptions {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var options = CliOptions{};
    var i: usize = 1;

    while (i < args.len) : (i += 1) {
        const arg = args[i];

        // Handle flags
        if (std.mem.startsWith(u8, arg, "-")) {
            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                options.help = true;
            } else if (std.mem.eql(u8, arg, "-V") or std.mem.eql(u8, arg, "--version")) {
                options.version = true;
            } else if (std.mem.eql(u8, arg, "--init")) {
                options.init_config = true;
            } else if (std.mem.eql(u8, arg, "-c") or std.mem.eql(u8, arg, "--config")) {
                i += 1;
                if (i < args.len) {
                    options.config_file = try allocator.dupe(u8, args[i]);
                }
            } else if (std.mem.eql(u8, arg, "-t") or std.mem.eql(u8, arg, "--theme")) {
                i += 1;
                if (i < args.len) {
                    options.theme = try allocator.dupe(u8, args[i]);
                }
            } else if (std.mem.eql(u8, arg, "--loop")) {
                options.loop = true;
            } else if (std.mem.eql(u8, arg, "--auto-advance")) {
                i += 1;
                if (i < args.len) {
                    options.auto_advance = std.fmt.parseInt(u32, args[i], 10) catch null;
                }
            } else if (std.mem.eql(u8, arg, "--timeout")) {
                i += 1;
                if (i < args.len) {
                    options.timeout = std.fmt.parseInt(u32, args[i], 10) catch null;
                }
            } else if (std.mem.eql(u8, arg, "-e") or std.mem.eql(u8, arg, "--export")) {
                i += 1;
                if (i < args.len) {
                    options.export_format = try allocator.dupe(u8, args[i]);
                }
            } else if (std.mem.eql(u8, arg, "-o") or std.mem.eql(u8, arg, "--output")) {
                i += 1;
                if (i < args.len) {
                    options.output_dir = try allocator.dupe(u8, args[i]);
                }
            }
        } else {
            // Positional argument (file path)
            if (options.file_path == null) {
                options.file_path = try allocator.dupe(u8, arg);
            }
        }
    }

    return options;
}

/// Free allocated CLI options
pub fn deinitOptions(options: *CliOptions, allocator: std.mem.Allocator) void {
    if (options.file_path) |path| allocator.free(path);
    if (options.config_file) |path| allocator.free(path);
    if (options.theme) |theme| allocator.free(theme);
    if (options.export_format) |fmt| allocator.free(fmt);
    if (options.output_dir) |dir| allocator.free(dir);
}

/// Print help message
pub fn printHelp() void {
    std.debug.print(
        \\tuia {s} - Terminal presentation tool
        \\
        \\USAGE:
        \\  tuia [OPTIONS] <FILE>    Present a markdown file
        \\  tuia [OPTIONS]           Start with welcome screen
        \\
        \\OPTIONS:
        \\  -h, --help              Show this help message
        \\  -V, --version           Show version information
        \\  --init                  Create sample configuration file
        \\  -c, --config <FILE>     Use specific config file
        \\  -t, --theme <THEME>     Set theme (dark, light, or custom)
        \\  --loop                  Loop presentation
        \\  --auto-advance <SEC>    Auto-advance slides every N seconds
        \\  --timeout <SEC>         Code execution timeout (default: 30)
        \\  -e, --export <FORMAT>   Export to format (html, revealjs)
        \\  -o, --output <DIR>      Output directory for export
        \\
        \\COMMANDS (in presentation):
        \\  j, Down, Space, Right   Next slide
        \\  k, Up, Backspace, Left  Previous slide
        \\  g                       First slide
        \\  G                       Last slide
        \\  1-9                     Jump to slide number
        \\  ?, F1                   Show help
        \\  q, Ctrl+C               Quit
        \\
    , .{root.version});
}

/// Print version information
pub fn printVersion() void {
    std.debug.print("tuia {s}\n", .{root.version});
}

test "parseArgs basic" {
    const testing = std.testing;

    // Test with --help
    // Note: This would require mocking std.process.args
    // For now, just test the structure
    var options = CliOptions{ .help = true };
    try testing.expect(options.help);
    try testing.expect(!options.hasOverrides());
}

test "CliOptions getOverrides" {
    const testing = std.testing;

    var options = CliOptions{
        .theme = "light",
        .loop = true,
        .timeout = 60,
    };

    const overrides = options.getOverrides();
    try testing.expectEqualStrings("light", overrides.theme.?);
    try testing.expect(overrides.loop.?);
    try testing.expectEqual(@as(u32, 60), overrides.timeout.?);
}
