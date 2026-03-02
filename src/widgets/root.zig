//! UI widgets
const std = @import("std");

pub const Widget = @import("Widget.zig");
pub const SlideWidget = @import("SlideWidget.zig");
pub const TextWidget = @import("TextWidget.zig");
pub const CodeWidget = @import("CodeWidget.zig");
pub const HelpWidget = @import("HelpWidget.zig");
pub const StatusBar = @import("StatusBar.zig");
pub const NoteWidget = @import("NoteWidget.zig");

test {
    std.testing.refAllDecls(@This());
}
