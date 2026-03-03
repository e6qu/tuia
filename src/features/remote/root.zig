//! Remote control module for presentations
const std = @import("std");

pub const RemoteServer = @import("RemoteServer.zig").RemoteServer;

test {
    std.testing.refAllDecls(@This());
}
