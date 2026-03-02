const std = @import("std");
const ElementMod = @import("Element.zig");
const Element = ElementMod.Element;

/// Slide represents a single presentation slide
pub const Slide = struct {
    elements: []Element,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, elements: []const Element) !Self {
        const copy = try allocator.alloc(Element, elements.len);
        @memcpy(copy, elements);
        return .{ .elements = copy };
    }

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        for (self.elements) |element| {
            element.deinit(allocator);
        }
        allocator.free(self.elements);
    }

    pub fn elementCount(self: Self) usize {
        return self.elements.len;
    }

    pub fn isEmpty(self: Self) bool {
        return self.elements.len == 0;
    }

    pub fn getTitle(self: Self) ?[]const u8 {
        for (self.elements) |element| {
            if (element == .heading) {
                return element.heading.text;
            }
        }
        return null;
    }

    pub fn validate(self: Self) ValidationError!void {
        if (self.isEmpty()) {
            return ValidationError.EmptySlide;
        }
        for (self.elements) |element| {
            if (element == .heading) {
                if (element.heading.level < 1 or element.heading.level > 6) {
                    return ValidationError.InvalidHeadingLevel;
                }
            }
        }
    }

    /// Get the first code block on this slide
    pub fn getFirstCodeBlock(self: Self) ?ElementMod.CodeBlock {
        for (self.elements) |element| {
            if (element == .code_block) {
                return element.code_block;
            }
        }
        return null;
    }

    /// Get all code blocks on this slide
    pub fn getCodeBlocks(self: Self, allocator: std.mem.Allocator) ![]ElementMod.CodeBlock {
        var blocks = std.ArrayList(ElementMod.CodeBlock).init(allocator);
        defer blocks.deinit();

        for (self.elements) |element| {
            if (element == .code_block) {
                try blocks.append(element.code_block);
            }
        }

        return blocks.toOwnedSlice();
    }
};

pub const ValidationError = error{
    EmptySlide,
    InvalidHeadingLevel,
};

// Tests
test "Slide basic operations" {
    const testing = std.testing;

    // Test empty slide validation
    const empty_slide = Slide{ .elements = &.{} };
    try testing.expectError(ValidationError.EmptySlide, empty_slide.validate());
}
