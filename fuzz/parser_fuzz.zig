//! Fuzz target for the Markdown parser
//! Compile with: zig build fuzz-parser

const std = @import("std");
const Parser = @import("../src/parser/Parser.zig");
const Scanner = @import("../src/parser/Scanner.zig");

/// Entry point for libFuzzer
export fn LLVMFuzzerTestOneInput(data: [*]const u8, len: usize) callconv(.C) c_int {
    const input = data[0..len];
    
    // Use a fixed buffer allocator for fuzzing to avoid leaks
    var buffer: [1024 * 1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    
    // Test 1: Scanner should not crash on any input
    {
        var scanner = Scanner.init(input);
        while (true) {
            const tok = scanner.nextToken();
            if (tok.token_type == .eof) break;
        }
    }
    
    // Test 2: Parser should not crash on any input
    {
        var parser = Parser.init(allocator, input);
        defer parser.deinit();
        
        const result = parser.parse() catch |err| switch (err) {
            error.OutOfMemory => return 0, // Expected in fuzzing
            else => return 0, // Other errors are acceptable
        };
        defer result.deinit(allocator);
        
        // Validate basic invariants
        for (result.slides) |slide| {
            // Slide elements count should be reasonable
            if (slide.elements.len > 10000) {
                @panic("Suspicious: too many elements in slide");
            }
        }
    }
    
    return 0;
}

/// Standalone main for testing without libFuzzer
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Read from stdin
    const stdin = std.io.getStdIn().reader();
    const input = try stdin.readAllAlloc(allocator, 10 * 1024 * 1024);
    defer allocator.free(input);
    
    const result = LLVMFuzzerTestOneInput(input.ptr, input.len);
    std.process.exit(@intCast(result));
}
