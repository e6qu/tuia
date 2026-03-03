//! HTML exporter for presentations
const std = @import("std");
const Presentation = @import("../core/Presentation.zig").Presentation;
const Slide = @import("../core/Slide.zig").Slide;
const Element = @import("../core/Element.zig").Element;
const Inline = @import("../core/Element.zig").Inline;
const Theme = @import("../render/Theme.zig").Theme;
const CssGenerator = @import("CssGenerator.zig").CssGenerator;
const inlineToPlainText = @import("../core/Element.zig").inlineToPlainText;

/// HTML exporter for generating static HTML presentations
pub const HtmlExporter = struct {
    allocator: std.mem.Allocator,
    theme: Theme,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, theme: Theme) Self {
        return .{
            .allocator = allocator,
            .theme = theme,
        };
    }

    /// Export presentation to HTML string
    pub fn exportToHtml(self: Self, presentation: Presentation) ![]const u8 {
        var output: std.ArrayList(u8) = .empty;
        defer output.deinit(self.allocator);
        const writer = output.writer(self.allocator);

        // Write HTML header
        try self.writeHeader(writer, presentation);

        // Write slides
        for (presentation.slides, 0..) |slide, i| {
            try self.writeSlide(writer, slide, i + 1);
        }

        // Write footer
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

        try writer.writeAll("<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n");
        try writer.writeAll("    <meta charset=\"UTF-8\">\n");
        try writer.writeAll("    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n");
        try writer.writeAll("    <title>");
        try writer.writeAll(title);
        try writer.writeAll("</title>\n");
        try writer.writeAll("    <style>\n");

        // Generate and write CSS
        var css_gen = CssGenerator.init(self.theme);
        const css = try css_gen.generate(self.allocator);
        defer self.allocator.free(css);
        try writer.writeAll(css);

        try writer.writeAll("    </style>\n");
        try writer.writeAll("</head>\n<body>\n");
        try writer.writeAll("    <div class=\"presentation\">\n");
        try writer.writeAll("        <div class=\"slides\">\n");
    }

    fn writeFooter(_: Self, writer: anytype) !void {
        try writer.writeAll("        </div>\n");
        try writer.writeAll("    </div>\n");
        try writer.writeAll("<script>\n");
        try writer.writeAll("    // Navigation\n");
        try writer.writeAll("    document.addEventListener('keydown', function(e) {\n");
        try writer.writeAll("        const slides = document.querySelectorAll('.slide');\n");
        try writer.writeAll("        let current = 0;\n");
        try writer.writeAll("        slides.forEach((slide, i) => {\n");
        try writer.writeAll("            if (slide.classList.contains('active')) current = i;\n");
        try writer.writeAll("        });\n");
        try writer.writeAll("        \n");
        try writer.writeAll("        if (e.key === 'ArrowRight' || e.key === ' ') {\n");
        try writer.writeAll("            e.preventDefault();\n");
        try writer.writeAll("            if (current < slides.length - 1) {\n");
        try writer.writeAll("                slides[current].classList.remove('active');\n");
        try writer.writeAll("                slides[current + 1].classList.add('active');\n");
        try writer.writeAll("                slides[current + 1].scrollIntoView({behavior: 'smooth'});\n");
        try writer.writeAll("            }\n");
        try writer.writeAll("        } else if (e.key === 'ArrowLeft') {\n");
        try writer.writeAll("            e.preventDefault();\n");
        try writer.writeAll("            if (current > 0) {\n");
        try writer.writeAll("                slides[current].classList.remove('active');\n");
        try writer.writeAll("                slides[current - 1].classList.add('active');\n");
        try writer.writeAll("                slides[current - 1].scrollIntoView({behavior: 'smooth'});\n");
        try writer.writeAll("            }\n");
        try writer.writeAll("        }\n");
        try writer.writeAll("    });\n");
        try writer.writeAll("    \n");
        try writer.writeAll("    // Initialize first slide\n");
        try writer.writeAll("    document.querySelector('.slide')?.classList.add('active');\n");
        try writer.writeAll("</script>\n");
        try writer.writeAll("</body>\n");
        try writer.writeAll("</html>\n");
    }

    fn writeSlide(self: Self, writer: anytype, slide: Slide, slide_num: usize) !void {
        try writer.print("            <div class=\"slide\" id=\"slide-{d}\">\n", .{slide_num});
        try writer.writeAll("                <div class=\"slide-content\">\n");

        for (slide.elements) |element| {
            try self.writeElement(writer, element);
        }

        try writer.writeAll("                </div>\n");
        try writer.writeAll("            </div>\n");
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
                const text = try inlineToPlainText(self.allocator, h.content);
                defer self.allocator.free(text);
                try writer.print("<{s}>{s}</{s}>\n", .{ tag, text, tag });
            },
            .paragraph => |p| {
                const text = try inlineToPlainText(self.allocator, p.content);
                defer self.allocator.free(text);
                try writer.writeAll("<p>");
                try writer.writeAll(text);
                try writer.writeAll("</p>\n");
            },
            .code_block => |cb| {
                try writer.writeAll("<pre><code");
                if (cb.language) |lang| {
                    try writer.print(" class=\"language-{s}\"", .{lang});
                }
                try writer.writeAll(">");
                try writeEscapedHtml(writer, cb.code);
                try writer.writeAll("</code></pre>\n");
            },
            .list => |list| {
                const tag = if (list.ordered) "ol" else "ul";
                try writer.print("<{s}>\n", .{tag});
                for (list.items) |item| {
                    const text = try inlineToPlainText(self.allocator, item.content);
                    defer self.allocator.free(text);
                    try writer.writeAll("<li>");
                    try writer.writeAll(text);
                    try writer.writeAll("</li>\n");
                }
                try writer.print("</{s}>\n", .{tag});
            },
            .blockquote => |bq| {
                const text = try inlineToPlainText(self.allocator, bq.content);
                defer self.allocator.free(text);
                try writer.writeAll("<blockquote>");
                try writer.writeAll(text);
                try writer.writeAll("</blockquote>\n");
            },
            .thematic_break => {
                try writer.writeAll("<hr>\n");
            },
            .image => |img| {
                try writer.print("<img src=\"{s}\" alt=\"{s}\">\n", .{ img.url, img.alt });
            },
            .table => |t| {
                try writer.writeAll("<table>\n");
                // Headers
                try writer.writeAll("<thead><tr>\n");
                for (t.headers) |header| {
                    const text = try inlineToPlainText(self.allocator, header.content);
                    defer self.allocator.free(text);
                    try writer.print("<th>{s}</th>\n", .{text});
                }
                try writer.writeAll("</tr></thead>\n");
                // Body
                try writer.writeAll("<tbody>\n");
                for (t.rows) |row| {
                    try writer.writeAll("<tr>\n");
                    for (row) |cell| {
                        const text = try inlineToPlainText(self.allocator, cell.content);
                        defer self.allocator.free(text);
                        try writer.print("<td>{s}</td>\n", .{text});
                    }
                    try writer.writeAll("</tr>\n");
                }
                try writer.writeAll("</tbody>\n");
                try writer.writeAll("</table>\n");
            },
        }
    }
};

/// Write text with HTML escaping
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

test "HtmlExporter basic" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Create a simple presentation
    var presentation = Presentation{
        .allocator = allocator,
        .metadata = .{
            .title = try allocator.dupe(u8, "Test Presentation"),
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

    // Create a slide with a heading
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

    // Export to HTML
    const theme = @import("../render/Theme.zig").darkTheme();
    var exporter = HtmlExporter.init(allocator, theme);
    const html = try exporter.exportToHtml(presentation);
    defer allocator.free(html);

    // Verify HTML contains expected content
    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "<!DOCTYPE html>"));
    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "Test Presentation"));
    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "Hello World"));
    try testing.expect(std.mem.containsAtLeast(u8, html, 1, "<h1>"));
}
