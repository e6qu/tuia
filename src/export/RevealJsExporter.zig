//! Reveal.js exporter for presentations
const std = @import("std");
const Presentation = @import("../core/Presentation.zig").Presentation;
const Slide = @import("../core/Slide.zig").Slide;
const Element = @import("../core/Element.zig").Element;
const inlineToPlainText = @import("../core/Element.zig").inlineToPlainText;

/// Reveal.js export configuration
pub const RevealJsConfig = struct {
    /// Reveal.js theme (black, white, league, beige, sky, night, serif, simple, solarized, blood, moon)
    theme: []const u8 = "black",

    /// Slide transition style
    transition: Transition = .slide,

    /// Background transition style
    background_transition: BackgroundTransition = .fade,

    /// Enable slide numbers
    slide_number: SlideNumber = .c_t,

    /// Enable speaker notes
    enable_notes: bool = true,

    /// Enable code highlighting with highlight.js
    enable_highlight: bool = true,

    /// Enable search plugin
    enable_search: bool = true,

    /// Enable zoom plugin
    enable_zoom: bool = true,

    /// Self-contained mode (inline all resources)
    self_contained: bool = false,

    /// Enable PDF export support
    enable_pdf: bool = true,

    /// Transition speed
    transition_speed: TransitionSpeed = .default,

    /// Auto-slide (0 = disabled)
    auto_slide: u32 = 0,

    /// Loop presentation
    loop: bool = false,

    /// Show controls
    controls: bool = true,

    /// Show progress bar
    progress: bool = true,

    /// Center slides vertically
    center: bool = true,

    /// Enable touch/swipe
    touch: bool = true,

    /// Show navigation arrows
    navigation_mode: NavigationMode = .default,

    /// Fragment default animation
    fragment_default: FragmentAnimation = .fade_in,

    pub const Transition = enum {
        none,
        fade,
        slide,
        convex,
        concave,
        zoom,

        pub fn toString(self: Transition) []const u8 {
            return switch (self) {
                .none => "none",
                .fade => "fade",
                .slide => "slide",
                .convex => "convex",
                .concave => "concave",
                .zoom => "zoom",
            };
        }
    };

    pub const BackgroundTransition = enum {
        none,
        fade,
        slide,
        convex,
        concave,
        zoom,

        pub fn toString(self: BackgroundTransition) []const u8 {
            return switch (self) {
                .none => "none",
                .fade => "fade",
                .slide => "slide",
                .convex => "convex",
                .concave => "concave",
                .zoom => "zoom",
            };
        }
    };

    pub const SlideNumber = enum {
        none,
        h_v,
        h_slash_v,
        c,
        c_slash_t,
        c_t,

        pub fn toString(self: SlideNumber) []const u8 {
            return switch (self) {
                .none => "false",
                .h_v => "h.v",
                .h_slash_v => "h/v",
                .c => "c",
                .c_slash_t => "c/t",
                .c_t => "c/t",
            };
        }
    };

    pub const TransitionSpeed = enum {
        default,
        fast,
        slow,

        pub fn toString(self: TransitionSpeed) []const u8 {
            return switch (self) {
                .default => "default",
                .fast => "fast",
                .slow => "slow",
            };
        }
    };

    pub const NavigationMode = enum {
        default,
        linear,
        grid,

        pub fn toString(self: NavigationMode) []const u8 {
            return switch (self) {
                .default => "default",
                .linear => "linear",
                .grid => "grid",
            };
        }
    };

    pub const FragmentAnimation = enum {
        fade_in,
        fade_out,
        fade_up,
        fade_down,
        fade_left,
        fade_right,
        fade_in_then_out,
        fade_in_then_semi_out,
        grow,
        shrink,
        strike,
        highlight_current_blue,
        highlight_red,
        highlight_green,
        highlight_blue,

        pub fn toString(self: FragmentAnimation) []const u8 {
            return switch (self) {
                .fade_in => "fade-in",
                .fade_out => "fade-out",
                .fade_up => "fade-up",
                .fade_down => "fade-down",
                .fade_left => "fade-left",
                .fade_right => "fade-right",
                .fade_in_then_out => "fade-in-then-out",
                .fade_in_then_semi_out => "fade-in-then-semi-out",
                .grow => "grow",
                .shrink => "shrink",
                .strike => "strike",
                .highlight_current_blue => "highlight-current-blue",
                .highlight_red => "highlight-red",
                .highlight_green => "highlight-green",
                .highlight_blue => "highlight-blue",
            };
        }
    };
};

