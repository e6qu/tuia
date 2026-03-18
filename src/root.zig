//! ZIGPRESENTERM - Terminal presentation tool

const std = @import("std");

// Module imports
pub const core = @import("core/root.zig");
pub const parser = @import("parser/root.zig");
pub const render = @import("render/root.zig");
pub const widgets = @import("widgets/root.zig");
pub const config = @import("config/root.zig");
pub const features = @import("features/root.zig");
pub const infra = @import("infra/root.zig");
pub const highlight = @import("highlight/root.zig");
pub const export_ = @import("export/root.zig");
pub const cli = @import("cli.zig");

// Test utilities (only available in test mode)
pub const test_utils = @import("test_utils.zig");

/// Library version
pub const version = "1.0.0";

// Tests — explicit imports to run inline tests without refAllDecls
// (refAllDecls causes exponential compile-time memory with complex generics)
test {
    _ = @import("core/root.zig");
    _ = @import("parser/root.zig");
    _ = @import("render/root.zig");
    _ = @import("widgets/root.zig");
    _ = @import("config/root.zig");
    _ = @import("features/root.zig");
    _ = @import("infra/root.zig");
    _ = @import("highlight/root.zig");
    _ = @import("export/root.zig");
    _ = @import("cli.zig");
    _ = @import("test_utils.zig");
}
