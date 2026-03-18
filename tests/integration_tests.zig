//! Integration tests for tuia

const std = @import("std");
const tuia = @import("tuia");

// Sanity test
test "sanity check" {
    try std.testing.expect(true);
}

// Test version is set
test "version is set" {
    try std.testing.expectEqualStrings("1.0.0", tuia.version);
}

// Test fixture loading
test "load fixture" {
    const allocator = std.testing.allocator;

    const content = try tuia.test_utils.Fixtures.load(allocator, "simple.md");
    defer allocator.free(content);

    try std.testing.expect(content.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, content, "# Simple Test") != null);
}

// Test minimal fixture
test "load minimal fixture" {
    const allocator = std.testing.allocator;

    const content = try tuia.test_utils.Fixtures.load(allocator, "minimal.md");
    defer allocator.free(content);

    try std.testing.expect(content.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, content, "# Minimal") != null);
}

// Golden file test example
test "golden file example" {
    const allocator = std.testing.allocator;

    // This is what we'd test
    const output = "Expected output\n";

    // Compare to golden file
    // Set ZIG_UPDATE_GOLDEN=1 to create/update
    try tuia.test_utils.Golden.expectEqual(allocator, output, "example.txt");
}

// Memory leak detection example
test "no memory leaks in example" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.detectLeaks();
        std.testing.expect(!leaked) catch {
            @panic("Memory leaks detected!");
        };
    }

    const allocator = gpa.allocator();

    // Allocate something
    const data = try allocator.alloc(u8, 100);
    allocator.free(data);
}

// Module compilation is verified by unit tests (zig build unit_test)
// Integration tests only test end-to-end behavior

// Import parser integration tests
comptime {
    _ = @import("integration/parser_integration_test.zig");
}

// Import export tests
comptime {
    _ = @import("integration/export_tests.zig");
}
