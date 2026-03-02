//! Core data models
const std = @import("std");

pub const Element = @import("Element.zig").Element;
pub const List = @import("Element.zig").List;
pub const ListItem = @import("Element.zig").ListItem;
pub const Slide = @import("Slide.zig").Slide;
pub const Presentation = @import("Presentation.zig").Presentation;
pub const PresentationBuilder = @import("Presentation.zig").Builder;
pub const Navigation = @import("Navigation.zig").Navigation;
pub const KeyBindings = @import("KeyBindings.zig").KeyBindings;
pub const InputHandler = @import("InputHandler.zig").InputHandler;
pub const Note = @import("Note.zig").Note;

test {
    std.testing.refAllDecls(@This());
}
