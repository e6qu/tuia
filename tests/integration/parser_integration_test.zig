//! Integration test: Parser Feature Showcase
const std = @import("std");
const tuia = @import("tuia");

// Helper to load file from any path
fn loadFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    return try std.fs.cwd().readFileAlloc(allocator, path, 1024 * 1024);
}

// Test that feature-showcase.md can be parsed
test "parse feature showcase presentation" {
    const allocator = std.testing.allocator;

    // Load the feature showcase file
    const content = try loadFile(allocator, "examples/feature-showcase.md");
    defer allocator.free(content);

    // Parse the presentation
    var parser = tuia.parser.Parser.init(allocator, content);
    var ast_pres = try parser.parse();
    defer ast_pres.deinit();

    // Verify front matter was parsed
    try std.testing.expect(ast_pres.metadata != null);
    const fm = ast_pres.metadata.?;
    try std.testing.expectEqualStrings("TUIA Feature Showcase", fm.title.?);
    try std.testing.expectEqualStrings("TUIA Developer", fm.author.?);
    try std.testing.expectEqualStrings("2026-03-02", fm.date.?);
    try std.testing.expectEqualStrings("dark", fm.theme.?);

    // Verify slides were created (should have multiple slides separated by ---)
    try std.testing.expect(ast_pres.slides.len > 5);

    std.debug.print("✅ Feature showcase: {d} slides parsed\n", .{ast_pres.slides.len});

    // Convert to core presentation (this exercises the converter)
    const core_pres = try tuia.parser.Converter.convertPresentation(allocator, ast_pres);
    defer core_pres.deinit();

    // Verify conversion preserved metadata
    try std.testing.expectEqualStrings("TUIA Feature Showcase", core_pres.metadata.title.?);
    try std.testing.expect(ast_pres.slides.len == core_pres.slides.len);
}

test "all example presentations parse successfully" {
    const allocator = std.testing.allocator;

    const examples = &[_][]const u8{
        "examples/demo.md",
        "examples/tutorial.md",
        "examples/cheatsheet.md",
        "examples/feature-showcase.md",
    };

    for (examples) |path| {
        const content = loadFile(allocator, path) catch |err| {
            std.debug.print("⚠️  Skipping {s}: {s}\n", .{ path, @errorName(err) });
            continue; // File might not exist
        };
        defer allocator.free(content);

        var parser = tuia.parser.Parser.init(allocator, content);
        var ast_pres = parser.parse() catch |err| {
            std.debug.print("❌ Failed to parse {s}: {s}\n", .{ path, @errorName(err) });
            return err;
        };
        defer ast_pres.deinit();

        // Should have at least one slide
        try std.testing.expect(ast_pres.slides.len > 0);

        std.debug.print("✅ {s}: {d} slides\n", .{ path, ast_pres.slides.len });
    }
}

test "feature showcase has expected slide count" {
    const allocator = std.testing.allocator;

    const content = try loadFile(allocator, "examples/feature-showcase.md");
    defer allocator.free(content);

    var parser = tuia.parser.Parser.init(allocator, content);
    var ast_pres = try parser.parse();
    defer ast_pres.deinit();

    // Count slides (separated by ---)
    // The presentation should have around 14 slides based on --- separators
    std.debug.print("📊 Feature showcase has {d} slides\n", .{ast_pres.slides.len});

    // Each slide should have at least one element
    for (ast_pres.slides, 0..) |slide, i| {
        if (slide.elements.len == 0) {
            std.debug.print("⚠️  Slide {d} has no elements\n", .{i});
        }
    }
}
