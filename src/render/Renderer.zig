//! Main rendering engine for presentations
const std = @import("std");
const tui = @import("../tui/root.zig");

const Presentation = @import("../core/Presentation.zig").Presentation;
const Slide = @import("../core/Slide.zig").Slide;
const Navigation = @import("../core/Navigation.zig").Navigation;
const Theme = @import("Theme.zig").Theme;
const darkTheme = @import("Theme.zig").darkTheme;

const SlideWidget = @import("../widgets/SlideWidget.zig").SlideWidget;
const ExecutionWidget = @import("../widgets/ExecutionWidget.zig").ExecutionWidget;
const HelpWidget = @import("../widgets/HelpWidget.zig").HelpWidget;
const StatusBar = @import("../widgets/StatusBar.zig").StatusBar;
const DrawContext = @import("../widgets/Widget.zig").DrawContext;

/// Layout configuration for the renderer
pub const LayoutConfig = struct {
    /// Top margin for slide content
    top_margin: usize = 1,
    /// Bottom margin for status bar
    bottom_margin: usize = 1,
    /// Left margin
    left_margin: usize = 2,
    /// Right margin
    right_margin: usize = 2,
    /// Height percentage for execution widget (when visible)
    execution_height_percent: u8 = 40,

    /// Get the content area within the window
    pub fn getContentArea(self: LayoutConfig, win: tui.Window) ContentArea {
        return .{
            .x = self.left_margin,
            .y = self.top_margin,
            .width = if (win.width > self.left_margin + self.right_margin)
                win.width - self.left_margin - self.right_margin
            else
                0,
            .height = if (win.height > self.top_margin + self.bottom_margin)
                win.height - self.top_margin - self.bottom_margin
            else
                0,
        };
    }
};

/// Content area definition
pub const ContentArea = struct {
    x: usize,
    y: usize,
    width: usize,
    height: usize,
};

