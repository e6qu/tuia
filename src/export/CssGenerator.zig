//! CSS generator from themes
const std = @import("std");
const Theme = @import("../render/Theme.zig").Theme;
const Color = @import("../render/Theme.zig").Color;

/// Generates CSS from themes
pub const CssGenerator = struct {
    theme: Theme,

    const Self = @This();

    pub fn init(theme: Theme) Self {
        return .{
            .theme = theme,
        };
    }

    /// Generate complete CSS stylesheet
    pub fn generate(self: Self, allocator: std.mem.Allocator) ![]const u8 {
        var css: std.ArrayList(u8) = .empty;
        defer css.deinit(allocator);
        const writer = css.writer(allocator);

        // Base styles
        try writer.writeAll("* {\n");
        try writer.writeAll("    margin: 0;\n");
        try writer.writeAll("    padding: 0;\n");
        try writer.writeAll("    box-sizing: border-box;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("html, body {\n");
        try writer.writeAll("    height: 100%;\n");
        try writer.writeAll("    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;\n");
        try writer.writeAll("    line-height: 1.6;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll(".presentation {\n");
        try writer.writeAll("    height: 100vh;\n");
        try writer.writeAll("    overflow: hidden;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll(".slides {\n");
        try writer.writeAll("    height: 100%;\n");
        try writer.writeAll("    overflow-y: auto;\n");
        try writer.writeAll("    scroll-snap-type: y mandatory;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll(".slide {\n");
        try writer.writeAll("    min-height: 100vh;\n");
        try writer.writeAll("    display: flex;\n");
        try writer.writeAll("    align-items: center;\n");
        try writer.writeAll("    justify-content: center;\n");
        try writer.writeAll("    padding: 2rem;\n");
        try writer.writeAll("    scroll-snap-align: start;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll(".slide-content {\n");
        try writer.writeAll("    max-width: 1200px;\n");
        try writer.writeAll("    width: 100%;\n");
        try writer.writeAll("}\n\n");

        // Theme-specific styles
        try self.writeThemeStyles(writer);

        // Element styles
        try writer.writeAll("h1, h2, h3, h4, h5, h6 {\n");
        try writer.writeAll("    margin-bottom: 1rem;\n");
        try writer.writeAll("    font-weight: 600;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("h1 {\n");
        try writer.writeAll("    font-size: 3rem;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("h2 {\n");
        try writer.writeAll("    font-size: 2.5rem;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("h3 {\n");
        try writer.writeAll("    font-size: 2rem;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("p {\n");
        try writer.writeAll("    margin-bottom: 1rem;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("pre {\n");
        try writer.writeAll("    background: #f5f5f5;\n");
        try writer.writeAll("    padding: 1rem;\n");
        try writer.writeAll("    border-radius: 4px;\n");
        try writer.writeAll("    overflow-x: auto;\n");
        try writer.writeAll("    margin-bottom: 1rem;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("code {\n");
        try writer.writeAll("    font-family: 'Monaco', 'Menlo', 'Consolas', monospace;\n");
        try writer.writeAll("    font-size: 0.9em;\n");
        try writer.writeAll("    background: #f5f5f5;\n");
        try writer.writeAll("    padding: 0.2em 0.4em;\n");
        try writer.writeAll("    border-radius: 3px;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("pre code {\n");
        try writer.writeAll("    background: none;\n");
        try writer.writeAll("    padding: 0;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("ul, ol {\n");
        try writer.writeAll("    margin-left: 2rem;\n");
        try writer.writeAll("    margin-bottom: 1rem;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("li {\n");
        try writer.writeAll("    margin-bottom: 0.5rem;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("blockquote {\n");
        try writer.writeAll("    border-left: 4px solid #ddd;\n");
        try writer.writeAll("    padding-left: 1rem;\n");
        try writer.writeAll("    margin-left: 0;\n");
        try writer.writeAll("    margin-bottom: 1rem;\n");
        try writer.writeAll("    font-style: italic;\n");
        try writer.writeAll("    color: #666;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("hr {\n");
        try writer.writeAll("    border: none;\n");
        try writer.writeAll("    border-top: 2px solid #ddd;\n");
        try writer.writeAll("    margin: 2rem 0;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("a {\n");
        try writer.writeAll("    color: #0066cc;\n");
        try writer.writeAll("    text-decoration: none;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("a:hover {\n");
        try writer.writeAll("    text-decoration: underline;\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("img {\n");
        try writer.writeAll("    max-width: 100%;\n");
        try writer.writeAll("    height: auto;\n");
        try writer.writeAll("}\n\n");

        // Dark mode support
        try writer.writeAll("@media (prefers-color-scheme: dark) {\n");
        try writer.writeAll("    body {\n");
        try writer.writeAll("        background: #1a1a1a;\n");
        try writer.writeAll("        color: #e0e0e0;\n");
        try writer.writeAll("    }\n");
        try writer.writeAll("    \n");
        try writer.writeAll("    pre, code {\n");
        try writer.writeAll("        background: #2a2a2a;\n");
        try writer.writeAll("    }\n");
        try writer.writeAll("    \n");
        try writer.writeAll("    blockquote {\n");
        try writer.writeAll("        border-left-color: #444;\n");
        try writer.writeAll("        color: #999;\n");
        try writer.writeAll("    }\n");
        try writer.writeAll("    \n");
        try writer.writeAll("    hr {\n");
        try writer.writeAll("        border-top-color: #444;\n");
        try writer.writeAll("    }\n");
        try writer.writeAll("    \n");
        try writer.writeAll("    a {\n");
        try writer.writeAll("        color: #66b3ff;\n");
        try writer.writeAll("    }\n");
        try writer.writeAll("}\n");

        return css.toOwnedSlice(allocator);
    }

    fn writeThemeStyles(self: Self, writer: anytype) !void {
        // Convert theme colors to CSS
        try writer.writeAll("body {\n");

        // Background color from code_block bg (closest we have to page bg)
        if (self.theme.code_block.bg) |bg| {
            const color_str = colorToCss(bg);
            try writer.print("    background: {s};\n", .{color_str});
        }

        // Text color from paragraph fg
        if (self.theme.paragraph.fg) |fg| {
            const color_str = colorToCss(fg);
            try writer.print("    color: {s};\n", .{color_str});
        }

        try writer.writeAll("}\n\n");
    }
};

/// Convert theme color to CSS color string
fn colorToCss(color: Color) []const u8 {
    return switch (color) {
        .default => "inherit",
        .black => "#000000",
        .red => "#cd3131",
        .green => "#0dbc79",
        .yellow => "#e5e510",
        .blue => "#2472c8",
        .magenta => "#bc3fbc",
        .cyan => "#11a8cd",
        .white => "#e5e5e5",
        .bright_black => "#666666",
        .bright_red => "#f14c4c",
        .bright_green => "#23d18b",
        .bright_yellow => "#f5f543",
        .bright_blue => "#3b8eea",
        .bright_magenta => "#d670d6",
        .bright_cyan => "#29b8db",
        .bright_white => "#ffffff",
        .rgb => "rgb(128, 128, 128)", // Fallback for RGB
    };
}

test "CssGenerator basic" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const theme = @import("../render/Theme.zig").darkTheme();
    var generator = CssGenerator.init(theme);

    const css = try generator.generate(allocator);
    defer allocator.free(css);

    // Verify CSS contains expected content
    try testing.expect(std.mem.containsAtLeast(u8, css, 1, "html, body"));
    try testing.expect(std.mem.containsAtLeast(u8, css, 1, ".slide"));
    try testing.expect(std.mem.containsAtLeast(u8, css, 1, "h1"));
    try testing.expect(std.mem.containsAtLeast(u8, css, 1, "@media (prefers-color-scheme: dark)"));
}
