//! Minimal TUI library — replaces vaxis dependency
//!
//! Only lightweight types are exported here. Terminal (raw I/O, event loop,
//! threading) is intentionally NOT re-exported to keep the compilation
//! footprint small — App.zig imports it directly.
pub const Style = @import("Style.zig").Style;
pub const Color = @import("Style.zig").Color;
pub const Cell = @import("Cell.zig").Cell;
pub const Key = @import("Key.zig").Key;
pub const Screen = @import("Screen.zig").Screen;
pub const Window = @import("Window.zig").Window;

/// Terminal window dimensions
pub const Winsize = struct {
    rows: u16,
    cols: u16,
    x_pixel: u16 = 0,
    y_pixel: u16 = 0,
};

/// Terminal event (key press or resize)
pub const Event = union(enum) {
    key: Key,
    winsize: Winsize,
};
