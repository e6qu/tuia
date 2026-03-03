//! E2E/Integration tests for export functionality

const std = @import("std");
const tuia = @import("tuia");

const Presentation = tuia.core.Presentation;
const Slide = tuia.core.Slide;
const Element = tuia.core.Element;
const Parser = tuia.parser.Parser;
const convertPresentation = tuia.parser.Converter.convertPresentation;
const HtmlExporter = tuia.export_.HtmlExporter;
const RevealJsExporter = tuia.export_.RevealJsExporter;
const BeamerExporter = tuia.export_.BeamerExporter;
const PdfExporter = tuia.export_.PdfExporter;
const Theme = tuia.render.Theme;

// ============== HTML Export E2E Tests ==============

test "e2e: HTML export full presentation" {
    const allocator = std.testing.allocator;

    // Parse a full presentation
    const markdown =
        \\---
        \\title: Integration Test
        \\author: Test Author
        \\---
        \\n        \\# First Slide
        \\n        \\This is a paragraph with **bold** and *italic* text.
        \\n        \\---
        \\n        \\# Second Slide
        \\n        \\- Item 1
        \\- Item 2
        \\- Item 3
        \\n        \\---
        \\n        \\# Code Example
        \\n        \\```python
        \\print("Hello, World!")
        \\```
    ;

    var parser = Parser.init(allocator, markdown);

    var ast = try parser.parse();
    defer ast.deinit();

    var presentation = try convertPresentation(allocator, ast);
    defer presentation.deinit();

    // Export to HTML
    var exporter = HtmlExporter.init(allocator, Theme.darkTheme());
    const html = try exporter.exportToHtml(presentation);
    defer allocator.free(html);

    // Verify structure
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "<!DOCTYPE html>"));
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "Integration Test"));
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "Test Author"));
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "First Slide"));
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "Second Slide"));
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "Item 1"));
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "print"));

    // Verify we have the right number of slide divs
    const slide_count = std.mem.count(u8, html, "class=\"slide\"");
    try std.testing.expectEqual(@as(usize, 3), slide_count);
}

// ============== Reveal.js Export E2E Tests ==============

test "e2e: Reveal.js export with all element types" {
    const allocator = std.testing.allocator;

    const markdown =
        \\# Title Slide
        \\n        \\A paragraph with [a link](https://example.com).
        \\n        \\---
        \\n        \\## Lists and Quotes
        \\n        \\> This is a blockquote
        \\> with multiple lines.
        \\n        \\1. First ordered item
        \\2. Second ordered item
        \\3. Third item
        \\n        \\---
        \\n        \\## Table Slide
        \\n        \\| Header 1 | Header 2 |
        \\|----------|----------|
        \\| Cell 1   | Cell 2   |
        \\| Cell 3   | Cell 4   |
    ;

    var parser = Parser.init(allocator, markdown);

    var ast = try parser.parse();
    defer ast.deinit();

    var presentation = try convertPresentation(allocator, ast);
    defer presentation.deinit();

    // Export to Reveal.js
    var exporter = RevealJsExporter.init(allocator, "white");
    const html = try exporter.exportToHtml(presentation);
    defer allocator.free(html);

    // Verify structure
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "reveal.js"));
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "theme/white.css"));
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "<section>"));

    // Verify link is present
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "https://example.com"));

    // Verify table structure
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "<table>"));
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "<th>"));

    // Verify blockquote
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "<blockquote>"));

    // Verify ordered list
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "<ol>"));
}

// ============== Beamer/LaTeX Export E2E Tests ==============

