//! Main application state and event loop
const std = @import("std");
const builtin = @import("builtin");
const tui = @import("tui/root.zig");
const Terminal = @import("tui/Terminal.zig").Terminal;

const core = @import("core/root.zig");
const parser_module = @import("parser/root.zig");
const widgets = @import("widgets/root.zig");
const render = @import("render/root.zig");
const features = @import("features/root.zig");
const executor = @import("features/executor/root.zig");
const transitions = @import("features/transitions/root.zig");
const ConfigEditor = @import("config/ConfigEditor.zig").ConfigEditor;
const Config = @import("config/Config.zig").Config;

const Presentation = core.Presentation;
const PresentationBuilder = core.PresentationBuilder;
const Navigation = core.Navigation;
const Parser = parser_module.Parser;
const convertPresentation = @import("parser/Converter.zig").convertPresentation;
const InputHandler = @import("core/InputHandler.zig").InputHandler;
const ExecutionWidget = @import("widgets/ExecutionWidget.zig").ExecutionWidget;
const HelpWidget = @import("widgets/HelpWidget.zig").HelpWidget;
const PresentationOverlay = @import("widgets/PresentationOverlay.zig").PresentationOverlay;
const CodeExecutor = executor.CodeExecutor;
const ExecutionConfig = executor.ExecutionConfig;
const ExecutorRegistry = executor.ExecutorRegistry;
const Language = executor.Language;
const Renderer = render.Renderer;
const Theme = render.Theme.Theme;
const darkTheme = render.Theme.darkTheme;
const lightTheme = render.Theme.lightTheme;

const Signal = enum {
    sigint,
    sigterm,
};

