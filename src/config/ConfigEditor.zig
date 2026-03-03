//! Interactive GUI configuration editor
const std = @import("std");
const vaxis = @import("vaxis");

const Config = @import("Config.zig").Config;

/// Configuration editor state
pub const ConfigEditor = struct {
    allocator: std.mem.Allocator,
    config: Config,

    // UI State
    selected_section: Section,
    selected_field: usize,

    // Input mode
    input_mode: InputMode,
    input_buffer: std.ArrayList(u8),

    // Dirty flag
    dirty: bool,

    const Self = @This();

    pub const Section = enum {
        presentation,
        theme,
        display,
        transitions,

        pub fn next(self: Section) Section {
            return switch (self) {
                .presentation => .theme,
                .theme => .display,
                .display => .transitions,
                .transitions => .presentation,
            };
        }

        pub fn prev(self: Section) Section {
            return switch (self) {
                .presentation => .transitions,
                .theme => .presentation,
                .display => .theme,
                .transitions => .display,
            };
        }

        pub fn toString(self: Section) []const u8 {
            return switch (self) {
                .presentation => "Presentation",
                .theme => "Theme",
                .display => "Display",
                .transitions => "Transitions",
            };
        }
    };

    pub const InputMode = enum {
        navigate,
        edit,
    };

    pub fn init(allocator: std.mem.Allocator, config: Config) !Self {
        var editor = Self{
            .allocator = allocator,
            .config = config,
            .selected_section = .presentation,
            .selected_field = 0,
            .input_mode = .navigate,
            .input_buffer = .empty,
            .dirty = false,
        };

        // Clone strings in config
        editor.config.theme.name = try allocator.dupe(u8, config.theme.name);

        return editor;
    }

    pub fn deinit(self: *Self) void {
        self.input_buffer.deinit(self.allocator);
    }

    /// Handle key input
    pub fn handleKey(self: *Self, key: vaxis.Key) !void {
        switch (self.input_mode) {
            .navigate => try self.handleNavigateKey(key),
            .edit => try self.handleEditKey(key),
        }
    }

    fn handleNavigateKey(self: *Self, key: vaxis.Key) !void {
        switch (key.codepoint) {
            'q', 0x1B => {}, // Quit handled by caller
            'j', vaxis.Key.down => {
                self.selected_field += 1;
                self.clampField();
            },
            'k', vaxis.Key.up => {
                if (self.selected_field > 0) {
                    self.selected_field -= 1;
                }
            },
            'h', vaxis.Key.left => {
                self.selected_section = self.selected_section.prev();
                self.selected_field = 0;
            },
            'l', vaxis.Key.right => {
                self.selected_section = self.selected_section.next();
                self.selected_field = 0;
            },
            '\r', ' ' => { // Enter edit mode
                self.input_mode = .edit;
                self.input_buffer.clearRetainingCapacity();
            },
            else => {},
        }
    }

    fn handleEditKey(self: *Self, key: vaxis.Key) !void {
        switch (key.codepoint) {
            0x1B => { // Escape - cancel edit
                self.input_mode = .navigate;
                self.input_buffer.clearRetainingCapacity();
            },
            '\r' => { // Enter - confirm edit
                try self.confirmEdit();
                self.input_mode = .navigate;
                self.input_buffer.clearRetainingCapacity();
            },
            vaxis.Key.backspace => {
                if (self.input_buffer.items.len > 0) {
                    _ = self.input_buffer.pop();
                }
            },
            else => {
                if (key.codepoint >= 32 and key.codepoint < 127) {
                    try self.input_buffer.append(self.allocator, @intCast(key.codepoint));
                }
            },
        }
    }

    fn confirmEdit(self: *Self) !void {
        const value = self.input_buffer.items;
        if (value.len == 0) return;

        switch (self.selected_section) {
            .theme => {
                if (self.selected_field == 0) { // theme name
                    self.allocator.free(self.config.theme.name);
                    self.config.theme.name = try self.allocator.dupe(u8, value);
                    self.dirty = true;
                }
            },
            .presentation => {
                if (self.selected_field == 0) { // auto_advance
                    self.config.presentation.auto_advance_seconds = std.fmt.parseInt(u32, value, 10) catch return;
                    self.dirty = true;
                }
            },
            else => {},
        }
    }

    fn getFieldCount(self: Self) usize {
        return switch (self.selected_section) {
            .presentation => 3,
            .theme => 2,
            .display => 2,
            .transitions => 2,
        };
    }

    fn clampField(self: *Self) void {
        const count = self.getFieldCount();
        if (self.selected_field >= count) {
            self.selected_field = count - 1;
        }
    }

    /// Draw the config editor UI
    pub fn draw(self: Self, win: vaxis.Window) void {
        win.clear();

        // Draw header
        self.drawHeader(win);

        // Draw sidebar with sections
        self.drawSidebar(win);

        // Draw main content area
        self.drawContent(win);

        // Draw footer
        self.drawFooter(win);

        // Draw input prompt if editing
        if (self.input_mode == .edit) {
            self.drawInputPrompt(win);
        }
    }

    fn drawHeader(self: Self, win: vaxis.Window) void {
        _ = self;
        const header_text = "Configuration Editor";
        const col = @divTrunc(win.width, 2) - @divTrunc(@as(u16, @intCast(header_text.len)), 2);

        _ = win.writeCell(col, 0, .{
            .char = .{ .grapheme = header_text },
            .style = .{ .bold = true },
        });
    }

    fn drawSidebar(self: Self, win: vaxis.Window) void {
        var row: u16 = 2;

        const sections = &[_]Section{ .presentation, .theme, .display, .transitions };
        for (sections) |section| {
            const is_selected = section == self.selected_section;

            const prefix = if (is_selected) "> " else "  ";
            var buf: [64]u8 = undefined;
            const text = std.fmt.bufPrint(&buf, "{s}{s}", .{ prefix, section.toString() }) catch continue;

            const style = if (is_selected)
                vaxis.Style{ .bold = true, .fg = .{ .rgb = .{ 0, 150, 255 } } }
            else
                vaxis.Style{};

            _ = win.writeCell(0, row, .{
                .char = .{ .grapheme = text },
                .style = style,
            });

            row += 1;
        }
    }

    fn drawContent(self: Self, win: vaxis.Window) void {
        const start_col: u16 = 22;
        var row: u16 = 2;

        // Draw section title
        _ = win.writeCell(start_col, row, .{
            .char = .{ .grapheme = self.selected_section.toString() },
            .style = .{ .bold = true },
        });
        row += 2;

        // Draw fields
        const field_count = self.getFieldCount();
        var i: usize = 0;
        while (i < field_count and row < win.height - 3) : ({
            i += 1;
            row += 1;
        }) {
            const is_selected = i == self.selected_field;

            const field_text = self.getFieldLabel(i);
            const value_text = self.getFieldValue(i);

            var buf: [256]u8 = undefined;
            const line = std.fmt.bufPrint(&buf, "  {s}: ", .{field_text}) catch continue;

            const style = if (is_selected)
                vaxis.Style{
                    .bg = .{ .rgb = .{ 40, 40, 40 } },
                    .fg = .{ .rgb = .{ 0, 200, 255 } },
                }
            else
                vaxis.Style{};

            // Draw field name
            _ = win.writeCell(start_col, row, .{
                .char = .{ .grapheme = line },
                .style = style,
            });

            // Draw value
            _ = win.writeCell(start_col + 25, row, .{
                .char = .{ .grapheme = value_text },
                .style = style,
            });
        }
    }

    fn drawFooter(self: Self, win: vaxis.Window) void {
        const footer_row = win.height - 1;

        const help_text = "j/k: navigate | h/l: sections | Enter: edit | q: quit";
        _ = win.writeCell(0, footer_row, .{
            .char = .{ .grapheme = help_text },
            .style = .{ .fg = .{ .rgb = .{ 128, 128, 128 } } },
        });

        if (self.dirty) {
            const dirty_text = " [modified]";
            _ = win.writeCell(@intCast(help_text.len), footer_row, .{
                .char = .{ .grapheme = dirty_text },
                .style = .{ .fg = .{ .rgb = .{ 255, 165, 0 } } },
            });
        }
    }

    fn drawInputPrompt(self: Self, win: vaxis.Window) void {
        const row = win.height - 4;
        const prompt = "Enter value: ";

        _ = win.writeCell(0, row, .{
            .char = .{ .grapheme = prompt },
            .style = .{ .bold = true },
        });

        if (self.input_buffer.items.len > 0) {
            _ = win.writeCell(@intCast(prompt.len), row, .{
                .char = .{ .grapheme = self.input_buffer.items },
                .style = .{ .fg = .{ .rgb = .{ 0, 200, 255 } } },
            });
        }
    }

    fn getFieldLabel(self: Self, index: usize) []const u8 {
        return switch (self.selected_section) {
            .presentation => switch (index) {
                0 => "Auto-advance",
                1 => "Loop",
                2 => "Show numbers",
                else => "Unknown",
            },
            .theme => switch (index) {
                0 => "Theme",
                1 => "Use term bg",
                else => "Unknown",
            },
            .display => switch (index) {
                0 => "Truecolor",
                1 => "Mouse",
                else => "Unknown",
            },
            .transitions => switch (index) {
                0 => "Enabled",
                1 => "Duration",
                else => "Unknown",
            },
        };
    }

    fn getFieldValue(self: Self, index: usize) []const u8 {
        return switch (self.selected_section) {
            .presentation => switch (index) {
                0 => if (self.config.presentation.auto_advance_seconds == 0) "off" else "on",
                1 => if (self.config.presentation.loop) "yes" else "no",
                2 => if (self.config.presentation.show_slide_numbers) "yes" else "no",
                else => "?",
            },
            .theme => switch (index) {
                0 => self.config.theme.name,
                1 => if (self.config.theme.use_terminal_background) "yes" else "no",
                else => "?",
            },
            .display => switch (index) {
                0 => if (self.config.display.truecolor) "yes" else "no",
                1 => if (self.config.display.mouse) "yes" else "no",
                else => "?",
            },
            .transitions => switch (index) {
                0 => if (self.config.transitions.enabled) "yes" else "no",
                1 => "300ms", // Simplified
                else => "?",
            },
        };
    }
};

test "ConfigEditor init" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const config = Config{};
    var editor = try ConfigEditor.init(allocator, config);
    defer editor.deinit();

    try testing.expectEqual(ConfigEditor.Section.presentation, editor.selected_section);
    try testing.expectEqual(@as(usize, 0), editor.selected_field);
}

test "Section navigation" {
    const testing = std.testing;

    var section = ConfigEditor.Section.presentation;
    section = section.next();
    try testing.expectEqual(ConfigEditor.Section.theme, section);
    section = section.prev();
    try testing.expectEqual(ConfigEditor.Section.presentation, section);
}
