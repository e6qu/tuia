const std = @import("std");
const App = @import("App.zig").App;
const cli = @import("cli.zig");
const export_cmd = @import("export/Command.zig");
const root = @import("root.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.detectLeaks()) {
            std.log.err("Memory leaks detected!", .{});
        }
    }
    const allocator = gpa.allocator();

    var options = try cli.parseArgs(allocator);
    defer cli.deinitOptions(&options, allocator);

    if (options.help) {
        cli.printHelp();
        export_cmd.printExportHelp();
        return;
    }

    if (options.version) {
        cli.printVersion();
        return;
    }

    if (options.isExport()) {
        const file_path = options.file_path orelse {
            std.debug.print("Error: Export requires a file path\n", .{});
            std.process.exit(1);
        };
        const format = options.export_format.?;

        export_cmd.handleExport(allocator, file_path, format, options.output_dir) catch |err| {
            std.debug.print("Export failed: {s}\n", .{@errorName(err)});
            std.process.exit(1);
        };
        return;
    }

    var app = try App.init(allocator);
    defer app.deinit();

    // Load presentation file if provided
    if (options.file_path) |file_path| {
        app.loadPresentation(file_path) catch |err| {
            std.debug.print("Error loading presentation: {s}\n", .{@errorName(err)});
            std.process.exit(1);
        };
    }

    try app.run();
}
