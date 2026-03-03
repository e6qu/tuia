//! Export command handler for CLI
const std = @import("std");
const cli = @import("../cli.zig");
const Parser = @import("../parser/root.zig").Parser;
const convertPresentation = @import("../parser/Converter.zig").convertPresentation;
const Presentation = @import("../core/Presentation.zig").Presentation;

const HtmlExporter = @import("HtmlExporter.zig").HtmlExporter;
const RevealJsExporter = @import("RevealJsExporter.zig").RevealJsExporter;
const BeamerExporter = @import("BeamerExporter.zig").BeamerExporter;
const PdfExporter = @import("PdfExporter.zig").PdfExporter;
const ThemeModule = @import("../render/Theme.zig");
const Theme = ThemeModule.Theme;

/// Handle export command
pub fn handleExport(
    allocator: std.mem.Allocator,
    file_path: []const u8,
    format: []const u8,
    output_dir: ?[]const u8,
) !void {
    // Read input file
    const content = try std.fs.cwd().readFileAlloc(allocator, file_path, 1024 * 1024);
    defer allocator.free(content);

    std.debug.print("Loading presentation: {s}\n", .{file_path});

    // Parse the presentation
    var parser = Parser.init(allocator, content);
    var ast_pres = try parser.parse();
    defer ast_pres.deinit();

    std.debug.print("Parsed {d} slides\n", .{ast_pres.slides.len});

    // Convert to core presentation
    var core_pres = try convertPresentation(allocator, ast_pres);
    defer core_pres.deinit();

    // Determine output path
    const output_path = try getOutputPath(allocator, file_path, format, output_dir);
    defer allocator.free(output_path);

    // Create output directory if specified and doesn't exist
    if (output_dir) |dir| {
        std.fs.cwd().makeDir(dir) catch |err| {
            if (err != error.PathAlreadyExists) return err;
        };
    }

    std.debug.print("Exporting to {s}: {s}\n", .{ format, output_path });

    // Export based on format
    if (std.mem.eql(u8, format, "html")) {
        try exportHtml(allocator, core_pres, output_path);
    } else if (std.mem.eql(u8, format, "revealjs")) {
        try exportRevealJs(allocator, core_pres, output_path);
    } else if (std.mem.eql(u8, format, "beamer") or std.mem.eql(u8, format, "latex")) {
        try exportBeamer(allocator, core_pres, output_path);
    } else if (std.mem.eql(u8, format, "pdf")) {
        try exportPdf(allocator, core_pres, output_path);
    } else {
        std.debug.print("Unknown export format: {s}\n", .{format});
        std.debug.print("Supported formats: html, revealjs, beamer, pdf\n", .{});
        return error.UnknownExportFormat;
    }

    std.debug.print("Export complete: {s}\n", .{output_path});
}

/// Get output file path
fn getOutputPath(
    allocator: std.mem.Allocator,
    input_path: []const u8,
    format: []const u8,
    output_dir: ?[]const u8,
) ![]u8 {
    // Get base name from input
    const basename = std.fs.path.basename(input_path);
    const stem = if (std.mem.lastIndexOf(u8, basename, ".")) |idx|
        basename[0..idx]
    else
        basename;

    // Determine extension
    const ext = if (std.mem.eql(u8, format, "beamer") or std.mem.eql(u8, format, "latex"))
        "tex"
    else if (std.mem.eql(u8, format, "revealjs") or std.mem.eql(u8, format, "html"))
        "html"
    else if (std.mem.eql(u8, format, "pdf"))
        "pdf"
    else
        format;

    // Build filename
    const filename = try std.mem.concat(allocator, u8, &.{ stem, ".", ext });
    defer allocator.free(filename);

    // Build output path
    if (output_dir) |dir| {
        return try std.fs.path.join(allocator, &.{ dir, filename });
    } else {
        return try allocator.dupe(u8, filename);
    }
}

/// Export to HTML
fn exportHtml(allocator: std.mem.Allocator, presentation: Presentation, output_path: []const u8) !void {
    var exporter = HtmlExporter.init(allocator, ThemeModule.darkTheme());
    try exporter.exportToFile(presentation, output_path);
}

/// Export to Reveal.js
fn exportRevealJs(allocator: std.mem.Allocator, presentation: Presentation, output_path: []const u8) !void {
    var exporter = RevealJsExporter.init(allocator, "dark");
    try exporter.exportToFile(presentation, output_path);
}

/// Export to Beamer/LaTeX
fn exportBeamer(allocator: std.mem.Allocator, presentation: Presentation, output_path: []const u8) !void {
    var exporter = BeamerExporter.init(allocator, null, null);
    try exporter.exportToFile(presentation, output_path);
}

/// Export to PDF
fn exportPdf(allocator: std.mem.Allocator, presentation: Presentation, output_path: []const u8) !void {
    var exporter = PdfExporter.init(allocator, null, null);
    try exporter.exportToFile(presentation, output_path);

    // Check if PDF was actually generated
    if (!PdfExporter.isAvailable()) {
        std.debug.print("\nWarning: pdflatex not found. Only LaTeX source was generated.\n", .{});
        std.debug.print("To generate PDF, install TeX Live and run: pdflatex {s}\n", .{output_path});
    }
}

/// Print export help
pub fn printExportHelp() void {
    std.debug.print("\nExport Formats:\n", .{});
    std.debug.print("  html       Static HTML presentation\n", .{});
    std.debug.print("  revealjs   Reveal.js web presentation\n", .{});
    std.debug.print("  beamer     LaTeX Beamer slides\n", .{});
    std.debug.print("  pdf        PDF document (requires pdflatex)\n", .{});
    std.debug.print("\nExamples:\n", .{});
    std.debug.print("  tuia -e html presentation.md\n", .{});
    std.debug.print("  tuia -e pdf presentation.md -o ./output/\n", .{});
}
