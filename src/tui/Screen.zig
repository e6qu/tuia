//! Screen buffer — a 2D grid of cells
const Cell = @import("Cell.zig").Cell;

/// Screen buffer backing a terminal display.
/// Does not own its memory — receives an externally-owned slice.
pub const Screen = struct {
    width: u16 = 0,
    height: u16 = 0,
    buf: []Cell = &.{},

    /// Initialize with an externally-owned buffer. No allocation.
    pub fn init(buf: []Cell, width: u16, height: u16) Screen {
        const len = @as(usize, width) * height;
        const actual = @min(len, buf.len);
        @memset(buf[0..actual], Cell{});
        return .{ .width = width, .height = height, .buf = buf[0..actual] };
    }

    /// No-op — Screen doesn't own its memory.
    pub fn deinit(self: *Screen) void {
        self.buf = &.{};
        self.width = 0;
        self.height = 0;
    }

    /// Resize within the pre-allocated buffer. Clamps to `max_cells`. No allocation.
    /// `full_buf` must be the original buffer passed to `init` (or equivalent full-capacity slice).
    pub fn resize(self: *Screen, full_buf: []Cell, width: u16, height: u16) void {
        if (self.width == width and self.height == height) return;
        const len = @min(@as(usize, width) * height, full_buf.len);
        self.width = width;
        self.height = height;
        self.buf = full_buf[0..len];
        @memset(self.buf, Cell{});
    }

    pub fn clear(self: *Screen) void {
        @memset(self.buf, Cell{});
    }
};
