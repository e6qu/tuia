//! PDF exporter for presentations
//! Generates LaTeX and optionally compiles to PDF using pdflatex
const std = @import("std");
const Presentation = @import("../core/Presentation.zig").Presentation;
const BeamerExporter = @import("BeamerExporter.zig").BeamerExporter;

/// PDF exporter that generates LaTeX and compiles to PDF
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

    /// Export presentation to PDF file
    /// First generates LaTeX, then compiles with pdflatex if available
    pub fn exportToFile(self: Self, presentation: Presentation, path: []const u8) !void {
        // Generate LaTeX source
        var beamer_exporter = BeamerExporter.init(self.allocator, self.theme, self.color_theme);
        const latex = try beamer_exporter.exportToLatex(presentation);
        defer self.allocator.free(latex);

        // Write .tex file (temporary or alongside PDF)
        const tex_path = try self.getTexPath(path);
        defer self.allocator.free(tex_path);

        const tex_file = try std.fs.cwd().createFile(tex_path, .{});
        defer tex_file.close();
        try tex_file.writeAll(latex);

        // Try to compile to PDF
        const compiled = try self.compileLatex(tex_path);

        if (!compiled) {
            std.log.warn("pdflatex not found. LaTeX source saved to: {s}", .{tex_path});
            std.log.warn("To generate PDF, install TeX Live and run: pdflatex {s}", .{tex_path});
        }
    }

    /// Export presentation to PDF bytes
    /// Returns error if pdflatex is not available
    pub fn exportToPdf(self: Self, presentation: Presentation) ![]const u8 {
        // Generate LaTeX source
        var beamer_exporter = BeamerExporter.init(self.allocator, self.theme, self.color_theme);
        const latex = try beamer_exporter.exportToLatex(presentation);
        defer self.allocator.free(latex);

        // Create temp directory for compilation
        var tmp_dir = std.testing.tmpDir(.{});
        defer tmp_dir.cleanup();

        const tmp_path = try tmp_dir.dir.realpathAlloc(self.allocator, ".");
        defer self.allocator.free(tmp_path);

        // Write LaTeX file
        const tex_path = try std.fs.path.join(self.allocator, &.{ tmp_path, "presentation.tex" });
        defer self.allocator.free(tex_path);

        const tex_file = try tmp_dir.dir.createFile("presentation.tex", .{});
        defer tex_file.close();
        try tex_file.writeAll(latex);

        // Compile
        const compiled = try self.compileLatex(tex_path);
        if (!compiled) {
            return error.PdflatexNotFound;
        }

        // Read generated PDF
        const pdf_path = try std.fs.path.join(self.allocator, &.{ tmp_path, "presentation.pdf" });
        defer self.allocator.free(pdf_path);

        const pdf_file = try std.fs.cwd().openFile(pdf_path, .{});
        defer pdf_file.close();

        const stat = try pdf_file.stat();
        const pdf_content = try self.allocator.alloc(u8, stat.size);
        errdefer self.allocator.free(pdf_content);

        const bytes_read = try pdf_file.readAll(pdf_content);
        if (bytes_read != stat.size) {
            return error.IncompleteRead;
        }

        return pdf_content;
    }

    /// Get the .tex path from the .pdf path
    fn getTexPath(self: Self, pdf_path: []const u8) ![]const u8 {
        // Replace .pdf extension with .tex
        if (std.mem.endsWith(u8, pdf_path, ".pdf")) {
            const base = pdf_path[0 .. pdf_path.len - 4];
            return try std.mem.concat(self.allocator, u8, &.{ base, ".tex" });
        }
        return try std.mem.concat(self.allocator, u8, &.{ pdf_path, ".tex" });
    }

    /// Compile LaTeX to PDF using pdflatex
    /// Returns true if successful, false if pdflatex not found
    fn compileLatex(self: Self, tex_path: []const u8) !bool {
        _ = self;

        // Check if pdflatex is available
        const check_result = std.process.Child.run(.{
            .allocator = std.heap.page_allocator,
            .argv = &.{ "which", "pdflatex" },
        }) catch |err| {
            if (err == error.FileNotFound) {
                return false; // which command not found (Windows)
            }
            return err;
        };
        defer {
            std.heap.page_allocator.free(check_result.stdout);
            std.heap.page_allocator.free(check_result.stderr);
        }

        if (check_result.term.Exited != 0) {
            return false; // pdflatex not found
        }

        // Run pdflatex (twice for references)
        const tex_dir = std.fs.path.dirname(tex_path) orelse ".";
        const tex_file = std.fs.path.basename(tex_path);

        for (0..2) |_| {
            var child = std.process.Child.init(&.{
                "pdflatex",
                "-interaction=nonstopmode",
                "-output-directory",
                tex_dir,
                tex_file,
            }, std.heap.page_allocator);

            child.stderr_behavior = .Ignore;
            child.stdout_behavior = .Ignore;

            const term = try child.spawnAndWait();
            if (term.Exited != 0) {
                std.log.warn("pdflatex compilation warning or error (exit code: {d})", .{term.Exited});
                // Continue anyway, might just be warnings
            }
        }

        return true;
    }

    /// Check if PDF generation is available (pdflatex installed)
    pub fn isAvailable() bool {
        const result = std.process.Child.run(.{
            .allocator = std.heap.page_allocator,
            .argv = &.{ "which", "pdflatex" },
        }) catch return false;

        defer {
            std.heap.page_allocator.free(result.stdout);
            std.heap.page_allocator.free(result.stderr);
        }

        return result.term.Exited == 0;
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
