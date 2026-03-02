//! Sixel graphics protocol support
const std = @import("std");
const Image = @import("ImageLoader.zig").Image;

/// Sixel graphics protocol implementation
/// https://en.wikipedia.org/wiki/Sixel
pub const SixelGraphics = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
        };
    }

    /// Check if terminal supports Sixel
    pub fn isSupported() bool {
        // Check TERM for known Sixel-supporting terminals
        if (std.process.getEnvVarOwned(std.heap.page_allocator, "TERM")) |term| {
            defer std.heap.page_allocator.free(term);
            const known_terms = [_][]const u8{
                "mlterm",
                "yaft",
                "foot",
                "contour",
                "wezterm",
                "xterm-256color",
            };
            for (known_terms) |known| {
                if (std.mem.indexOf(u8, term, known) != null) return true;
            }
        } else |_| {}

        // Check for explicit Sixel capability
        if (std.process.getEnvVarOwned(std.heap.page_allocator, "TERMINAL_SIXEL")) |_| {
            return true;
        } else |_| {}

        return false;
    }

    /// Encode image data for Sixel protocol
    /// Returns a string that should be written to the terminal
    pub fn encodeImage(
        self: Self,
        image: Image,
        options: DisplayOptions,
    ) ![]const u8 {
        var output: std.ArrayList(u8) = .empty;
        errdefer output.deinit(self.allocator);
        const writer = output.writer(self.allocator);

        // Start Sixel mode
        try writer.writeAll("\x1bPq"); // DCS q

        // Set raster attributes (if dimensions provided)
        if (options.width orelse image.width > 0 and options.height orelse image.height > 0) {
            const w = options.width orelse image.width;
            const h = options.height orelse image.height;
            try writer.print("\"1;1;{d};{d}", .{ w, h });
        }

        // Convert image to Sixel data
        // Sixel uses a run-length encoding of color indices
        // For simplicity, we'll create a basic implementation

        // Define color palette (basic 16 colors)
        for (0..16) |color_idx| {
            const r = ((color_idx >> 0) & 1) * 100;
            const g = ((color_idx >> 1) & 1) * 100;
            const b = ((color_idx >> 2) & 1) * 100;
            try writer.print("#{d};2;{d};{d};{d}", .{ color_idx, r, g, b });
        }

        // Sixel encodes 6 pixels vertically per character
        // We'll create a simplified representation
        const width = @min(image.width, options.max_width orelse image.width);
        const height = @min(image.height, options.max_height orelse image.height);

        var y: u32 = 0;
        while (y < height) : (y += 6) {
            // Select color 0 (black) for this band
            try writer.writeAll("#0");

            var x: u32 = 0;
            while (x < width) : (x += 1) {
                // Encode 6 vertical pixels
                var sixel_char: u8 = '?' - 63; // Start at 0

                var dy: u32 = 0;
                while (dy < 6 and y + dy < height) : (dy += 1) {
                    if (image.getPixel(x, y + dy)) |pixel| {
                        // Check if pixel is "on" (not fully transparent and not black)
                        if (pixel[3] > 128 and (pixel[0] > 64 or pixel[1] > 64 or pixel[2] > 64)) {
                            sixel_char |= @as(u8, 1) << @intCast(dy);
                        }
                    }
                }

                // Write the Sixel character (add 63 to get printable range)
                try writer.writeByte(sixel_char + 63);
            }

            // End of line
            try writer.writeByte('-');
        }

        // End Sixel mode
        try writer.writeAll("\x1b\\"); // ST

        return output.toOwnedSlice(self.allocator);
    }

    /// Create a simple display options struct
    pub fn defaultOptions() DisplayOptions {
        return .{};
    }
};

/// Display options for Sixel images
pub const DisplayOptions = struct {
    /// Width in pixels
    width: ?u32 = null,
    /// Height in pixels
    height: ?u32 = null,
    /// Maximum width (for scaling)
    max_width: ?u32 = 800,
    /// Maximum height (for scaling)
    max_height: ?u32 = 600,
};

test "SixelGraphics detection" {
    // This test depends on environment variables
    // Just verify it doesn't crash
    _ = SixelGraphics.isSupported();
}