/// Reveal.js exporter for generating web-based presentations
pub const RevealJsExporter = struct {
    allocator: std.mem.Allocator,
    config: RevealJsConfig,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, config: RevealJsConfig) Self {
        return .{
            .allocator = allocator,
            .config = config,
        };
    }

    /// Export presentation to Reveal.js HTML string
    pub fn exportToHtml(self: Self, presentation: Presentation) ![]const u8 {
        var output: std.ArrayList(u8) = .empty;
        defer output.deinit(self.allocator);
        const writer = output.writer(self.allocator);

        try self.writeHeader(writer, presentation);

        for (presentation.slides, 0..) |slide, i| {
            try self.writeSlide(writer, slide, i + 1);
        }

        try self.writeFooter(writer);

        return output.toOwnedSlice(self.allocator);
    }

    /// Export presentation to HTML file
    pub fn exportToFile(self: Self, presentation: Presentation, path: []const u8) !void {
        const html = try self.exportToHtml(presentation);
        defer self.allocator.free(html);

        const file = try std.fs.cwd().createFile(path, .{});
        defer file.close();

        try file.writeAll(html);
    }

    fn writeHeader(self: Self, writer: anytype, presentation: Presentation) !void {
        const title = if (presentation.metadata.title) |t| t else "Presentation";
        const author = if (presentation.metadata.author) |a| a else null;

        try writer.writeAll("<!DOCTYPE html>\n");
        try writer.writeAll("<html lang=\"en\">\n");
        try writer.writeAll("<head>\n");
        try writer.writeAll("    <meta charset=\"UTF-8\">\n");
        try writer.writeAll("    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n");
        try writer.writeAll("    <title>");
        try writer.writeAll(title);
        try writer.writeAll("</title>\n");

        // Reveal.js core CSS
        try writer.writeAll("    <link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/reveal.js@4.5.0/dist/reveal.css\">\n");
        try writer.writeAll("    <link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/reveal.js@4.5.0/dist/theme/");
        try writer.writeAll(self.config.theme);
        try writer.writeAll(".css\">\n");

        // Highlight.js for code syntax highlighting
        if (self.config.enable_highlight) {
            try writer.writeAll("    <link rel=\"stylesheet\" href=\"https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css\">\n");
        }

        // Custom styles
        try writer.writeAll("    <style>\n");
        try writer.writeAll("        .reveal section img {\n");
        try writer.writeAll("            border: none;\n");
        try writer.writeAll("            box-shadow: none;\n");
        try writer.writeAll("            max-height: 70vh;\n");
        try writer.writeAll("        }\n");
        try writer.writeAll("        .reveal pre {\n");
        try writer.writeAll("            font-size: 0.55em;\n");
        try writer.writeAll("            width: 100%;\n");
        try writer.writeAll("        }\n");
        try writer.writeAll("        .reveal code {\n");
        try writer.writeAll("            font-family: 'Fira Code', 'Consolas', monospace;\n");
        try writer.writeAll("        }\n");
        try writer.writeAll("        .reveal .slides {\n");
        try writer.writeAll("            text-align: left;\n");
        try writer.writeAll("        }\n");
        try writer.writeAll("        .reveal h1, .reveal h2, .reveal h3 {\n");
        try writer.writeAll("            text-transform: none;\n");
        try writer.writeAll("        }\n");

        // PDF export styles
        if (self.config.enable_pdf) {
            try writer.writeAll("        @media print {\n");
            try writer.writeAll("            .reveal .slides {\n");
            try writer.writeAll("                text-align: left !important;\n");
            try writer.writeAll("            }\n");
            try writer.writeAll("        }\n");
        }

        try writer.writeAll("    </style>\n");

        if (author) |a| {
            try writer.writeAll("    <meta name=\"author\" content=\"");
            try writeEscapedHtml(writer, a);
            try writer.writeAll("\">\n");
        }

        // PDF export hint
        if (self.config.enable_pdf) {
            try writer.writeAll("    <!-- PDF Export: Add ?print-pdf to URL and print to PDF -->\n");
        }

        try writer.writeAll("</head>\n");
        try writer.writeAll("<body>\n");
        try writer.writeAll("    <div class=\"reveal\">\n");
        try writer.writeAll("        <div class=\"slides\">\n");
    }

    fn writeFooter(self: Self, writer: anytype) !void {
        try writer.writeAll("        </div>\n");
        try writer.writeAll("    </div>\n");

        // Reveal.js core
        try writer.writeAll("    <script src=\"https://cdn.jsdelivr.net/npm/reveal.js@4.5.0/dist/reveal.js\"></script>\n");

        // Plugins
        if (self.config.enable_notes) {
            try writer.writeAll("    <script src=\"https://cdn.jsdelivr.net/npm/reveal.js@4.5.0/plugin/notes/notes.js\"></script>\n");
        }
        if (self.config.enable_highlight) {
            try writer.writeAll("    <script src=\"https://cdn.jsdelivr.net/npm/reveal.js@4.5.0/plugin/highlight/highlight.js\"></script>\n");
        }
        if (self.config.enable_search) {
            try writer.writeAll("    <script src=\"https://cdn.jsdelivr.net/npm/reveal.js@4.5.0/plugin/search/search.js\"></script>\n");
        }
        if (self.config.enable_zoom) {
            try writer.writeAll("    <script src=\"https://cdn.jsdelivr.net/npm/reveal.js@4.5.0/plugin/zoom/zoom.js\"></script>\n");
        }

        // Reveal.js initialization
        try writer.writeAll("    <script>\n");
        try writer.writeAll("        Reveal.initialize({\n");

        // Core options
        try writer.writeAll("            hash: true,\n");
        try writer.writeAll("            slideNumber: '");
        try writer.writeAll(self.config.slide_number.toString());
        try writer.writeAll("',\n");
        try writer.writeAll("            showSlideNumber: 'all',\n");
        try writer.writeAll("            transition: '");
        try writer.writeAll(self.config.transition.toString());
        try writer.writeAll("',\n");
        try writer.writeAll("            backgroundTransition: '");
        try writer.writeAll(self.config.background_transition.toString());
        try writer.writeAll("',\n");
        try writer.writeAll("            transitionSpeed: '");
        try writer.writeAll(self.config.transition_speed.toString());
        try writer.writeAll("',\n");
        try writer.writeAll("            controls: ");
        try writer.writeAll(if (self.config.controls) "true" else "false");
        try writer.writeAll(",\n");
        try writer.writeAll("            progress: ");
        try writer.writeAll(if (self.config.progress) "true" else "false");
        try writer.writeAll(",\n");
        try writer.writeAll("            center: ");
        try writer.writeAll(if (self.config.center) "true" else "false");
        try writer.writeAll(",\n");
        try writer.writeAll("            touch: ");
        try writer.writeAll(if (self.config.touch) "true" else "false");
        try writer.writeAll(",\n");
        try writer.writeAll("            loop: ");
        try writer.writeAll(if (self.config.loop) "true" else "false");
        try writer.writeAll(",\n");
        try writer.writeAll("            navigationMode: '");
        try writer.writeAll(self.config.navigation_mode.toString());
        try writer.writeAll("',\n");

        if (self.config.auto_slide > 0) {
            try writer.print("            autoSlide: {d},\n", .{self.config.auto_slide});
        }

        // Plugins
        try writer.writeAll("            plugins: [");
        var first = true;
        if (self.config.enable_notes) {
            if (!first) try writer.writeAll(", ");
            try writer.writeAll("RevealNotes");
            first = false;
        }
        if (self.config.enable_highlight) {
            if (!first) try writer.writeAll(", ");
            try writer.writeAll("RevealHighlight");
            first = false;
        }
        if (self.config.enable_search) {
            if (!first) try writer.writeAll(", ");
            try writer.writeAll("RevealSearch");
            first = false;
        }
        if (self.config.enable_zoom) {
            if (!first) try writer.writeAll(", ");
            try writer.writeAll("RevealZoom");
            first = false;
        }
        try writer.writeAll("]\n");

        try writer.writeAll("        });\n");

        // Keyboard shortcuts help
        try writer.writeAll("\n");
        try writer.writeAll("        // Keyboard shortcut help\n");
        try writer.writeAll("        console.log('Keyboard Shortcuts:');\n");
        try writer.writeAll("        console.log('  ? - Show help');\n");
        try writer.writeAll("        console.log('  f - Fullscreen');\n");
        try writer.writeAll("        console.log('  s - Speaker view');\n");
        try writer.writeAll("        console.log('  o - Overview mode');\n");
        if (self.config.enable_pdf) {
            try writer.writeAll("        console.log('  Add ?print-pdf to URL for PDF export');\n");
        }

        try writer.writeAll("    </script>\n");
        try writer.writeAll("</body>\n");
        try writer.writeAll("</html>\n");
    }

    fn writeSlide(self: Self, writer: anytype, slide: Slide, slide_num: usize) !void {
        _ = slide_num;

        // Start section with optional attributes
        try writer.writeAll("            <section>\n");

        for (slide.elements) |element| {
            try self.writeElement(writer, element);
        }

        if (slide.speaker_notes) |notes| {
            try writer.writeAll("                <aside class=\"notes\">\n");
            try writeEscapedHtml(writer, notes);
            try writer.writeAll("\n                </aside>\n");
        }

        try writer.writeAll("            </section>\n");
    }

    fn writeElement(self: Self, writer: anytype, element: Element) !void {
        switch (element) {
            .heading => |h| {
                const tag = switch (h.level) {
                    1 => "h1",
                    2 => "h2",
                    3 => "h3",
                    4 => "h4",
                    5 => "h5",
                    else => "h6",
                };
                try writer.writeAll("                <");
                try writer.writeAll(tag);
                try writer.writeAll(">");
                try self.writeInlines(writer, h.content);
                try writer.writeAll("</");
                try writer.writeAll(tag);
                try writer.writeAll(">\n");
            },
            .paragraph => |p| {
                try writer.writeAll("                <p>");
                try self.writeInlines(writer, p.content);
                try writer.writeAll("</p>\n");
            },
            .code_block => |cb| {
                try writer.writeAll("                <pre><code");
                if (cb.language) |lang| {
                    try writer.writeAll(" class=\"language-");
                    try writer.writeAll(lang);
                    try writer.writeAll("\"");
                }
                try writer.writeAll(" data-trim data-noescape>");
                try writeEscapedHtml(writer, cb.code);
                try writer.writeAll("</code></pre>\n");
            },
            .list => |list| {
                const tag = if (list.ordered) "ol" else "ul";
                try writer.writeAll("                <");
                try writer.writeAll(tag);
                try writer.writeAll(">\n");

                for (list.items) |item| {
                    try writer.writeAll("                    <li>");
                    try self.writeInlines(writer, item.content);
                    try writer.writeAll("</li>\n");
                }

                try writer.writeAll("                </");
                try writer.writeAll(tag);
                try writer.writeAll(">\n");
            },
            .blockquote => |bq| {
                try writer.writeAll("                <blockquote>");
                try self.writeInlines(writer, bq.content);
                try writer.writeAll("</blockquote>\n");
            },
            .thematic_break => {
                try writer.writeAll("                <hr>\n");
            },
            .image => |img| {
                try writer.writeAll("                <img src=\"");
                try writeEscapedHtml(writer, img.url);
                try writer.writeAll("\" alt=\"");
                try writeEscapedHtml(writer, img.alt);
                try writer.writeAll("\">\n");
            },
            .table => |t| {
                try writer.writeAll("                <table>\n");
                try writer.writeAll("                    <thead><tr>\n");
                for (t.headers) |header| {
                    try writer.writeAll("                        <th>");
                    try self.writeInlines(writer, header.content);
                    try writer.writeAll("</th>\n");
                }
                try writer.writeAll("                    </tr></thead>\n");
                try writer.writeAll("                    <tbody>\n");
                for (t.rows) |row| {
                    try writer.writeAll("                        <tr>\n");
                    for (row) |cell| {
                        try writer.writeAll("                            <td>");
                        try self.writeInlines(writer, cell.content);
                        try writer.writeAll("</td>\n");
                    }
                    try writer.writeAll("                        </tr>\n");
                }
                try writer.writeAll("                    </tbody>\n");
                try writer.writeAll("                </table>\n");
            },
            .media => |m| {
                if (m.media_type == .audio) {
                    try writer.writeAll("                <audio");
                    if (m.autoplay) try writer.writeAll(" autoplay");
                    if (m.loop) try writer.writeAll(" loop");
                    if (m.controls) try writer.writeAll(" controls");
                    try writer.writeAll(" src=\"");
                    try writeEscapedHtml(writer, m.url);
                    try writer.writeAll("\"></audio>\n");
                } else {
                    try writer.writeAll("                <video");
                    if (m.autoplay) try writer.writeAll(" autoplay");
                    if (m.loop) try writer.writeAll(" loop");
                    if (m.controls) try writer.writeAll(" controls");
                    try writer.writeAll(" src=\"");
                    try writeEscapedHtml(writer, m.url);
                    try writer.writeAll("\"></video>\n");
                }
            },
        }
    }

    fn writeInlines(self: Self, writer: anytype, inlines: []const @import("../core/Element.zig").Inline) !void {
        for (inlines) |inline_elem| {
            switch (inline_elem) {
                .text => |t| try writeEscapedHtml(writer, t),
                .code => |c| {
                    try writer.writeAll("<code>");
                    try writeEscapedHtml(writer, c);
                    try writer.writeAll("</code>");
                },
                .bold => |b| {
                    try writer.writeAll("<strong>");
                    try self.writeInlines(writer, b);
                    try writer.writeAll("</strong>");
                },
                .italic => |i| {
                    try writer.writeAll("<em>");
                    try self.writeInlines(writer, i);
                    try writer.writeAll("</em>");
                },
                .link => |l| {
                    try writer.writeAll("<a href=\"");
                    try writeEscapedHtml(writer, l.url);
                    try writer.writeAll("\">");
                    try self.writeInlines(writer, l.content);
                    try writer.writeAll("</a>");
                },
                .image => |img| {
                    try writer.writeAll("<img src=\"");
                    try writeEscapedHtml(writer, img.url);
                    try writer.writeAll("\" alt=\"");
                    try writeEscapedHtml(writer, img.alt);
                    try writer.writeAll("\">");
                },
            }
        }
    }
};

