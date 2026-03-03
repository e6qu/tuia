//! Custom Zig linter for TUIA
//! Detects common bug patterns that Semgrep might miss

const std = @import("std");

const Finding = struct {
    file: []const u8,
    line: u32,
    column: u32,
    message: []const u8,
    severity: Severity,

    const Severity = enum {
        error,
        warning,
        info,
    };
};

const Linter = struct {
    allocator: std.mem.Allocator,
    findings: std.ArrayList(Finding),

    fn init(allocator: std.mem.Allocator) Linter {
        return .{
            .allocator = allocator,
            .findings = std.ArrayList(Finding).init(allocator),
        };
    }

    fn deinit(self: *Linter) void {
        self.findings.deinit();
    }

    fn lintFile(self: *Linter, file_path: []const u8, source: []const u8) !void {
        // Simple pattern-based linting (AST-based would require zig's internal parser)
        try self.checkBoundsIssues(file_path, source);
        try self.checkIntegerSafety(file_path, source);
        try self.checkMemorySafety(file_path, source);
        try self.checkNullSafety(file_path, source);
    }

    fn checkBoundsIssues(self: *Linter, file_path: []const u8, source: []const u8) !void {
        var lines = std.mem.split(u8, source, "\n");
        var line_num: u32 = 0;

        while (lines.next()) |line| : (line_num += 1) {
            // Check for array[index] pattern without bounds check comment
            if (std.mem.indexOf(u8, line, "[") != null and
                std.mem.indexOf(u8, line, "]") != null)
            {
                // Skip if has bounds check comment
                if (std.mem.indexOf(u8, line, "// bounds-checked") != null) continue;
                if (std.mem.indexOf(u8, line, "// checked") != null) continue;

                // Check for common patterns that suggest bounds checking
                const has_len_check = std.mem.indexOf(u8, line, ".len") != null or
                    std.mem.indexOf(u8, line, "> ") != null or
                    std.mem.indexOf(u8, line, ">= ") != null;

                if (!has_len_check) {
                    // This is a heuristic - would need AST for accurate check
                    // For now, just flag potential issues
                }
            }
        }
    }

    fn checkIntegerSafety(self: *Linter, file_path: []const u8, source: []const u8) !void {
        var lines = std.mem.split(u8, source, "\n");
        var line_num: u32 = 0;

        while (lines.next()) |line| : (line_num += 1) {
            // Check for total_slides - 1 pattern
            if (std.mem.indexOf(u8, line, "total_slides") != null and
                std.mem.indexOf(u8, line, "- 1") != null)
            {
                // Check if there's a guard
                var has_guard = false;
                // Look at previous 3 lines for guard
                // (simplified - would need proper multi-line analysis)

                if (!has_guard) {
                    try self.findings.append(.{
                        .file = file_path,
                        .line = line_num,
                        .column = 0,
                        .message = "Potential integer underflow: total_slides - 1 without zero check",
                        .severity = .error,
                    });
                }
            }

            // Check for division without zero check
            if (std.mem.indexOf(u8, line, " / ") != null) {
                // Skip if there's a comment indicating check
                if (std.mem.indexOf(u8, line, "// div-checked") != null) continue;

                // Would need more context for accurate detection
            }
        }
    }

    fn checkMemorySafety(self: *Linter, file_path: []const u8, source: []const u8) !void {
        var lines = std.mem.split(u8, source, "\n");
        var line_num: u32 = 0;

        while (lines.next()) |line| : (line_num += 1) {
            // Check for allocator.free("")
            if (std.mem.indexOf(u8, line, "allocator.free(") != null or
                std.mem.indexOf(u8, line, ".free(") != null)
            {
                if (std.mem.indexOf(u8, line, "\"") != null) {
                    try self.findings.append(.{
                        .file = file_path,
                        .line = line_num,
                        .column = 0,
                        .message = "Potential free of string literal - verify this is heap-allocated",
                        .severity = .error,
                    });
                }
            }

            // Check for try allocator.create without errdefer
            if (std.mem.indexOf(u8, line, "try ") != null and
                std.mem.indexOf(u8, line, "allocator.create") != null)
            {
                // Look for errdefer in next few lines
                // (simplified check)
            }
        }
    }

    fn checkNullSafety(self: *Linter, file_path: []const u8, source: []const u8) !void {
        var lines = std.mem.split(u8, source, "\n");
        var line_num: u32 = 0;

        while (lines.next()) |line| : (line_num += 1) {
            // Check for .? unwrap
            if (std.mem.indexOf(u8, line, ".?") != null) {
                // Skip if in if condition
                if (std.mem.indexOf(u8, line, "if (") != null) continue;

                try self.findings.append(.{
                    .file = file_path,
                    .line = line_num,
                    .column = 0,
                    .message = "Optional unwrapped with .? - consider using 'if (opt) |value|' for safety",
                    .severity = .warning,
                });
            }
        }
    }

    fn report(self: *Linter) void {
        const stderr = std.io.getStdErr().writer();

        var errors: u32 = 0;
        var warnings: u32 = 0;

        for (self.findings.items) |finding| {
            const severity_str = switch (finding.severity) {
                .error => "ERROR",
                .warning => "WARNING",
                .info => "INFO",
            };

            stderr.print("{s}:{d}:{d}: {s}: {s}\n", .{
                finding.file,
                finding.line + 1,
                finding.column + 1,
                severity_str,
                finding.message,
            }) catch {};

            switch (finding.severity) {
                .error => errors += 1,
                .warning => warnings += 1,
                .info => {},
            }
        }

        stderr.print("\nTotal: {d} errors, {d} warnings\n", .{ errors, warnings }) catch {};
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: ziglint <source-directory>\n", .{});
        std.process.exit(1);
    }

    const source_dir = args[1];

    var linter = Linter.init(allocator);
    defer linter.deinit();

    var dir = try std.fs.cwd().openDir(source_dir, .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (!std.mem.endsWith(u8, entry.path, ".zig")) continue;

        const source = std.fs.cwd().readFileAlloc(allocator, entry.path, 1 << 20) catch |err| {
            std.log.warn("Could not read {s}: {s}", .{ entry.path, @errorName(err) });
            continue;
        };
        defer allocator.free(source);

        try linter.lintFile(entry.path, source);
    }

    linter.report();

    // Exit with error code if there are errors
    for (linter.findings.items) |finding| {
        if (finding.severity == .error) {
            std.process.exit(1);
        }
    }
}
