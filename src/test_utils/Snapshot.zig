//! Snapshot testing utilities for TUIA
const std = @import("std");

/// Snapshot testing error
pub const SnapshotError = error{
    SnapshotMismatch,
    SnapshotNotFound,
    InvalidSnapshot,
};

/// Options for snapshot comparison
pub const SnapshotOptions = struct {
    /// Update snapshots automatically
    update: bool = false,

    /// Snapshot file extension
    extension: []const u8 = ".snap",

    /// Directory to store snapshots
    snapshot_dir: []const u8 = "tests/__snapshots__",
};

/// Compare output against a stored snapshot
pub fn expectEqual(
    allocator: std.mem.Allocator,
    actual: []const u8,
    snapshot_name: []const u8,
    options: SnapshotOptions,
) !void {
    const snapshot_path = try std.fs.path.join(allocator, &.{
        options.snapshot_dir,
        snapshot_name,
    });
    defer allocator.free(snapshot_path);

    // Check if update mode is enabled via environment variable
    const update_env = std.posix.getenv("ZIG_UPDATE_SNAPSHOTS");
    const should_update = options.update or (update_env != null);

    if (should_update) {
        // Create directory if needed
        const dir_path = std.fs.path.dirname(snapshot_path) orelse ".";
        try std.fs.cwd().makePath(dir_path);

        // Write snapshot
        try std.fs.cwd().writeFile(.{
            .sub_path = snapshot_path,
            .data = actual,
        });

        std.debug.print("Updated snapshot: {s}\n", .{snapshot_name});
        return;
    }

    // Read existing snapshot
    const expected = std.fs.cwd().readFileAlloc(allocator, snapshot_path, 1024 * 1024) catch |err| {
        if (err == error.FileNotFound) {
            std.debug.print("\n\nSnapshot not found: {s}\nRun with ZIG_UPDATE_SNAPSHOTS=1 to create it.\n\n", .{snapshot_name});
            return SnapshotError.SnapshotNotFound;
        }
        return err;
    };
    defer allocator.free(expected);

    // Compare
    if (!std.mem.eql(u8, expected, actual)) {
        std.debug.print("\n\nSnapshot mismatch: {s}\n\nExpected:\n{s}\n\nActual:\n{s}\n\nRun with ZIG_UPDATE_SNAPSHOTS=1 to update.\n\n", .{ snapshot_name, expected, actual });
        return SnapshotError.SnapshotMismatch;
    }
}

/// Create a snapshot name from test name and parameters
pub fn makeName(allocator: std.mem.Allocator, base: []const u8, params: []const []const u8) ![]const u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    try result.appendSlice(base);

    for (params) |param| {
        try result.append('_');
        try result.appendSlice(param);
    }

    try result.appendSlice(".snap");

    return result.toOwnedSlice();
}