test "e2e: Beamer export produces valid LaTeX structure" {
    const allocator = std.testing.allocator;

    const markdown =
        \\---
        \\title: LaTeX Test Presentation
        \\author: LaTeX Author
        \\date: 2026-03-03
        \\---
        \\n        \\# Introduction
        \\n        \\Welcome to the **presentation** about `code` and *formatting*.
        \\n        \\---
        \\n        \\# Code Example
        \\n        \\```rust
        \\fn main() {
        \\    println!("Hello");
        \\}
        \\```
        \\n        \\---
        \\n        \\# Summary
        \\n        \\- Point A: Important
        \\- Point B: Critical
        \\- Point C: Essential
        \\n        \\> Remember: Always test your code!
    ;

    var parser = Parser.init(allocator, markdown);

    var ast = try parser.parse();
    defer ast.deinit();

    var presentation = try convertPresentation(allocator, ast);
    defer presentation.deinit();

    // Export to LaTeX/Beamer
    var exporter = BeamerExporter.init(allocator, "metropolis", "crane");
    const latex = try exporter.exportToLatex(presentation);
    defer allocator.free(latex);

    // Verify document structure
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\documentclass[aspectratio=169]{beamer}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\begin{document}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\end{document}"));

    // Verify metadata
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\title{LaTeX Test Presentation}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\author{LaTeX Author}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\date{2026-03-03}"));

    // Verify theme
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\usetheme{metropolis}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\usecolortheme{crane}"));

    // Verify frame structure
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\begin{frame}{Introduction}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\begin{frame}{Code Example}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\begin{frame}{Summary}"));

    // Verify formatting
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\textbf{presentation}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\textit{formatting}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\texttt{code}"));

    // Verify code block with language
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\begin{lstlisting}[language=Rust]"));

    // Verify list
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\begin{itemize}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\item Point A"));

    // Verify blockquote
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\begin{quote}"));

    // Verify title page
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\titlepage"));
}

test "e2e: Beamer export escapes special characters" {
    const allocator = std.testing.allocator;

    // Markdown with special LaTeX characters
    const markdown =
        \\# Special Characters: $100 & More
        \\n        \\This text contains: $, %, #, _, {, }, ~, ^, \\, <, >
        \\n        \\Math formula: a^2 + b^2 = c^2
    ;

    var parser = Parser.init(allocator, markdown);

    var ast = try parser.parse();
    defer ast.deinit();

    var presentation = try convertPresentation(allocator, ast);
    defer presentation.deinit();

    var exporter = BeamerExporter.init(allocator, null, null);
    const latex = try exporter.exportToLatex(presentation);
    defer allocator.free(latex);

    // Verify special characters are escaped
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\$100"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\&"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\%"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\#"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\_"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\{"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\^{}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\textasciitilde{}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\textbackslash{}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\textless{}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\textgreater{}"));
}

test "e2e: Beamer export table rendering" {
    const allocator = std.testing.allocator;

    const markdown =
        \\# Table Test
        \\n        \\| Name | Value | Description |
        \\|------|-------|-------------|
        \\| A    | 10    | First item  |
        \\| B    | 20    | Second item |
        \\| C    | 30    | Third item  |
    ;

    var parser = Parser.init(allocator, markdown);

    var ast = try parser.parse();
    defer ast.deinit();

    var presentation = try convertPresentation(allocator, ast);
    defer presentation.deinit();

    var exporter = BeamerExporter.init(allocator, null, null);
    const latex = try exporter.exportToLatex(presentation);
    defer allocator.free(latex);

    // Verify table structure
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\begin{tabular}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\toprule"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\midrule"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\bottomrule"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "Name & Value & Description"));
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\\\")); // Row separator
}

test "e2e: Beamer export image handling" {
    const allocator = std.testing.allocator;

    const markdown =
        \\# Image Slide
        \\n        \\![Alt text](path/to/image.png)
    ;

    var parser = Parser.init(allocator, markdown);

    var ast = try parser.parse();
    defer ast.deinit();

    var presentation = try convertPresentation(allocator, ast);
    defer presentation.deinit();

    var exporter = BeamerExporter.init(allocator, null, null);
    const latex = try exporter.exportToLatex(presentation);
    defer allocator.free(latex);

    // Verify image inclusion
    try std.testing.expect(std.mem.containsAtLeast(u8, latex, 1, "\\includegraphics[width=0.8\\textwidth]{path/to/image.png}"));
}