fn writeEscapedHtml(writer: anytype, text: []const u8) !void {
    for (text) |c| {
        switch (c) {
            '<' => try writer.writeAll("&lt;"),
            '>' => try writer.writeAll("&gt;"),
            '&' => try writer.writeAll("&amp;"),
            '"' => try writer.writeAll("&quot;"),
            '\'' => try writer.writeAll("&#x27;"),
            else => try writer.writeByte(c),
        }
    }
}

test "RevealJsExporter basic" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var presentation = Presentation{
        .allocator = allocator,
        .metadata = .{
            .title = try allocator.dupe(u8, "Test Presentation"),
            .author = try allocator.dupe(u8, "Test Author"),
            .date = null,
            .theme = null,
        },
        .slides = try allocator.alloc(Slide, 1),
    };
    defer {
        presentation.metadata.deinit(allocator);
        for (presentation.slides) |slide| {
            slide.deinit(allocator);
        }
        allocator.free(presentation.slides);
    }

    var elements: std.ArrayList(Element) = .empty;
    defer elements.deinit(allocator);

    const heading_content = try allocator.alloc(@import("../core/Element.zig").Inline, 1);
    heading_content[0] = .{ .text = try allocator.dupe(u8, "Hello World") };

    try elements.append(allocator, .{ .heading = .{
        .content = heading_content,
        .level = 1,
    } });

    presentation.slides[0] = Slide{
        .elements = try elements.toOwnedSlice(allocator),
        .speaker_notes = null,
    };

    const config = RevealJsConfig{};
    var exporter = RevealJsExporter.init(allocator, config);
    const html = try exporter.exportToHtml(presentation);
    defer allocator.free(html);

    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "<!DOCTYPE html>"));
    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "Test Presentation"));
    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "reveal.js"));
    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "<section>"));
    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "Hello World"));
    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "RevealNotes"));
    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "RevealHighlight"));
}

test "RevealJsExporter with custom config" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var presentation = Presentation{
        .allocator = allocator,
        .metadata = .{
            .title = try allocator.dupe(u8, "Custom Config Test"),
            .author = null,
            .date = null,
            .theme = null,
        },
        .slides = try allocator.alloc(Slide, 1),
    };
    defer {
        presentation.metadata.deinit(allocator);
        for (presentation.slides) |slide| {
            slide.deinit(allocator);
        }
        allocator.free(presentation.slides);
    }

    presentation.slides[0] = Slide{
        .elements = try allocator.alloc(Element, 0),
        .speaker_notes = null,
    };

    const config = RevealJsConfig{
        .theme = "white",
        .transition = .fade,
        .enable_notes = false,
        .enable_highlight = false,
    };

    var exporter = RevealJsExporter.init(allocator, config);
    const html = try exporter.exportToHtml(presentation);
    defer allocator.free(html);

    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "theme/white.css"));
    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "transition: 'fade'"));
    try testing.expect(!std.mem.containsAtLeast(u8, html, 1, "RevealNotes"));
}
