//! Widget for displaying code execution status and results
const std = @import("std");
const tui = @import("../tui/root.zig");
const ExecutionResult = @import("../features/executor/root.zig").ExecutionResult;
const ExecutionOutputWidget = @import("../features/executor/root.zig").ExecutionOutputWidget;

/// ExecutionWidget displays code execution status and results
pub const ExecutionWidget = struct {
    allocator: std.mem.Allocator,
    output_widget: ExecutionOutputWidget,

    /// Current execution state
    state: State = .idle,
    /// Language being executed
    language: ?[]const u8 = null,
    /// Code being executed
    code: ?[]const u8 = null,
    /// Last execution result
    last_result: ?ExecutionResult = null,
    /// Whether widget is visible
    visible: bool = false,
    /// Window height percentage (0-100)
    height_percent: u8 = 40,

    const Self = @This();

    pub const State = enum {
        /// No execution in progress
        idle,
        /// Executing code
        executing,
        /// Execution completed successfully
        success,
        /// Execution failed
        failed,
        /// Execution timed out
        timeout,
        /// Language not available
        language_not_available,
    };

    /// Initialize execution widget
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .output_widget = ExecutionOutputWidget.init(allocator, 1000),
        };
    }

    /// Clean up
    pub fn deinit(self: *Self) void {
        self.output_widget.deinit();
        if (self.language) |l| {
            self.allocator.free(l);
        }
        if (self.code) |c| {
            self.allocator.free(c);
        }
        if (self.last_result) |*r| {
            r.deinit(self.allocator);
        }
    }

    /// Start executing code
    pub fn startExecution(self: *Self, language: []const u8, code: []const u8) !void {
        // Clean up previous
        if (self.language) |l| {
            self.allocator.free(l);
        }
        if (self.code) |c| {
            self.allocator.free(c);
        }
        if (self.last_result) |*r| {
            r.deinit(self.allocator);
            self.last_result = null;
        }

        self.language = try self.allocator.dupe(u8, language);
        self.code = try self.allocator.dupe(u8, code);
        self.state = .executing;
        self.visible = true;
        self.output_widget.clear();
    }

    /// Set execution result
    pub fn setResult(self: *Self, result: ExecutionResult) !void {
        if (self.last_result) |*r| {
            r.deinit(self.allocator);
        }
        self.last_result = result;

        // Update state based on result
        if (result.killed) {
            self.state = .timeout;
        } else if (result.exit_code == 0) {
            self.state = .success;
        } else {
            self.state = .failed;
        }

        // Add output to widget
        try self.output_widget.addExecutionResult(result.stdout, result.stderr);
    }

    /// Set language not available error
    pub fn setLanguageNotAvailable(self: *Self) void {
        self.state = .language_not_available;
        self.visible = true;
    }

    /// Toggle visibility
    pub fn toggle(self: *Self) void {
        self.visible = !self.visible;
    }

    /// Show widget
    pub fn show(self: *Self) void {
        self.visible = true;
    }

    /// Hide widget
    pub fn hide(self: *Self) void {
        self.visible = false;
    }

    /// Check if visible
    pub fn isVisible(self: Self) bool {
        return self.visible;
    }

    /// Get state
    pub fn getState(self: Self) State {
        return self.state;
    }

    /// Check if currently executing
    pub fn isExecuting(self: Self) bool {
        return self.state == .executing;
    }

    /// Scroll up in output
    pub fn scrollUp(self: *Self, lines: usize) void {
        self.output_widget.scrollUp(lines);
    }

    /// Scroll down in output
    pub fn scrollDown(self: *Self, lines: usize) void {
        self.output_widget.scrollDown(lines);
    }

    /// Page up in output
    pub fn pageUp(self: *Self, page_size: usize) void {
        self.output_widget.pageUp(page_size);
    }

    /// Page down in output
    pub fn pageDown(self: *Self, page_size: usize) void {
        self.output_widget.pageDown(page_size);
    }

    /// Get state as display string
    pub fn getStateDisplay(self: Self, allocator: std.mem.Allocator) ![]const u8 {
        return switch (self.state) {
            .idle => allocator.dupe(u8, "Idle"),
            .executing => allocator.dupe(u8, "Executing..."),
            .success => allocator.dupe(u8, "✓ Success"),
            .failed => try std.fmt.allocPrint(allocator, "✗ Failed (exit code: {d})", .{
                if (self.last_result) |r| r.exit_code else 0,
            }),
            .timeout => allocator.dupe(u8, "⏱ Timeout"),
            .language_not_available => allocator.dupe(u8, "⚠ Language not available"),
        };
    }

    /// Get execution time display
    pub fn getExecutionTimeDisplay(self: Self, allocator: std.mem.Allocator) !?[]const u8 {
        const result = self.last_result orelse return null;
        return try std.fmt.allocPrint(allocator, "{d}ms", .{result.execution_time_ms});
    }

    /// Draw the execution widget
    pub fn draw(self: Self, win: tui.Window, theme: anytype) void {
        if (!self.visible) return;

        // Clear the window area
        win.clear();

        // Draw border
        const style = self.getStateStyle(theme);

        // Title bar with state
        const title = self.getTitle();
        const title_style = style;

        // Draw title at top
        var row: usize = 0;
        win.writeCell(0, @intCast(row), .{
            .char = .{ .grapheme = title },
            .style = title_style,
        });
        row += 1;

        // Draw separator line
        for (0..win.width) |col| {
            win.writeCell(@intCast(col), @intCast(row), .{
                .char = .{ .grapheme = "─" },
                .style = style,
            });
        }
        row += 1;

        // Draw output content
        const visible_lines = self.output_widget.getVisibleLines(win.height - row);
        for (visible_lines, 0..) |line, i| {
            const line_row = row + i;
            if (line_row >= win.height) break;

            // Truncate content if too long
            const content = if (line.content.len > win.width)
                line.content[0..win.width]
            else
                line.content;

            // Use different color for stderr
            const line_style = if (line.stream == .stderr)
                elementStyleToVaxis(theme.error_color)
            else
                elementStyleToVaxis(theme.paragraph);

            win.writeCell(0, @intCast(line_row), .{
                .char = .{ .grapheme = content },
                .style = line_style,
            });
        }

        // Draw status bar at bottom
        if (win.height > 2) {
            const status_row = win.height - 1;
            const status_owned: ?[]const u8 = self.getStatusText() catch null;
            const status = status_owned orelse "Error";
            defer if (status_owned) |s| self.allocator.free(s);

            for (0..win.width) |col| {
                win.writeCell(@intCast(col), @intCast(status_row), .{
                    .char = .{ .grapheme = " " },
                    .style = .{ .bg = .{ .rgb = .{ 40, 40, 40 } } },
                });
            }

            win.writeCell(0, @intCast(status_row), .{
                .char = .{ .grapheme = status },
                .style = .{ .bg = .{ .rgb = .{ 40, 40, 40 } } },
            });
        }
    }

    /// Get widget title based on state
    fn getTitle(self: Self) []const u8 {
        return switch (self.state) {
            .idle => " Execution ",
            .executing => " Executing... ",
            .success => " ✓ Execution Complete ",
            .failed => " ✗ Execution Failed ",
            .timeout => " ⏱ Execution Timeout ",
            .language_not_available => " ⚠ Language Not Available ",
        };
    }

    /// Get style based on state
    fn getStateStyle(self: Self, theme: anytype) tui.Style {
        const element_style = switch (self.state) {
            .idle => theme.paragraph,
            .executing => theme.accent_color,
            .success => theme.success_color,
            .failed => theme.error_color,
            .timeout => theme.warning_color,
            .language_not_available => theme.error_color,
        };
        return elementStyleToVaxis(element_style);
    }

    /// Convert ElementStyle to tui.Style
    fn elementStyleToVaxis(es: @import("../render/Theme.zig").ElementStyle) tui.Style {
        var style: tui.Style = .{};
        if (es.fg) |fg| {
            if (@import("../render/Theme.zig").Theme.toRgb(fg)) |rgb| {
                style.fg = .{ .rgb = rgb };
            }
        }
        if (es.bg) |bg| {
            if (@import("../render/Theme.zig").Theme.toRgb(bg)) |rgb| {
                style.bg = .{ .rgb = rgb };
            }
        }
        style.bold = es.bold orelse false;
        style.italic = es.italic orelse false;
        if (es.underline orelse false) {
            style.ul_style = .single;
        }
        return style;
    }

    /// Get status bar text
    fn getStatusText(self: Self) ![]const u8 {
        var parts: std.ArrayList(u8) = .empty;
        defer parts.deinit(self.allocator);

        const writer = parts.writer(self.allocator);

        // State
        const state_str = try self.getStateDisplay(self.allocator);
        defer self.allocator.free(state_str);
        try writer.writeAll(state_str);

        // Execution time
        if (try self.getExecutionTimeDisplay(self.allocator)) |time| {
            defer self.allocator.free(time);
            try writer.print(" | {s}", .{time});
        }

        // Output stats
        const stats = self.output_widget.capture.getStats();
        try writer.print(" | Lines: {d}", .{stats.total_lines});

        return parts.toOwnedSlice(self.allocator);
    }
};