/// App manages the presentation application state and event loop
pub const App = struct {
    allocator: std.mem.Allocator,
    terminal: Terminal,

    presentation: ?Presentation = null,
    navigation: ?Navigation = null,
    input_handler: InputHandler,

    renderer: Renderer,
    help_widget: HelpWidget,

    execution_widget: ExecutionWidget,
    executor_registry: ?ExecutorRegistry = null,

    overlay: PresentationOverlay,

    transition_manager: transitions.TransitionManager,

    remote_server: features.remote.RemoteServer,
    remote_enabled: bool,

    media_player: features.media.MediaPlayer,

    config_editor: ?ConfigEditor,
    show_config_editor: bool,

    current_theme: Theme,

    running: bool = true,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        var terminal = try Terminal.init(allocator);
        errdefer terminal.deinit();

        return .{
            .allocator = allocator,
            .terminal = terminal,
            .input_handler = InputHandler.init(allocator),
            .execution_widget = ExecutionWidget.init(allocator),
            .help_widget = HelpWidget.init(allocator),
            .overlay = PresentationOverlay.init(allocator),
            .transition_manager = transitions.TransitionManager.init(allocator),
            .remote_server = features.remote.RemoteServer.init(allocator, 8765),
            .remote_enabled = false,
            .media_player = features.media.MediaPlayer.init(allocator),
            .config_editor = null,
            .show_config_editor = false,
            .renderer = Renderer.init(allocator),
            .current_theme = darkTheme(),
        };
    }

    /// Clean up resources
    pub fn deinit(self: *Self) void {
        if (self.executor_registry) |*reg| {
            reg.deinit();
        }
        if (self.navigation) |*nav| {
            nav.deinit(self.allocator);
        }
        if (self.presentation) |*pres| {
            pres.deinit();
        }
        self.renderer.deinit();
        self.execution_widget.deinit();
        self.help_widget.deinit();
        self.overlay.deinit();
        self.transition_manager.deinit();
        self.remote_server.stop();
        self.media_player.deinit();
        if (self.config_editor) |*ce| {
            ce.deinit();
        }
        self.input_handler.deinit();
        self.terminal.stop();
        self.terminal.deinit();
    }

    /// Load a presentation from a file
    pub fn loadPresentation(self: *Self, file_path: []const u8) !void {
        // Read file contents
        const file = try std.fs.cwd().openFile(file_path, .{});
        defer file.close();

        const content = try file.readToEndAlloc(self.allocator, 1024 * 1024); // 1MB max
        defer self.allocator.free(content);

        // Parse the presentation
        var prs = Parser.init(self.allocator, content);
        var ast_presentation = try prs.parse();

        // Convert AST presentation to core presentation
        const presentation = try convertPresentation(self.allocator, ast_presentation);

        // Clean up AST presentation after conversion
        ast_presentation.deinit();

        // Clean up old state
        if (self.navigation) |*old_nav| {
            old_nav.deinit(self.allocator);
        }
        if (self.presentation) |*old| {
            old.deinit();
        }
        if (self.executor_registry) |*old_reg| {
            old_reg.deinit();
        }

        // Store new presentation
        self.presentation = presentation;
        self.navigation = Navigation.init(&self.presentation.?);

        // Initialize executor
        self.executor_registry = ExecutorRegistry.init(self.allocator, ExecutionConfig{});

        // Update renderer with first slide
        self.renderer.clearSlide();
    }

    /// Run the main event loop
    pub fn run(self: *Self) !void {
        try self.terminal.enterAltScreen();
        self.terminal.queryTerminal();

        try self.terminal.start();

        while (self.running) {
            // Use short timeout during transitions for smooth animation (~60fps)
            const event = if (self.transition_manager.isTransitioning())
                self.terminal.nextEventTimeout(16_000_000) // 16ms
            else
                self.terminal.nextEvent();

            if (event) |ev| {
                self.handleEvent(ev) catch {};
            } else if (!self.transition_manager.isTransitioning()) {
                break; // null from nextEvent means quit (not timeout)
            }
            self.render() catch {};
        }
    }

    /// Handle an event
    fn handleEvent(self: *Self, event: tui.Event) !void {
        switch (event) {
            .key => |key| {
                try self.handleKey(key);
            },
            .winsize => |ws| {
                self.terminal.resize(ws);
            },
        }
    }

    /// Handle a key press
    fn handleKey(self: *Self, key: tui.Key) !void {
        // Handle config editor mode
        if (self.show_config_editor) {
            if (self.config_editor) |*ce| {
                try ce.handleKey(key);
                if (key.codepoint == 'q' and ce.input_mode == .navigate) {
                    self.show_config_editor = false;
                }
            }
            return;
        }

        // No presentation loaded — only allow quit
        if (self.navigation == null) {
            if ((key.codepoint == 'c' and key.mods.ctrl) or key.codepoint == 'q') {
                self.running = false;
            }
            return;
        }

        const nav = &self.navigation.?;

        // Check for quit
        if (key.codepoint == 'c' and key.mods.ctrl) {
            self.running = false;
            return;
        }

        // Launch config editor with '='
        if (key.codepoint == '=' and !self.input_handler.isInJumpMode()) {
            if (self.config_editor == null) {
                self.config_editor = try ConfigEditor.init(self.allocator, Config{});
            }
            self.show_config_editor = true;
            return;
        }

        // Handle laser pointer movement
        if (self.overlay.isLaserMode()) {
            switch (key.codepoint) {
                'h', tui.Key.left => {
                    self.overlay.moveLaser(-1, 0, 80, 24);
                    return;
                },
                'j', tui.Key.down => {
                    self.overlay.moveLaser(0, 1, 80, 24);
                    return;
                },
                'k', tui.Key.up => {
                    self.overlay.moveLaser(0, -1, 80, 24);
                    return;
                },
                'l', tui.Key.right => {
                    self.overlay.moveLaser(1, 0, 80, 24);
                    return;
                },
                else => {},
            }
        }

        // Toggle laser pointer mode with 'L'
        if (key.codepoint == 'L' and !self.input_handler.isInJumpMode()) {
            self.overlay.toggleLaserMode();
            // Center laser initially
            if (self.overlay.isLaserMode()) {
                self.overlay.setLaserPosition(40, 12);
            }
            return;
        }

        // Toggle drawing mode with 'D'
        if (key.codepoint == 'D' and !self.input_handler.isInJumpMode()) {
            self.overlay.toggleDrawMode();
            return;
        }

        // Clear drawings with 'C' (Shift+C, distinct from Ctrl+C)
        if (key.codepoint == 'C' and !key.mods.ctrl and !self.input_handler.isInJumpMode()) {
            self.overlay.clearDrawings();
            return;
        }

        // Handle drawing (click to draw in draw mode)
        if (self.overlay.isDrawMode() and key.codepoint == ' ') {
            // Draw at laser position
            try self.overlay.drawAt(self.overlay.laser_x, self.overlay.laser_y);
            return;
        }

        // Theme switching with 't'
        if (key.codepoint == 't' and !self.input_handler.isInJumpMode()) {
            self.overlay.toggleThemePicker();
            return;
        }

        // Theme selection in picker mode
        if (self.overlay.show_theme_picker) {
            switch (key.codepoint) {
                'j', tui.Key.down => {
                    self.overlay.nextTheme();
                    return;
                },
                'k', tui.Key.up => {
                    self.overlay.prevTheme();
                    return;
                },
                '\r', ' ' => {
                    // Apply selected theme
                    if (self.overlay.getCurrentThemeName()) |theme_name| {
                        if (std.mem.eql(u8, theme_name, "dark")) {
                            self.current_theme = darkTheme();
                        } else if (std.mem.eql(u8, theme_name, "light")) {
                            self.current_theme = lightTheme();
                        }
                    }
                    self.overlay.toggleThemePicker();
                    return;
                },
                'q', 0x1B => { // Escape
                    self.overlay.toggleThemePicker();
                    return;
                },
                else => {},
            }
        }

        // Check if this key will cause a slide change (before handling input)
        const will_change_slide = self.willChangeSlide(key, nav);
        const current_slide = nav.current_slide;

        // Capture current screen state for transition BEFORE navigation
        if (will_change_slide and self.transition_manager.config.enabled) {
            const win = self.terminal.window();
            // Screen already has the correct "from" state from the last render cycle
            const next_slide = self.getNextSlideIndex(key, nav);
            try self.transition_manager.startTransition(current_slide, next_slide, win);
        }

        // Handle input
        const should_quit = try self.input_handler.handleKey(key, nav, self.allocator);
        if (should_quit) {
            self.running = false;
            return;
        }

        // Check if code execution was requested
        if (key.codepoint == 'e' and !self.input_handler.isInJumpMode()) {
            try self.executeCurrentCodeBlock();
        }

        // On slide change, update overlay
        if (will_change_slide) {
            self.overlay.onSlideChange();
        }

        // Toggle transitions with 'T'
        if (key.codepoint == 'T' and !self.input_handler.isInJumpMode()) {
            self.transition_manager.toggleEnabled();
            const status = if (self.transition_manager.config.enabled) "enabled" else "disabled";
            const msg = try std.fmt.allocPrint(self.allocator, "Transitions {s}", .{status});
            defer self.allocator.free(msg);
            try nav.setMessage(self.allocator, msg, 60);
        }

        // Toggle remote control with 'R'
        if (key.codepoint == 'R' and !self.input_handler.isInJumpMode()) {
            if (self.remote_enabled) {
                self.remote_server.stop();
                self.remote_enabled = false;
                try nav.setMessage(self.allocator, "Remote control disabled", 60);
            } else {
                self.remote_server.start(nav) catch |err| {
                    const err_msg = try std.fmt.allocPrint(self.allocator, "Remote error: {s}", .{@errorName(err)});
                    defer self.allocator.free(err_msg);
                    try nav.setMessage(self.allocator, err_msg, 120);
                    return;
                };
                self.remote_enabled = true;
                try nav.setMessage(self.allocator, "Remote: http://localhost:8765", 120);
            }
        }

        // Media controls
        if (key.codepoint == 'm' and !self.input_handler.isInJumpMode()) {
            try nav.setMessage(self.allocator, "Media: Press 'M' to toggle playback", 60);
        }

        // Stop media with 'M' (shift+m)
        if (key.codepoint == 'M' and !key.mods.ctrl) {
            self.media_player.stop();
            try nav.setMessage(self.allocator, "Media stopped", 60);
        }
    }

    /// Check if a key press will change the current slide
    fn willChangeSlide(self: *Self, key: tui.Key, nav: *Navigation) bool {
        _ = self;
        return switch (key.codepoint) {
            'j', 'k', 'g', 'G', tui.Key.space, tui.Key.backspace, tui.Key.left, tui.Key.right, tui.Key.up, tui.Key.down => !nav.show_help and !nav.show_overview,
            else => false,
        };
    }

    /// Get the next slide index based on key press
    fn getNextSlideIndex(self: *Self, key: tui.Key, nav: *Navigation) usize {
        _ = self;
        const total = nav.total_slides;
        const current = nav.current_slide;

        return switch (key.codepoint) {
            'j', tui.Key.down, tui.Key.right, tui.Key.space => if (current < total - 1) current + 1 else current,
            'k', tui.Key.up, tui.Key.left, tui.Key.backspace => if (current > 0) current - 1 else current,
            'g' => 0,
            'G' => if (total > 0) total - 1 else 0,
            else => current,
        };
    }

    /// Execute the code block on the current slide
    fn executeCurrentCodeBlock(self: *Self) !void {
        var nav = &self.navigation.?;
        const pres = self.presentation.?;

        // Get current slide
        const slide = pres.getSlide(nav.current_slide) orelse {
            try nav.setMessage(self.allocator, "No slide to execute code from", 60);
            return;
        };

        // Extract first code block from slide
        const code_block = slide.getFirstCodeBlock() orelse {
            try nav.setMessage(self.allocator, "No code block on this slide", 60);
            return;
        };

        // Determine language
        const lang_str = code_block.language orelse "bash";
        const language = Language.fromString(lang_str) orelse Language.bash;

        // Check if language is available
        const runner = executor.Runner.forLanguage(language);
        if (!runner.isAvailable()) {
            self.execution_widget.setLanguageNotAvailable();
            nav.showExecution();
            return;
        }

        // Show execution widget
        nav.showExecution();
        try self.execution_widget.startExecution(lang_str, code_block.code);

        // Execute
        var exec = CodeExecutor.init(self.allocator, ExecutionConfig{});
        const result = exec.execute(code_block.code, language) catch |err| {
            const msg = try std.fmt.allocPrint(self.allocator, "Execution failed: {s}", .{@errorName(err)});
            defer self.allocator.free(msg);
            try nav.setMessage(self.allocator, msg, 120);
            return;
        };

        // Store result
        try self.execution_widget.setResult(result);

        // Update navigation message
        const msg = if (result.success())
            try std.fmt.allocPrint(self.allocator, "✓ Executed in {d}ms", .{result.execution_time_ms})
        else
            try std.fmt.allocPrint(self.allocator, "✗ Failed (exit: {d})", .{result.exit_code});
        defer self.allocator.free(msg);
        try nav.setMessage(self.allocator, msg, 120);
    }

    /// Render the UI using the Renderer
    fn render(self: *Self) !void {
        // Tick navigation to expire timed messages
        if (self.navigation) |*nav| {
            nav.tick(self.allocator);
        }

        const win = self.terminal.window();

        // Update transition manager
        const transition_just_completed = self.transition_manager.update();

        // If transition just completed, we need to capture the final slide
        if (transition_just_completed) {
            // Transition finished - normal rendering will show new slide
        }

        // Check if we're in a transition
        if (self.transition_manager.isTransitioning()) {
            // During transition, render to a temporary buffer first
            // Create a child window for the slide content
            const content_win = win.child(.{
                .x_off = 0,
                .y_off = 0,
                .width = win.width,
                .height = win.height,
            });

            // Render current state (which should be the "to" slide)
            try self.renderer.render(
                content_win,
                self.presentation,
                self.navigation,
                null, // Don't show execution during transition
                null, // Don't show help during transition
                self.current_theme,
            );

            // Capture the "to" slide if we haven't yet
            if (self.transition_manager.to_buffer) |to_buf| {
                // Skip if buffer is empty (e.g., zero window dimensions)
                if (to_buf.cells.len == 0) return;
                const first_cell = to_buf.cells[0];
                if (first_cell.char.grapheme.len == 0 and first_cell.style.fg == .default) {
                    self.transition_manager.completeTransition(content_win);
                }
            }

            // Render the transition
            self.transition_manager.render(win);
        } else {
            // Normal rendering
            try self.renderer.render(
                win,
                self.presentation,
                self.navigation,
                if (self.navigation) |nav| if (nav.show_execution) &self.execution_widget else null else null,
                if (self.navigation) |nav| if (nav.show_help) &self.help_widget else null else null,
                self.current_theme,
            );
        }

        // Draw overlay (laser pointer, drawings, theme picker)
        if (self.presentation != null and self.navigation != null) {
            // Get slide dimensions (approximate)
            const slide_width = win.width;
            const slide_height = if (win.height > 2) win.height - 2 else win.height; // Account for status bar

            self.overlay.draw(win, slide_width, slide_height);
        }

        // Draw config editor if active
        if (self.show_config_editor) {
            if (self.config_editor) |ce| {
                ce.draw(win);
            }
        }

        try self.terminal.render();
    }
};

test "App initialization" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Can't fully test App without TTY, but we can test the struct
    var app = App{
        .allocator = allocator,
        .terminal = undefined,
        .input_handler = InputHandler.init(allocator),
        .execution_widget = ExecutionWidget.init(allocator),
        .help_widget = HelpWidget.init(allocator),
        .overlay = PresentationOverlay.init(allocator),
        .transition_manager = transitions.TransitionManager.init(allocator),
        .remote_server = features.remote.RemoteServer.init(allocator, 8765),
        .remote_enabled = false,
        .media_player = features.media.MediaPlayer.init(allocator),
        .config_editor = null,
        .show_config_editor = false,
        .renderer = Renderer.init(allocator),
        .current_theme = darkTheme(),
    };

    app.input_handler.deinit();
    app.execution_widget.deinit();
    app.help_widget.deinit();
    app.overlay.deinit();
    app.transition_manager.deinit();
    app.remote_server.stop();
    app.media_player.deinit();
    app.renderer.deinit();
}