// ============== PDF Export E2E Tests ==============

test "e2e: PDF export generates LaTeX source" {
    const allocator = std.testing.allocator;

    const markdown =
        \\---
        \\title: PDF Export Test
        \\author: PDF Author
        \\---
        \\n        \\# Slide 1
        \\n        \\Content here.
    ;

    var parser = Parser.init(allocator, markdown);

    var ast = try parser.parse();
    defer ast.deinit();

    var presentation = try convertPresentation(allocator, ast);
    defer presentation.deinit();

    // Create temp directory
    var tmp_dir = std.testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    const tmp_path = try tmp_dir.dir.realpathAlloc(allocator, ".");
    defer allocator.free(tmp_path);

    const pdf_path = try std.fs.path.join(allocator, &.{ tmp_path, "test.pdf" });
    defer allocator.free(pdf_path);

    // Export to PDF (generates .tex file)
    var exporter = PdfExporter.init(allocator, null, null);
    try exporter.exportToFile(presentation, pdf_path);

    // Verify .tex file was created
    const tex_path = try std.fs.path.join(allocator, &.{ tmp_path, "test.tex" });
    defer allocator.free(tex_path);

    const tex_file = try std.fs.cwd().openFile(tex_path, .{});
    defer tex_file.close();

    const stat = try tex_file.stat();
    try std.testing.expect(stat.size > 0);

    // Read and verify content
    const content = try allocator.alloc(u8, stat.size);
    defer allocator.free(content);
    _ = try tex_file.readAll(content);

    try std.testing.expect(std.mem.containsAtLeast(u8, content, 1, "\\documentclass"));
    try std.testing.expect(std.mem.containsAtLeast(u8, content, 1, "PDF Export Test"));
}

// ============== Round-trip Tests ==============

test "e2e: Export all formats from same presentation" {
    const allocator = std.testing.allocator;

    const markdown =
        \\---
        \\title: Multi-Format Test
        \\author: Test Author
        \\---
        \\n        \\# Test Slide
        \\n        \\This is **bold** and *italic* with `code`.
        \\n        \\- Item 1
        \\- Item 2
        \\n        \\```python
        \\print("hello")
        \\```
    ;

    var parser = Parser.init(allocator, markdown);

    var ast = try parser.parse();
    defer ast.deinit();

    var presentation = try convertPresentation(allocator, ast);
    defer presentation.deinit();

    // Export to all formats
    var html_exporter = HtmlExporter.init(allocator, Theme.darkTheme());
    const html = try html_exporter.exportToHtml(presentation);
    defer allocator.free(html);

    var reveal_exporter = RevealJsExporter.init(allocator, "black");
    const reveal = try reveal_exporter.exportToHtml(presentation);
    defer allocator.free(reveal);

    var beamer_exporter = BeamerExporter.init(allocator, "default", null);
    const beamer = try beamer_exporter.exportToLatex(presentation);
    defer allocator.free(beamer);

    // Verify all contain expected content
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "Multi-Format Test"));
    try std.testing.expect(std.mem.containsAtLeast(u8, reveal, 1, "Multi-Format Test"));
    try std.testing.expect(std.mem.containsAtLeast(u8, beamer, 1, "Multi-Format Test"));

    // Verify formatting in all outputs
    // HTML: <strong>, <em>
    try std.testing.expect(std.mem.containsAtLeast(u8, html, 1, "<strong>bold</strong>") or
        std.mem.containsAtLeast(u8, html, 1, "font-weight:bold"));

    // Reveal.js: <strong>, <em>
    try std.testing.expect(std.mem.containsAtLeast(u8, reveal, 1, "<strong>bold</strong>"));

    // Beamer: \textbf, \textit
    try std.testing.expect(std.mem.containsAtLeast(u8, beamer, 1, "\\textbf{bold}"));
    try std.testing.expect(std.mem.containsAtLeast(u8, beamer, 1, "\\textit{italic}"));
}
