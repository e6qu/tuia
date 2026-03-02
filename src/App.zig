//! Main application state and event loop
const std = @import("std");
const vaxis = @import("vaxis");

const core = @import("core/root.zig");
const parser_module = @import("parser/root.zig");
const widgets = @import("widgets/root.zig");
const render = @import("render/root.zig");
const executor = @import("features/executor/root.zig");

const Presentation = core.Presentation;
const PresentationBuilder = core.PresentationBuilder;
const Navigation = core.Navigation;
const Parser = parser_module.Parser;
const convertPresentation = @import("parser/Converter.zig").convertPresentation;
const InputHandler = @import("core/InputHandler.zig").InputHandler;
const ExecutionWidget = @import("widgets/ExecutionWidget.zig").ExecutionWidget;
const HelpWidget = @import("widgets/HelpWidget.zig").HelpWidget;
const CodeExecutor = executor.CodeExecutor;
const ExecutionConfig = executor.ExecutionConfig;
const ExecutorRegistry = executor.ExecutorRegistry;
const Language = executor.Language;
const Renderer = render.Renderer;

const Event = union(enum) {
    key: vaxis.Key,
    winsize: vaxis.Winsize,
};

/// App manages the presentation application state and event loop
pub const App = struct {
    allocator: std.mem.Allocator,
    tty: vaxis.Tty,
    vx: vaxis.Vaxis,
    loop: vaxis.Loop(Event),

    // Presentation state
    presentation: ?Presentation = null,
    navigation: ?Navigation = null,
    input_handler: InputHandler,

    // Rendering
    renderer: Renderer,
    help_widget: HelpWidget,

    // Code execution
    execution_widget: ExecutionWidget,
    executor_registry: ?ExecutorRegistry = null,

    // Running state
    running: bool = true,

    const Self = @This();

    /// Initialize the application
    pub fn init(allocator: std.mem.Allocator) !Self {
        var tty_buffer: [4096]u8 = undefined;
        var tty = try vaxis.Tty.init(&tty_buffer);

        var vx = try vaxis.init(allocator, .{});

        var loop: vaxis.Loop(Event) = .{
            .tty = &tty,
            .vaxis = &vx,
        };
        try loop.init();

        return .{
            .allocator = allocator,
            .tty = tty,
            .vx = vx,
            .loop = loop,
            .input_handler = InputHandler.init(allocator),
            .execution_widget = ExecutionWidget.init(allocator),
            .help_widget = HelpWidget.init(allocator),
            .renderer = Renderer.init(allocator),
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
        self.input_handler.deinit();
        self.loop.stop();
        self.vx.deinit(self.allocator, self.tty.writer());
        self.tty.deinit();
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
        try self.vx.enterAltScreen(self.tty.writer());
        try self.vx.queryTerminal(self.tty.writer(), 1 * std.time.ns_per_s);

        try self.loop.start();

        while (self.running) {
            const event = self.loop.nextEvent();
            try self.handleEvent(event);
            try self.render();
        }
    }

    /// Handle an event
    fn handleEvent(self: *Self, event: Event) !void {
        switch (event) {
            .key => |key| {
                try self.handleKey(key);
            },
            .winsize => |ws| {
                try self.vx.resize(self.allocator, self.tty.writer(), ws);
            },
        }
    }

    /// Handle a key press
    fn handleKey(self: *Self, key: vaxis.Key) !void {
        const nav = &self.navigation.?;

        // Check for quit
        if (key.codepoint == 'c' and key.mods.ctrl) {
            self.running = false;
            return;
        }

        // Handle input
        const should_quit = try self.input_handler.handleKey(key, nav, self.allocator);
        if (should_quit) {
            self.running = false;
            return;
        }

        // Check if code execution was requested
        // This is a bit hacky - we need a better way to signal this
        // For now, check if 'e' was pressed and we're not in jump mode
        if (key.codepoint == 'e' and !self.input_handler.isInJumpMode()) {
            try self.executeCurrentCodeBlock();
        }
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
        const win = self.vx.window();

        // Use renderer to render everything
        try self.renderer.render(
            win,
            self.presentation,
            self.navigation,
            if (self.navigation) |nav| if (nav.show_execution) &self.execution_widget else null else null,
            if (self.navigation) |nav| if (nav.show_help) &self.help_widget else null else null,
        );

        try self.vx.render(self.tty.writer());
    }
};

test "App initialization" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Can't fully test App without TTY, but we can test the struct
    var app = App{
        .allocator = allocator,
        .tty = undefined,
        .vx = undefined,
        .loop = undefined,
        .input_handler = InputHandler.init(allocator),
        .execution_widget = ExecutionWidget.init(allocator),
    };

    app.input_handler.deinit();
    app.execution_widget.deinit();
}
