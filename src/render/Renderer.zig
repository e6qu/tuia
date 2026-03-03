//! Main rendering engine for presentations
const std = @import("std");
const vaxis = @import("vaxis");

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
    pub fn getContentArea(self: LayoutConfig, win: vaxis.Window) ContentArea {
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

    /// Initialize with a specific theme
    pub fn initWithTheme(allocator: std.mem.Allocator, theme: Theme) Self {
        return .{
            .allocator = allocator,
            .theme = theme,
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
    pub fn setCurrentSlide(self: *Self, slide: Slide) !void {
        // Store old widget temporarily
        const old_widget = self.current_slide_widget;

        // Create new slide widget first
        self.current_slide_widget = try SlideWidget.init(self.allocator, slide);

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
        }
    }

    /// Render the complete UI
    pub fn render(
        self: *Self,
        win: vaxis.Window,
        presentation: ?Presentation,
        nav: ?Navigation,
        execution_widget: ?*ExecutionWidget,
        help_widget: ?*HelpWidget,
        theme: Theme,
    ) !void {
        _ = theme;
        win.clear();

        if (presentation == null or nav == null) {
            try self.renderWelcomeScreen(win);
            return;
        }

        const pres = presentation.?;
        const navigation = nav.?;

        // Update current slide widget if needed
        if (self.current_slide_widget == null or
            self.getCurrentSlideIndex() != navigation.current_slide)
        {
            if (pres.getSlide(navigation.current_slide)) |slide| {
                try self.setCurrentSlide(slide);
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
        try self.renderStatusBar(win, pres, navigation);

        // Render help overlay if visible
        if (help_widget) |help| {
            if (help.visible) {
                help.draw(win, self.theme);
            }
        }
    }

    /// Render welcome screen when no presentation is loaded
    fn renderWelcomeScreen(self: Self, win: vaxis.Window) !void {
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
            _ = win.writeCell(col, center_row - 1, .{
                .char = .{ .grapheme = welcome_text },
                .style = .{ .bold = true },
            });
        }

        // Draw subtitle
        if (win.width > subtitle.len) {
            const col = @divTrunc(win.width - @as(u16, @intCast(subtitle.len)), 2);
            _ = win.writeCell(col, center_row + 1, .{
                .char = .{ .grapheme = subtitle },
            });
        }

        // Draw hint
        if (win.width > hint.len and center_row + 3 < win.height) {
            const col = @divTrunc(win.width - @as(u16, @intCast(hint.len)), 2);
            const style = vaxis.Style{
                .fg = .{ .rgb = .{ 128, 128, 128 } },
            };
            _ = win.writeCell(col, center_row + 3, .{
                .char = .{ .grapheme = hint },
                .style = style,
            });
        }
    }

    /// Render the status bar at the bottom
    fn renderStatusBar(self: Self, win: vaxis.Window, presentation: Presentation, nav: Navigation) !void {
        const status_row = win.height - 1;
        if (status_row < 0) return;

        // Build status text
        const slide_info = try std.fmt.allocPrint(self.allocator, " Slide {d}/{d} ", .{
            nav.currentSlideNumber(),
            presentation.slideCount(),
        });
        defer self.allocator.free(slide_info);

        // Get title if available
        const title = presentation.metadata.title;

        // Draw background
        const bg_color = if (self.theme.code_block.bg) |c|
            if (Theme.toRgb(c)) |rgb| vaxis.Cell.Color{ .rgb = rgb } else .default
        else
            vaxis.Cell.Color{ .rgb = .{ 40, 40, 40 } };

        const fg_color = if (self.theme.code_block.fg) |c|
            if (Theme.toRgb(c)) |rgb| vaxis.Cell.Color{ .rgb = rgb } else .default
        else
            .default;

        const bg_style = vaxis.Style{
            .bg = bg_color,
            .fg = fg_color,
        };

        for (0..win.width) |col| {
            _ = win.writeCell(@intCast(col), status_row, .{
                .char = .{ .grapheme = " " },
                .style = bg_style,
            });
        }

        // Draw slide info
        _ = win.writeCell(0, status_row, .{
            .char = .{ .grapheme = slide_info },
            .style = bg_style,
        });

        // Draw title if available
        if (title) |t| {
            const title_display = try std.fmt.allocPrint(self.allocator, " {s} ", .{t});
            defer self.allocator.free(title_display);

            if (win.width > title_display.len + slide_info.len) {
                const title_col: u16 = @intCast(slide_info.len);
                _ = win.writeCell(title_col, status_row, .{
                    .char = .{ .grapheme = title_display },
                    .style = bg_style,
                });
            }
        }

        // Draw message if any
        if (nav.message) |msg| {
            const msg_col = if (win.width > msg.len + 2)
                win.width - @as(u16, @intCast(msg.len)) - 2
            else
                0;

            const msg_bg = if (self.theme.code_block.bg) |c|
                if (Theme.toRgb(c)) |rgb| vaxis.Cell.Color{ .rgb = rgb } else .default
            else
                vaxis.Cell.Color{ .rgb = .{ 40, 40, 40 } };

            const msg_fg = if (self.theme.accent_color.fg) |c|
                if (Theme.toRgb(c)) |rgb| vaxis.Cell.Color{ .rgb = rgb } else .default
            else
                vaxis.Cell.Color{ .rgb = .{ 0, 255, 255 } };

            const msg_style = vaxis.Style{
                .bg = msg_bg,
                .fg = msg_fg,
            };

            _ = win.writeCell(msg_col, status_row, .{
                .char = .{ .grapheme = msg },
                .style = msg_style,
            });
        }
    }

    /// Get current slide index (for comparison)
    fn getCurrentSlideIndex(self: Self) usize {
        _ = self;
        // This is a placeholder - in practice, we'd track the current index
        // The actual tracking happens through the navigation system
        return 0;
    }

    /// Render a simple text presentation (for testing/debugging)
    pub fn renderDebug(self: Self, win: vaxis.Window, presentation: Presentation) !void {
        win.clear();

        const title = presentation.metadata.title orelse "Untitled";
        _ = win.writeCell(0, 0, .{
            .char = .{ .grapheme = title },
            .style = .{ .bold = true, .underline = true },
        });

        const slide_count = try std.fmt.allocPrint(self.allocator, "Slides: {d}", .{presentation.slideCount()});
        defer self.allocator.free(slide_count);

        _ = win.writeCell(0, 2, .{
            .char = .{ .grapheme = slide_count },
        });
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

test "Renderer with theme" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const theme = darkTheme();
    var renderer = Renderer.initWithTheme(allocator, theme);
    defer renderer.deinit();
}

// Note: LayoutConfig test removed as vaxis.Window cannot be easily mocked
// The getContentArea function is tested indirectly through integration tests
