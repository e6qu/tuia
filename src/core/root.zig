//! Core data models
const std = @import("std");

pub const Element = @import("Element.zig");
pub const Slide = @import("Slide.zig");
pub const Presentation = @import("Presentation.zig");
pub const Navigation = @import("Navigation.zig");
pub const KeyBindings = @import("KeyBindings.zig");
pub const InputHandler = @import("InputHandler.zig");

test {
    std.testing.refAllDecls(@This());
}
