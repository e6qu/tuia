const std = @import("std");
const App = @import("App.zig").App;
const root = @import("root.zig");

pub fn main() !void {
    // Parse CLI args first
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    // Handle CLI options
    if (args.len > 1) {
        const arg = args[1];
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            std.debug.print(
                \\tuia {s} - Terminal presentation tool
                \\
                \\USAGE:
                \\  tuia [OPTIONS] <FILE>    Present a markdown file
                \\  tuia [OPTIONS]           Start with welcome screen
                \\
                \\OPTIONS:
                \\  -h, --help      Show this help message
                \\  -V, --version   Show version information
                \\
                \\COMMANDS (in presentation):
                \\  j, k            Next/previous slide
                \\  e               Execute code block
                \\  E               Toggle execution output
                \\  q, Ctrl+C       Quit
                \\
            , .{root.version});
            return;
        }
        if (std.mem.eql(u8, arg, "-V") or std.mem.eql(u8, arg, "--version")) {
            std.debug.print("tuia {s}\n", .{root.version});
            return;
        }
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.detectLeaks()) {
            std.log.err("Memory leaks detected!", .{});
        }
    }
    const allocator = gpa.allocator();

    // Initialize app
    var app = try App.init(allocator);
    defer app.deinit();

    // Load presentation file if provided
    if (args.len > 1) {
        const file_path = args[1];
        app.loadPresentation(file_path) catch |err| {
            std.debug.print("Error loading presentation: {s}\n", .{@errorName(err)});
            std.process.exit(1);
        };
    }

    // Run the app
    try app.run();
}
