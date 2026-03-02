//! Output handling for code execution
const std = @import("std");

/// Output stream type
pub const StreamType = enum {
    stdout,
    stderr,
};

/// Output line with metadata
pub const OutputLine = struct {
    content: []const u8,
    stream: StreamType,
    timestamp_ms: i64,

    const Self = @This();

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        allocator.free(self.content);
    }
};

/// OutputCapture collects and processes execution output
pub const OutputCapture = struct {
    allocator: std.mem.Allocator,
    lines: std.ArrayList(OutputLine),
    max_lines: usize,
    max_line_length: usize,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, max_lines: usize, max_line_length: usize) Self {
        return .{
            .allocator = allocator,
            .lines = .empty,
            .max_lines = max_lines,
            .max_line_length = max_line_length,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.lines.items) |line| {
            line.deinit(self.allocator);
        }
        self.lines.deinit(self.allocator);
    }

    /// Add raw output data
    pub fn addOutput(self: *Self, data: []const u8, stream: StreamType) !void {
        // Split into lines
        var line_iter = std.mem.splitScalar(u8, data, '\n');
        const now = std.time.milliTimestamp();

        while (line_iter.next()) |line| {
            // Skip empty last line
            if (line.len == 0 and line_iter.rest().len == 0) break;

            // Truncate if too long
            const content = if (line.len > self.max_line_length)
                try self.allocator.dupe(u8, line[0..self.max_line_length])
            else
                try self.allocator.dupe(u8, line);

            const output_line = OutputLine{
                .content = content,
                .stream = stream,
                .timestamp_ms = now,
            };

            try self.lines.append(self.allocator, output_line);

            // Remove oldest if over limit
            if (self.lines.items.len > self.max_lines) {
                const removed = self.lines.orderedRemove(0);
                removed.deinit(self.allocator);
            }
        }
    }

    /// Get all lines
    pub fn getLines(self: Self) []const OutputLine {
        return self.lines.items;
    }

    /// Get lines filtered by stream
    pub fn getLinesByStream(self: Self, allocator: std.mem.Allocator, stream: StreamType) ![]OutputLine {
        var filtered: std.ArrayList(OutputLine) = .empty;
        defer filtered.deinit(allocator);

        for (self.lines.items) |line| {
            if (line.stream == stream) {
                try filtered.append(allocator, line);
            }
        }

        return filtered.toOwnedSlice();
    }

    /// Get combined output as single string
    pub fn getCombinedOutput(self: Self, allocator: std.mem.Allocator) ![]const u8 {
        if (self.lines.items.len == 0) {
            return allocator.dupe(u8, "");
        }

        // Calculate total size
        var total_size: usize = 0;
        for (self.lines.items) |line| {
            total_size += line.content.len + 1; // +1 for newline
        }

        var result = std.ArrayList(u8).init(allocator);
        defer result.deinit();
        try result.ensureTotalCapacity(total_size);

        for (self.lines.items) |line| {
            try result.appendSlice(line.content);
            try result.append('\n');
        }

        return result.toOwnedSlice();
    }

    /// Get statistics
    pub fn getStats(self: Self) Stats {
        var stats: Stats = .{};

        for (self.lines.items) |line| {
            stats.total_lines += 1;
            stats.total_bytes += line.content.len;

            switch (line.stream) {
                .stdout => stats.stdout_lines += 1,
                .stderr => stats.stderr_lines += 1,
            }
        }

        return stats;
    }

    /// Clear all output
    pub fn clear(self: *Self) void {
        for (self.lines.items) |line| {
            line.deinit(self.allocator);
        }
        self.lines.clearRetainingCapacity();
    }

    /// Format output for display with colors
    pub fn formatForDisplay(
        self: Self,
        allocator: std.mem.Allocator,
        show_line_numbers: bool,
        highlight_errors: bool,
    ) ![]const u8 {
        if (self.lines.items.len == 0) {
            return allocator.dupe(u8, "(no output)");
        }

        var result = std.ArrayList(u8).init(allocator);
        defer result.deinit();

        for (self.lines.items, 1..) |line, i| {
            if (show_line_numbers) {
                const prefix = try std.fmt.allocPrint(allocator, "{d:>4} | ", .{i});
                defer allocator.free(prefix);
                try result.appendSlice(prefix);
            }

            // Add color codes based on stream
            if (highlight_errors) {
                switch (line.stream) {
                    .stdout => {},
                    .stderr => try result.appendSlice("\x1b[31m"), // Red for stderr
                }
            }

            try result.appendSlice(line.content);

            if (highlight_errors and line.stream == .stderr) {
                try result.appendSlice("\x1b[0m"); // Reset
            }

            try result.append('\n');
        }

        return result.toOwnedSlice();
    }
};

/// Output statistics
pub const Stats = struct {
    total_lines: usize = 0,
    total_bytes: usize = 0,
    stdout_lines: usize = 0,
    stderr_lines: usize = 0,
};

