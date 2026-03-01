const std = @import("std");

/// Application entry point
pub fn main() !void {
    // Initialize allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.detectLeaks();
        if (leaked) {
            std.log.err("Memory leaks detected!", .{});
        }
    }
    const allocator = gpa.allocator();

    // Parse command line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // For now, just show help or version
    if (args.len < 2) {
        try showHelp();
        return;
    }

    const command = args[1];

    if (std.mem.eql(u8, command, "--help") or std.mem.eql(u8, command, "-h")) {
        try showHelp();
        return;
    }

    if (std.mem.eql(u8, command, "--version") or std.mem.eql(u8, command, "-V")) {
        try showVersion();
        return;
    }

    // Treat as file path and try to read
    const file_path = command;
    try readFile(allocator, file_path);
}

/// Show help message
fn showHelp() !void {
    const help =
        \\slidz 0.1.0
        \\Terminal presentation tool
        \\
        \\USAGE:
        \\    slidz [OPTIONS] <FILE>
        \\    slidz --help
        \\    slidz --version
        \\
        \\ARGS:
        \\    <FILE>    Presentation file to display
        \\
        \\OPTIONS:
        \\    -h, --help       Print help information
        \\    -V, --version    Print version information
        \\
    ;
    try std.fs.File.stdout().writeAll(help);
}

/// Show version
fn showVersion() !void {
    try std.fs.File.stdout().writeAll("slidz 0.1.0\n");
}

/// Read and display file info
fn readFile(allocator: std.mem.Allocator, file_path: []const u8) !void {
    const file = std.fs.cwd().openFile(file_path, .{}) catch |err| {
        std.log.err("Failed to open file '{s}': {s}", .{ file_path, @errorName(err) });
        return err;
    };
    defer file.close();

    const content = file.readToEndAlloc(allocator, 1024 * 1024) catch |err| {
        std.log.err("Failed to read file: {s}", .{@errorName(err)});
        return err;
    };
    defer allocator.free(content);

    std.log.info("Loaded: {s} ({d} bytes)", .{ file_path, content.len });
    std.log.info("Content preview:\n{s}", .{content[0..@min(content.len, 200)]});
}

// Tests for main module
test "sanity check" {
    try std.testing.expect(true);
}
