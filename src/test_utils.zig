//! Test utilities for slidz

const std = @import("std");

/// Golden file testing - compare output to expected
pub const Golden = struct {
    /// Directory for golden files
    const golden_dir = "tests/fixtures/golden/";

    /// Compare actual output to golden file
    /// Set ZIG_UPDATE_GOLDEN=1 to update golden files
    pub fn expectEqual(allocator: std.mem.Allocator, actual: []const u8, name: []const u8) !void {
        const path = try std.fs.path.join(allocator, &.{ golden_dir, name });
        defer allocator.free(path);

        // Check if we should update
        const update = std.process.hasEnvVarConstant("ZIG_UPDATE_GOLDEN");

        if (update) {
            // Ensure directory exists
            try std.fs.cwd().makePath(golden_dir);
            // Write golden file
            try std.fs.cwd().writeFile(.{
                .sub_path = path,
                .data = actual,
            });
            std.debug.print("Updated golden file: {s}\n", .{path});
            return;
        }

        // Read expected
        const expected = std.fs.cwd().readFileAlloc(allocator, path, 1024 * 1024) catch |err| {
            if (err == error.FileNotFound) {
                std.debug.print("Golden file not found: {s}\n", .{path});
                std.debug.print("Run with ZIG_UPDATE_GOLDEN=1 to create it.\n", .{});
                return error.GoldenFileNotFound;
            }
            return err;
        };
        defer allocator.free(expected);

        // Compare
        if (!std.mem.eql(u8, expected, actual)) {
            std.debug.print("Golden file mismatch: {s}\n", .{path});
            std.debug.print("Expected ({d} bytes):\n{s}\n", .{ expected.len, expected });
            std.debug.print("Actual ({d} bytes):\n{s}\n", .{ actual.len, actual });
            std.debug.print("Run with ZIG_UPDATE_GOLDEN=1 to update.\n", .{});
            return error.GoldenMismatch;
        }
    }
};

/// Memory testing utilities
pub const Memory = struct {
    /// Check for leaks using GPA - call this manually, not in defer
    pub fn expectNoLeaks(gpa: *std.heap.GeneralPurposeAllocator(.{})) !void {
        const leaked = gpa.detectLeaks();
        try std.testing.expect(!leaked);
    }
};

/// Test fixtures utilities
pub const Fixtures = struct {
    /// Directory for test fixtures
    const fixtures_dir = "tests/fixtures/";

    /// Load a fixture file
    pub fn load(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
        const path = try std.fs.path.join(allocator, &.{ fixtures_dir, name });
        defer allocator.free(path);

        return try std.fs.cwd().readFileAlloc(allocator, path, 1024 * 1024);
    }

    /// List all fixtures
    pub fn list(allocator: std.mem.Allocator) ![][]const u8 {
        var files = std.ArrayList([]const u8).init(allocator);

        var dir = try std.fs.cwd().openDir(fixtures_dir, .{ .iterate = true });
        defer dir.close();

        var it = dir.iterate();
        while (try it.next()) |entry| {
            if (entry.kind == .file) {
                try files.append(try allocator.dupe(u8, entry.name));
            }
        }

        return files.toOwnedSlice();
    }
};

/// Performance testing utilities
pub const Performance = struct {
    /// Measure function execution time
    pub fn measure(f: fn () anyerror!void) !u64 {
        const start = std.time.milliTimestamp();
        try f();
        return @intCast(std.time.milliTimestamp() - start);
    }

    /// Assert execution time is under limit
    pub fn expectUnder(f: fn () anyerror!void, limit_ms: u64) !void {
        const elapsed = try measure(f);
        if (elapsed > limit_ms) {
            std.debug.print("Performance check failed: {d}ms > {d}ms\n", .{ elapsed, limit_ms });
            return error.TooSlow;
        }
    }
};

// Tests
test "golden file basics" {
    // Just verify it compiles
    const allocator = std.testing.allocator;
    _ = allocator;
}

test "fixtures module loads" {
    const allocator = std.testing.allocator;
    _ = allocator;
}
