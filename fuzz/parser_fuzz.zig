//! Fuzz target stub for basic input validation
//! Compile with: zig build fuzz-parser

const std = @import("std");
const tuia = @import("tuia");

/// Entry point for libFuzzer
export fn LLVMFuzzerTestOneInput(data: [*]const u8, len: usize) callconv(.c) c_int {
    const input = data[0..len];
    
    // Use a fixed buffer allocator for fuzzing to avoid leaks
    var buffer: [1024 * 1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    
    // Test: tuia module should not crash on any input
    _ = allocator;
    _ = tuia;
    
    // Basic validation: check for suspicious patterns
    if (input.len > 100_000) {
        return 0; // Skip very large inputs
    }
    
    // Count markdown headers to detect runaway parsing
    var header_count: usize = 0;
    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        if (input[i] == '#' and (i == 0 or input[i - 1] == '\n')) {
            header_count += 1;
            if (header_count > 1000) {
                @panic("Suspicious: too many headers");
            }
        }
    }
    
    return 0;
}

/// Standalone main for testing without libFuzzer
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    
    // Simple test with a sample input
    const test_input = "# Test Slide\n\nHello World\n";
    const result = LLVMFuzzerTestOneInput(test_input.ptr, test_input.len);
    std.process.exit(@intCast(result));
}
