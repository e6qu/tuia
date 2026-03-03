//! Reveal.js exporter for presentations
const std = @import("std");
const Presentation = @import("../core/Presentation.zig").Presentation;
const Slide = @import("../core/Slide.zig").Slide;
const Element = @import("../core/Element.zig").Element;
const inlineToPlainText = @import("../core/Element.zig").inlineToPlainText;

/// Reveal.js exporter for generating web-based presentations
pub const RevealJsExporter = struct {
    allocator: std.mem.Allocator,
    theme: ?[]const u8,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, theme: ?[]const u8) Self {
        return .{
            .allocator = allocator,
            .theme = theme,
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
        const reveal_theme = self.theme orelse "black";

        try writer.writeAll("<!DOCTYPE html>\n");
        try writer.writeAll("<html lang=\"en\">\n");
        try writer.writeAll("<head>\n");
        try writer.writeAll("    <meta charset=\"UTF-8\">\n");
        try writer.writeAll("    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n");
        try writer.writeAll("    <title>");
        try writer.writeAll(title);
        try writer.writeAll("</title>\n");
        try writer.writeAll("    <link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/reveal.js@4.5.0/dist/reveal.css\">\n");
        try writer.writeAll("    <link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/reveal.js@4.5.0/dist/theme/");
        try writer.writeAll(reveal_theme);
        try writer.writeAll(".css\">\n");
        try writer.writeAll("    <style>\n");
        try writer.writeAll("        .reveal section img {\n");
        try writer.writeAll("            border: none;\n");
        try writer.writeAll("            box-shadow: none;\n");
        try writer.writeAll("            max-height: 70vh;\n");
        try writer.writeAll("        }\n");
        try writer.writeAll("        .reveal pre {\n");
        try writer.writeAll("            font-size: 0.55em;\n");
        try writer.writeAll("        }\n");
        try writer.writeAll("        .reveal code {\n");
        try writer.writeAll("            font-family: 'Fira Code', 'Consolas', monospace;\n");
        try writer.writeAll("        }\n");
        try writer.writeAll("    </style>\n");

        if (author) |a| {
            try writer.writeAll("    <meta name=\"author\" content=\"");
            try writeEscapedHtml(writer, a);
            try writer.writeAll("\">\n");
        }

        try writer.writeAll("</head>\n");
        try writer.writeAll("<body>\n");
        try writer.writeAll("    <div class=\"reveal\">\n");
        try writer.writeAll("        <div class=\"slides\">\n");
    }

    fn writeFooter(_: Self, writer: anytype) !void {
        try writer.writeAll("        </div>\n");
        try writer.writeAll("    </div>\n");
        try writer.writeAll("    <script src=\"https://cdn.jsdelivr.net/npm/reveal.js@4.5.0/dist/reveal.js\"></script>\n");
        try writer.writeAll("    <script>\n");
        try writer.writeAll("        Reveal.initialize({\n");
        try writer.writeAll("            hash: true,\n");
        try writer.writeAll("            slideNumber: 'c/t',\n");
        try writer.writeAll("            showSlideNumber: 'all',\n");
        try writer.writeAll("            transition: 'slide',\n");
        try writer.writeAll("            backgroundTransition: 'fade'\n");
        try writer.writeAll("        });\n");
        try writer.writeAll("    </script>\n");
        try writer.writeAll("</body>\n");
        try writer.writeAll("</html>\n");
    }

    fn writeSlide(self: Self, writer: anytype, slide: Slide, slide_num: usize) !void {
        _ = slide_num;
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
                    try writer.writeAll("\" data-trim data-noescape");
                }
                try writer.writeAll(">");
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
                try writer.writeAll(img.url);
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
                    try writer.writeAll(l.url);
                    try writer.writeAll("\">");
                    try self.writeInlines(writer, l.content);
                    try writer.writeAll("</a>");
                },
                .image => |img| {
                    try writer.writeAll("<img src=\"");
                    try writer.writeAll(img.url);
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

    var exporter = RevealJsExporter.init(allocator, null);
    const html = try exporter.exportToHtml(presentation);
    defer allocator.free(html);

    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "<!DOCTYPE html>"));
    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "Test Presentation"));
    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "reveal.js"));
    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "<section>"));
    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "Hello World"));
}
