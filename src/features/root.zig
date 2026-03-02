//! Feature modules
const std = @import("std");

pub const images = @import("images/root.zig");

test {
    std.testing.refAllDecls(@This());
}
