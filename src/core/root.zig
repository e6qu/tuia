//! Core data models
const std = @import("std");

pub const Element = @import("Element.zig");
pub const Slide = @import("Slide.zig");
pub const Presentation = @import("Presentation.zig");

test {
    std.testing.refAllDecls(@This());
}