/// Renderer manages the presentation rendering pipeline
pub const Renderer = struct {
    allocator: std.mem.Allocator,
    theme: Theme,
    layout: LayoutConfig,
    current_slide_widget: ?*SlideWidget,
    current_slide_index: ?usize = null,

    const Self = @This();

    /// Initialize the renderer
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .theme = darkTheme(),
            .layout = .{},
            .current_slide_widget = null,
        };
    }

    /// Clean up resources
    pub fn deinit(self: *Self) void {
        if (self.current_slide_widget) |widget| {
            widget.deinit();
        }
    }

    /// Set the theme
    pub fn setTheme(self: *Self, theme: Theme) void {
        self.theme = theme;
    }

    /// Update the current slide widget
    pub fn setCurrentSlide(self: *Self, slide: Slide, index: usize) !void {
        // Store old widget temporarily
        const old_widget = self.current_slide_widget;

        // Create new slide widget first (deep-clones the slide to avoid double-free)
        self.current_slide_widget = try SlideWidget.init(self.allocator, slide, self.theme);
        self.current_slide_index = index;

        // Only free old widget after successful creation
        if (old_widget) |widget| {
            widget.deinit();
        }
    }

    /// Clear the current slide
    pub fn clearSlide(self: *Self) void {
        if (self.current_slide_widget) |widget| {
            widget.deinit();
            self.current_slide_widget = null;
            self.current_slide_index = null;
        }
    }

    /// Render the complete UI
    pub fn render(
        self: *Self,
        win: tui.Window,
        presentation: ?Presentation,
        nav: ?Navigation,
        execution_widget: ?*ExecutionWidget,
        help_widget: ?*HelpWidget,
        theme: Theme,
    ) !void {
        // Guard against zero-size windows (e.g. expect pty, minimized terminal)
        if (win.width == 0 or win.height == 0) return;

        // Update theme if it changed (forces slide widget rebuild)
        const theme_changed = !std.mem.eql(u8, self.theme.name, theme.name);
        if (theme_changed) {
            self.theme = theme;
            // Force rebuild of slide widget with new theme
            if (self.current_slide_widget) |widget| {
                widget.deinit();
                self.current_slide_widget = null;
            }
        }

        win.clear();

        if (presentation == null or nav == null) {
            try self.renderWelcomeScreen(win);
            return;
        }

        const pres = presentation.?;
        const navigation = nav.?;

        // Update current slide widget if needed
        const need_update = self.current_slide_widget == null or
            self.getCurrentSlideIndex() == null or
            self.getCurrentSlideIndex().? != navigation.current_slide;
        if (need_update) {
            if (pres.getSlide(navigation.current_slide)) |slide| {
                try self.setCurrentSlide(slide, navigation.current_slide);
            }
        }

        // Calculate layout areas
        const content_area = self.layout.getContentArea(win);

        // Render execution widget if visible (takes bottom portion)
        var slide_height = content_area.height;
        if (execution_widget) |exec| {
            if (exec.isVisible()) {
                const exec_height = @max(5, @divTrunc(content_area.height * self.layout.execution_height_percent, 100));
                slide_height = content_area.height - exec_height;

                const exec_win = win.child(.{
                    .x_off = @intCast(content_area.x),
                    .y_off = @intCast(content_area.y + slide_height),
                    .width = @intCast(content_area.width),
                    .height = @intCast(exec_height),
                });

                exec.draw(exec_win, self.theme);
            }
        }

        // Render the slide
        if (self.current_slide_widget) |slide_widget| {
            const slide_win = win.child(.{
                .x_off = @intCast(content_area.x),
                .y_off = @intCast(content_area.y),
                .width = @intCast(content_area.width),
                .height = @intCast(slide_height),
            });

            const ctx = DrawContext{
                .win = slide_win,
                .theme = self.theme,
            };

            slide_widget.draw(ctx, 0, 0);
        }

        // Render status bar
        self.renderStatusBar(win, pres, navigation);

        // Render help overlay if visible
        if (help_widget) |help| {
            help.draw(win, self.theme);
        }
    }

    /// Render welcome screen when no presentation is loaded
    fn renderWelcomeScreen(self: Self, win: tui.Window) !void {
        _ = self;

        const welcome_text = "Welcome to tuia!";
        const subtitle = "Open a presentation file to begin.";
        const hint = "Press 'q' to quit.";

        // Ensure minimum window height to avoid underflow
        if (win.height < 5) return;

        const center_row = @divTrunc(win.height, 2);

        // Draw welcome text
        if (win.width > welcome_text.len and center_row >= 1) {
            const col = @divTrunc(win.width - @as(u16, @intCast(welcome_text.len)), 2);
            win.writeCell(col, center_row - 1, .{
                .char = .{ .grapheme = welcome_text },
                .style = .{ .bold = true },
            });
        }

        // Draw subtitle
        if (win.width > subtitle.len) {
            const col = @divTrunc(win.width - @as(u16, @intCast(subtitle.len)), 2);
            win.writeCell(col, center_row + 1, .{
                .char = .{ .grapheme = subtitle },
            });
        }

        // Draw hint
        if (win.width > hint.len and center_row + 3 < win.height) {
            const col = @divTrunc(win.width - @as(u16, @intCast(hint.len)), 2);
            const style = tui.Style{
                .fg = .{ .rgb = .{ 128, 128, 128 } },
            };
            win.writeCell(col, center_row + 3, .{
                .char = .{ .grapheme = hint },
                .style = style,
            });
        }
    }

    /// Render the status bar at the bottom
    fn renderStatusBar(self: Self, win: tui.Window, presentation: Presentation, nav: Navigation) void {
        if (win.height < 2) return;
        const status_row = win.height - 1;

        // Build status text on stack
        var slide_buf: [64]u8 = undefined;
        const slide_info = std.fmt.bufPrint(&slide_buf, " Slide {d}/{d} ", .{
            nav.currentSlideNumber(),
            presentation.slideCount(),
        }) catch return;

        // Get title if available
        const title = presentation.metadata.title;

        // Draw background
        const bg_color = if (self.theme.code_block.bg) |c|
            if (Theme.toRgb(c)) |rgb| tui.Cell.Color{ .rgb = rgb } else .default
        else
            tui.Cell.Color{ .rgb = .{ 40, 40, 40 } };

        const fg_color = if (self.theme.code_block.fg) |c|
            if (Theme.toRgb(c)) |rgb| tui.Cell.Color{ .rgb = rgb } else .default
        else
            .default;

        const bg_style = tui.Style{
            .bg = bg_color,
            .fg = fg_color,
        };

        for (0..win.width) |col| {
            win.writeCell(@intCast(col), status_row, .{
                .char = .{ .grapheme = " " },
                .style = bg_style,
            });
        }

        // Draw slide info char-by-char
        for (slide_info, 0..) |ch, i| {
            if (i >= win.width) break;
            win.writeCell(@intCast(i), status_row, .{
                .char = .{ .grapheme = tui.Cell.grapheme(ch) },
                .style = bg_style,
            });
        }

        // Draw title if available
        if (title) |t| {
            var title_buf: [256]u8 = undefined;
            const title_display = std.fmt.bufPrint(&title_buf, " {s} ", .{t}) catch return;

            if (win.width > title_display.len + slide_info.len) {
                for (title_display, 0..) |ch, i| {
                    const col: u16 = @intCast(slide_info.len + i);
                    if (col >= win.width) break;
                    win.writeCell(col, status_row, .{
                        .char = .{ .grapheme = tui.Cell.grapheme(ch) },
                        .style = bg_style,
                    });
                }
            }
        }

        // Draw message if any
        if (nav.message) |msg| {
            const msg_col: u16 = if (win.width > msg.len + 2)
                win.width - @as(u16, @intCast(msg.len)) - 2
            else
                0;

            const msg_bg = if (self.theme.code_block.bg) |c|
                if (Theme.toRgb(c)) |rgb| tui.Cell.Color{ .rgb = rgb } else .default
            else
                tui.Cell.Color{ .rgb = .{ 40, 40, 40 } };

            const msg_fg = if (self.theme.accent_color.fg) |c|
                if (Theme.toRgb(c)) |rgb| tui.Cell.Color{ .rgb = rgb } else .default
            else
                tui.Cell.Color{ .rgb = .{ 0, 255, 255 } };

            const msg_style = tui.Style{
                .bg = msg_bg,
                .fg = msg_fg,
            };

            for (msg, 0..) |ch, i| {
                const col: u16 = msg_col + @as(u16, @intCast(i));
                if (col >= win.width) break;
                win.writeCell(col, status_row, .{
                    .char = .{ .grapheme = tui.Cell.grapheme(ch) },
                    .style = msg_style,
                });
            }
        }
    }

    /// Get current slide index (for comparison)
    fn getCurrentSlideIndex(self: Self) ?usize {
        return self.current_slide_index;
    }
};

// Tests
test "Renderer initialization" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var renderer = Renderer.init(allocator);
    defer renderer.deinit();

    // Renderer should start with no slide widget
    try testing.expect(renderer.current_slide_widget == null);
}

// Note: LayoutConfig test removed as tui.Window cannot be easily mocked
// The getContentArea function is tested indirectly through integration tests
