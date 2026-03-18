//! Window — a view into a Screen buffer for drawing
const Screen = @import("Screen.zig").Screen;
const Cell = @import("Cell.zig").Cell;
const Style = @import("Style.zig").Style;

/// A rectangular view into a Screen buffer.
/// Coordinates are relative to the window; offsets translate to screen space.
pub const Window = struct {
    x_off: i17 = 0,
    y_off: i17 = 0,
    width: u16 = 0,
    height: u16 = 0,
    screen: *Screen,

    /// Options for creating a child window
    pub const ChildOptions = struct {
        x_off: i17 = 0,
        y_off: i17 = 0,
        width: ?u16 = null,
        height: ?u16 = null,
    };

    /// Create a child window (sub-region of this window)
    pub fn child(self: Window, opts: ChildOptions) Window {
        const ew: u16 = opts.width orelse blk: {
            if (opts.x_off >= 0 and opts.x_off < self.width)
                break :blk self.width - @as(u16, @intCast(opts.x_off))
            else
                break :blk 0;
        };
        const eh: u16 = opts.height orelse blk: {
            if (opts.y_off >= 0 and opts.y_off < self.height)
                break :blk self.height - @as(u16, @intCast(opts.y_off))
            else
                break :blk 0;
        };
        return .{
            .x_off = self.x_off + opts.x_off,
            .y_off = self.y_off + opts.y_off,
            .width = ew,
            .height = eh,
            .screen = self.screen,
        };
    }

    /// Write a cell at the given window-relative position
    pub fn writeCell(self: Window, col: u16, row: u16, new_cell: Cell) void {
        const idx = self.screenIndex(col, row) orelse return;
        self.screen.buf[idx] = new_cell;
    }

    /// Read a cell at the given window-relative position
    pub fn readCell(self: Window, col: u16, row: u16) ?Cell {
        const idx = self.screenIndex(col, row) orelse return null;
        return self.screen.buf[idx];
    }

    /// Get the flat screen-buffer index for a position (struct-based API)
    pub fn cellIndex(self: Window, pos: struct { row: u16, col: u16 }) usize {
        return self.screenIndex(pos.col, pos.row) orelse 0;
    }

    /// Set a cell by flat screen-buffer index
    pub fn setCell(self: Window, index: usize, new_cell: Cell) void {
        if (index < self.screen.buf.len) {
            self.screen.buf[index] = new_cell;
        }
    }

    /// Clear the window (fill with default cells)
    pub fn clear(self: Window) void {
        self.fill(.{});
    }

    /// Fill the entire window with a cell
    pub fn fill(self: Window, cell: Cell) void {
        var row: u16 = 0;
        while (row < self.height) : (row += 1) {
            var col: u16 = 0;
            while (col < self.width) : (col += 1) {
                const idx = self.screenIndex(col, row) orelse continue;
                self.screen.buf[idx] = cell;
            }
        }
    }

    // -- internal --

    fn screenIndex(self: Window, col: u16, row: u16) ?usize {
        const abs_col = @as(i32, self.x_off) + @as(i32, col);
        const abs_row = @as(i32, self.y_off) + @as(i32, row);
        if (abs_col < 0 or abs_row < 0) return null;
        const c: u16 = @intCast(abs_col);
        const r: u16 = @intCast(abs_row);
        if (c >= self.screen.width or r >= self.screen.height) return null;
        return @as(usize, r) * self.screen.width + c;
    }
};