test "ExecutionWidget basic operations" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var widget = ExecutionWidget.init(allocator);
    defer widget.deinit();

    // Test initial state
    try testing.expectEqual(ExecutionWidget.State.idle, widget.getState());
    try testing.expect(!widget.isVisible());
    try testing.expect(!widget.isExecuting());

    // Test toggle
    widget.toggle();
    try testing.expect(widget.isVisible());

    // Test start execution
    try widget.startExecution("bash", "echo hello");
    try testing.expect(widget.isVisible());
    try testing.expect(widget.isExecuting());
    try testing.expectEqual(ExecutionWidget.State.executing, widget.getState());

    // Test set result
    const result = ExecutionResult{
        .exit_code = 0,
        .stdout = try allocator.dupe(u8, "hello\n"),
        .stderr = try allocator.dupe(u8, ""),
        .execution_time_ms = 100,
        .killed = false,
    };
    try widget.setResult(result);
    try testing.expectEqual(ExecutionWidget.State.success, widget.getState());
    try testing.expect(!widget.isExecuting());
}

test "ExecutionWidget language not available" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var widget = ExecutionWidget.init(allocator);
    defer widget.deinit();

    widget.setLanguageNotAvailable();
    try testing.expectEqual(ExecutionWidget.State.language_not_available, widget.getState());
    try testing.expect(widget.isVisible());
}
