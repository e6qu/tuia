//! Configuration system for TUIA
const std = @import("std");

pub const Config = @import("Config.zig").Config;
pub const PresentationConfig = @import("Config.zig").PresentationConfig;
pub const ThemeConfig = @import("Config.zig").ThemeConfig;
pub const KeyConfig = @import("Config.zig").KeyConfig;
pub const DisplayConfig = @import("Config.zig").DisplayConfig;
pub const ExportConfig = @import("Config.zig").ExportConfig;
pub const ExecutorConfig = @import("Config.zig").ExecutorConfig;
pub const WatchConfig = @import("Config.zig").WatchConfig;
pub const AspectRatio = @import("Config.zig").AspectRatio;
pub const UnicodeMode = @import("Config.zig").UnicodeMode;
pub const ExportFormat = @import("Config.zig").ExportFormat;

pub const ConfigParser = @import("ConfigParser.zig").ConfigParser;
pub const ConfigManager = @import("ConfigManager.zig").ConfigManager;
pub const ConfigOverrides = @import("ConfigManager.zig").ConfigOverrides;

test {
    _ = @import("Config.zig");
    _ = @import("ConfigParser.zig");
    _ = @import("ConfigManager.zig");
}