/// Execution output widget for TUI display
pub const ExecutionOutputWidget = struct {
    allocator: std.mem.Allocator,
    capture: OutputCapture,
    scroll_offset: usize = 0,
    show_stderr: bool = true,
    show_line_numbers: bool = true,
    follow_output: bool = true,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, max_lines: usize) Self {
        return .{
            .allocator = allocator,
            .capture = OutputCapture.init(allocator, max_lines, 1024),
        };
    }

    pub fn deinit(self: *Self) void {
        self.capture.deinit();
    }

    /// Add output from execution result
    pub fn addExecutionResult(self: *Self, stdout: []const u8, stderr: []const u8) !void {
        if (stdout.len > 0) {
            try self.capture.addOutput(stdout, .stdout);
        }
        if (stderr.len > 0 and self.show_stderr) {
            try self.capture.addOutput(stderr, .stderr);
        }

        if (self.follow_output) {
            self.scrollToBottom();
        }
    }

    /// Scroll to top
    pub fn scrollToTop(self: *Self) void {
        self.scroll_offset = 0;
    }

    /// Scroll to bottom
    pub fn scrollToBottom(self: *Self) void {
        const lines = self.capture.getLines();
        if (lines.len > 0) {
            self.scroll_offset = lines.len - 1;
        }
    }

    /// Scroll up
    pub fn scrollUp(self: *Self, lines: usize) void {
        if (self.scroll_offset >= lines) {
            self.scroll_offset -= lines;
        } else {
            self.scroll_offset = 0;
        }
    }

    /// Scroll down
    pub fn scrollDown(self: *Self, lines: usize) void {
        const total_lines = self.capture.getLines().len;
        self.scroll_offset = @min(self.scroll_offset + lines, if (total_lines > 0) total_lines - 1 else 0);
    }

    /// Page up
    pub fn pageUp(self: *Self, page_size: usize) void {
        self.scrollUp(page_size);
    }

    /// Page down
    pub fn pageDown(self: *Self, page_size: usize) void {
        self.scrollDown(page_size);
    }

    /// Toggle stderr visibility
    pub fn toggleStderr(self: *Self) void {
        self.show_stderr = !self.show_stderr;
    }

    /// Toggle line numbers
    pub fn toggleLineNumbers(self: *Self) void {
        self.show_line_numbers = !self.show_line_numbers;
    }

    /// Get visible lines for display
    pub fn getVisibleLines(self: Self, height: usize) []const OutputLine {
        const lines = self.capture.getLines();
        if (lines.len == 0) return &[_]OutputLine{};

        const start = @min(self.scroll_offset, lines.len);
        const end = @min(start + height, lines.len);

        return lines[start..end];
    }

    /// Clear output
    pub fn clear(self: *Self) void {
        self.capture.clear();
        self.scroll_offset = 0;
    }

    /// Get display info for status bar
    pub fn getStatusInfo(self: Self, allocator: std.mem.Allocator) ![]const u8 {
        const stats = self.capture.getStats();
        return try std.fmt.allocPrint(
            allocator,
            "Lines: {d} | Stdout: {d} | Stderr: {d} | Pos: {d}/{d}",
            .{
                stats.total_lines,
                stats.stdout_lines,
                stats.stderr_lines,
                self.scroll_offset + 1,
                stats.total_lines,
            },
        );
    }
};

test "OutputCapture basic" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var capture = OutputCapture.init(allocator, 100, 1000);
    defer capture.deinit();

    try capture.addOutput("line1\nline2\n", .stdout);
    try capture.addOutput("error1\n", .stderr);

    try testing.expectEqual(@as(usize, 3), capture.getLines().len);

    const stats = capture.getStats();
    try testing.expectEqual(@as(usize, 2), stats.stdout_lines);
    try testing.expectEqual(@as(usize, 1), stats.stderr_lines);
}

test "OutputCapture limit" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var capture = OutputCapture.init(allocator, 2, 1000);
    defer capture.deinit();

    try capture.addOutput("line1\n", .stdout);
    try capture.addOutput("line2\n", .stdout);
    try capture.addOutput("line3\n", .stdout);

    try testing.expectEqual(@as(usize, 2), capture.getLines().len);
    try testing.expectEqualStrings("line2", capture.getLines()[0].content);
    try testing.expectEqualStrings("line3", capture.getLines()[1].content);
}

test "ExecutionOutputWidget scroll" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var widget = ExecutionOutputWidget.init(allocator, 100);
    defer widget.deinit();

    try widget.capture.addOutput("line1\nline2\nline3\nline4\nline5\n", .stdout);

    widget.scrollToTop();
    try testing.expectEqual(@as(usize, 0), widget.scroll_offset);

    widget.scrollDown(2);
    try testing.expectEqual(@as(usize, 2), widget.scroll_offset);

    widget.scrollUp(1);
    try testing.expectEqual(@as(usize, 1), widget.scroll_offset);

    widget.scrollToBottom();
    try testing.expectEqual(@as(usize, 4), widget.scroll_offset);
}
