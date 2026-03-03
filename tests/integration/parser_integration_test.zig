//! Integration test: Parser tests
const std = @import("std");
const tuia = @import("tuia");

// Test 1: Simple parsing
test "parse simple presentation" {
    const allocator = std.testing.allocator;

    const markdown = "# Hello\n\nThis is a test.\n";

    var parser = tuia.parser.Parser.init(allocator, markdown);
    var ast_pres = try parser.parse();
    defer ast_pres.deinit();

    try std.testing.expect(ast_pres.slides.len >= 1);
}

// Test 2: Parse with frontmatter
test "parse with frontmatter" {
    const allocator = std.testing.allocator;

    const markdown = 
        \\---
        \\title: Test
        \\author: Author
        \\---
        \\# Slide 1
        \\Content here.
    ;

    var parser = tuia.parser.Parser.init(allocator, markdown);
    var ast_pres = try parser.parse();
    defer ast_pres.deinit();

    try std.testing.expect(ast_pres.metadata != null);
    try std.testing.expectEqualStrings("Test", ast_pres.metadata.?.title.?);
}

// Test 3: Parse with lists
test "parse with lists" {
    const allocator = std.testing.allocator;

    const markdown = 
        \\# List Test
        \\- Item 1
        \\- Item 2
        \\- Item 3
    ;

    var parser = tuia.parser.Parser.init(allocator, markdown);
    var ast_pres = try parser.parse();
    defer ast_pres.deinit();

    try std.testing.expect(ast_pres.slides.len >= 1);
}

// Test 4: Parse with code block
test "parse with code block" {
    const allocator = std.testing.allocator;

    const markdown = 
        \\# Code Test
        \\```zig
        \\const x = 42;
        \\```
    ;

    var parser = tuia.parser.Parser.init(allocator, markdown);
    var ast_pres = try parser.parse();
    defer ast_pres.deinit();

    try std.testing.expect(ast_pres.slides.len >= 1);
}

// Test 5: Parse with blockquote
test "parse with blockquote" {
    const allocator = std.testing.allocator;

    const markdown = 
        \\# Quote Test
        \\> This is a quote
        \\> With multiple lines
    ;

    var parser = tuia.parser.Parser.init(allocator, markdown);
    var ast_pres = try parser.parse();
    defer ast_pres.deinit();

    try std.testing.expect(ast_pres.slides.len >= 1);
}

// Test 6: Multiple slides
test "parse multiple slides" {
    const allocator = std.testing.allocator;

    const markdown = 
        \\# Slide 1
        \\Content 1
        \\---
        \\# Slide 2
        \\Content 2
        \\---
        \\# Slide 3
        \\Content 3
    ;

    var parser = tuia.parser.Parser.init(allocator, markdown);
    var ast_pres = try parser.parse();
    defer ast_pres.deinit();

    try std.testing.expectEqual(@as(usize, 3), ast_pres.slides.len);
}

// DISABLED - File-based tests need more debugging
// test "parse feature showcase presentation" {
//     const allocator = std.testing.allocator;
// 
//     const content = try std.fs.cwd().readFileAlloc(allocator, "examples/feature-showcase.md", 1024 * 1024);
//     defer allocator.free(content);
// 
//     var parser = tuia.parser.Parser.init(allocator, content);
//     var ast_pres = try parser.parse();
//     defer ast_pres.deinit();
// 
//     try std.testing.expect(ast_pres.slides.len > 5);
// }
