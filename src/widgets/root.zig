//! UI widgets
const std = @import("std");

pub const Widget = @import("Widget.zig");
pub const SlideWidget = @import("SlideWidget.zig");
pub const TextWidget = @import("TextWidget.zig");
pub const CodeWidget = @import("CodeWidget.zig");
pub const HelpWidget = @import("HelpWidget.zig");
pub const StatusBar = @import("StatusBar.zig");
pub const NoteWidget = @import("NoteWidget.zig");
pub const ExecutionWidget = @import("ExecutionWidget.zig");
pub const PresentationOverlay = @import("PresentationOverlay.zig").PresentationOverlay;

test {
    _ = @import("Widget.zig");
    _ = @import("SlideWidget.zig");
    _ = @import("TextWidget.zig");
    _ = @import("CodeWidget.zig");
    _ = @import("HelpWidget.zig");
    _ = @import("StatusBar.zig");
    _ = @import("NoteWidget.zig");
    _ = @import("ExecutionWidget.zig");
    _ = @import("PresentationOverlay.zig");
}
