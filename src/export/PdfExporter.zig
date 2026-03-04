//! PDF exporter for presentations
//! Generates LaTeX source (.tex) that users can compile to PDF with pdflatex
const std = @import("std");
const Presentation = @import("../core/Presentation.zig").Presentation;
const BeamerExporter = @import("BeamerExporter.zig").BeamerExporter;

/// PDF exporter that generates LaTeX source for manual PDF compilation
/// Note: This exporter generates a .tex file. Users need to have TeX Live
/// installed and run `pdflatex file.tex` to generate the actual PDF.
pub const PdfExporter = struct {
    allocator: std.mem.Allocator,
    theme: ?[]const u8,
    color_theme: ?[]const u8,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, theme: ?[]const u8, color_theme: ?[]const u8) Self {
        return .{
            .allocator = allocator,
            .theme = theme,
            .color_theme = color_theme,
        };
    }

    /// Export presentation to a .tex file that can be compiled to PDF
    /// The output file will have .tex extension (not .pdf)
    pub fn exportToFile(self: Self, presentation: Presentation, path: []const u8) !void {
        // Generate LaTeX source
        var beamer_exporter = BeamerExporter.init(self.allocator, self.theme, self.color_theme);
        const latex = try beamer_exporter.exportToLatex(presentation);
        defer self.allocator.free(latex);

        // Ensure .tex extension
        const tex_path = try self.getTexPath(path);
        defer self.allocator.free(tex_path);

        // Write .tex file
        const tex_file = try std.fs.cwd().createFile(tex_path, .{});
        defer tex_file.close();
        try tex_file.writeAll(latex);

        std.debug.print("LaTeX source saved to: {s}\n", .{tex_path});
        std.debug.print("To generate PDF, install TeX Live and run: pdflatex {s}\n", .{tex_path});
    }

    /// Get the .tex path from the input path
    fn getTexPath(self: Self, input_path: []const u8) ![]const u8 {
        // If path ends with .pdf, replace with .tex
        if (std.mem.endsWith(u8, input_path, ".pdf")) {
            const base = input_path[0 .. input_path.len - 4];
            return try std.mem.concat(self.allocator, u8, &.{ base, ".tex" });
        }
        // Otherwise just add .tex
        if (std.mem.endsWith(u8, input_path, ".tex")) {
            return try self.allocator.dupe(u8, input_path);
        }
        return try std.mem.concat(self.allocator, u8, &.{ input_path, ".tex" });
    }

    /// Returns false - PDF compilation requires external pdflatex tool
    pub fn isAvailable() bool {
        return false;
    }
};

// ============== Tests ==============

test "PdfExporter generates LaTeX source" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var presentation = Presentation{
        .allocator = allocator,
        .metadata = .{
            .title = try allocator.dupe(u8, "PDF Test"),
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
    heading_content[0] = .{ .text = try allocator.dupe(u8, "Hello PDF") };

    try elements.append(allocator, .{ .heading = .{
        .content = heading_content,
        .level = 1,
    } });

    presentation.slides[0] = Slide{
        .elements = try elements.toOwnedSlice(allocator),
        .speaker_notes = null,
    };

    // Create temp directory for test
    var tmp_dir = std.testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    const tmp_path = try tmp_dir.dir.realpathAlloc(allocator, ".");
    defer allocator.free(tmp_path);

    const pdf_path = try std.fs.path.join(allocator, &.{ tmp_path, "test.pdf" });
    defer allocator.free(pdf_path);

    var exporter = PdfExporter.init(allocator, null, null);
    try exporter.exportToFile(presentation, pdf_path);

    // Verify .tex file was created
    const tex_path = try std.fs.path.join(allocator, &.{ tmp_path, "test.tex" });
    defer allocator.free(tex_path);

    const tex_file = try std.fs.cwd().openFile(tex_path, .{});
    defer tex_file.close();

    const stat = try tex_file.stat();
    try testing.expect(stat.size > 0);

    // Read and verify content
    const content = try allocator.alloc(u8, stat.size);
    defer allocator.free(content);
    _ = try tex_file.readAll(content);

    try testing.expect(std.mem.containsAtLeast(u8, content, 1, "\\documentclass"));
    try testing.expect(std.mem.containsAtLeast(u8, content, 1, "Hello PDF"));
}

const Slide = @import("../core/Slide.zig").Slide;
const Element = @import("../core/Element.zig").Element;
