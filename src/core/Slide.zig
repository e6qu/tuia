const std = @import("std");
const ElementMod = @import("Element.zig");
const Element = ElementMod.Element;

/// Slide represents a single presentation slide
pub const Slide = struct {
    elements: []Element,
    speaker_notes: ?[]const u8,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, elements: []const Element, speaker_notes: ?[]const u8) !Self {
        const copy = try allocator.alloc(Element, elements.len);
        @memcpy(copy, elements);
        const notes_copy = if (speaker_notes) |notes| try allocator.dupe(u8, notes) else null;
        return .{
            .elements = copy,
            .speaker_notes = notes_copy,
        };
    }

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        for (self.elements) |element| {
            element.deinit(allocator);
        }
        allocator.free(self.elements);
        if (self.speaker_notes) |notes| {
            allocator.free(notes);
        }
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
                // Extract first text from inline content
                return @import("Element.zig").extractFirstText(element.heading.content);
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
    const empty_slide = Slide{ .elements = &.{}, .speaker_notes = null };
    try testing.expectError(ValidationError.EmptySlide, empty_slide.validate());
}
