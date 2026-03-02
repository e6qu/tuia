//! Kitty graphics protocol support
const std = @import("std");
const Image = @import("ImageLoader.zig").Image;

/// Kitty graphics protocol implementation
/// https://sw.kovidgoyal.net/kitty/graphics-protocol/
pub const KittyGraphics = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
        };
    }

    /// Check if terminal supports Kitty graphics
    pub fn isSupported() bool {
        // Check TERM or KITTY_WINDOW_ID environment variable
        if (std.process.getEnvVarOwned(std.heap.page_allocator, "KITTY_WINDOW_ID")) |_| {
            return true;
        } else |_| {
            // Also check for TERM containing "kitty"
            if (std.process.getEnvVarOwned(std.heap.page_allocator, "TERM")) |term| {
                defer std.heap.page_allocator.free(term);
                return std.mem.indexOf(u8, term, "kitty") != null;
            } else |_| {
                return false;
            }
        }
    }

    /// Encode image data for Kitty protocol
    /// Returns a string that should be written to the terminal
    pub fn encodeImage(
        self: Self,
        image: Image,
        options: DisplayOptions,
    ) ![]const u8 {
        var output: std.ArrayList(u8) = .empty;
        errdefer output.deinit(self.allocator);
        const writer = output.writer(self.allocator);

        // Convert RGBA to PNG bytes (simplified - just use raw data for now)
        const image_data = image.data;

        // Encode to base64
        const base64_len = std.base64.standard.Encoder.calcSize(image_data.len);
        const base64_buf = try self.allocator.alloc(u8, base64_len);
        defer self.allocator.free(base64_buf);
        const base64_data = std.base64.standard.Encoder.encode(base64_buf, image_data);

        // Generate a unique image ID
        const image_id = @intFromPtr(image.data.ptr) % 1000000;

        // Write control sequence
        try writer.print(
            \\e_Ga=T,f=32,s={d},v={d},i={d},c={d},r={d}
        , .{
            image.width,
            image.height,
            image_id,
            options.columns orelse 0,
            options.rows orelse 0,
        });

        // Write image data in chunks
        const chunk_size = 4096;
        var offset: usize = 0;
        while (offset < base64_data.len) {
            const end = @min(offset + chunk_size, base64_data.len);
            const chunk = base64_data[offset..end];

            if (offset == 0) {
                // First chunk
                try writer.writeAll(";");
            } else {
                // Continuation
                try writer.print(
                    \\e_Gm={d}
                , .{@intFromBool(end >= base64_data.len)});
            }

            try writer.writeAll(chunk);
            try writer.writeAll("\x1b\\");

            offset = end;
        }

        return output.toOwnedSlice(self.allocator);
    }

    /// Create a simple display options struct
    pub fn defaultOptions() DisplayOptions {
        return .{};
    }

    /// Delete an image from the terminal
    pub fn deleteImage(self: Self, image_id: u32) ![]const u8 {
        return try std.fmt.allocPrint(self.allocator, "\x1b_Ga=d,d=i,i={d}\x1b\\", .{image_id});
    }

    /// Delete all images from the terminal
    pub fn deleteAllImages(self: Self) ![]const u8 {
        return try std.fmt.allocPrint(self.allocator, "\x1b_Ga=d,d=A\x1b\\", .{});
    }
};

/// Display options for Kitty graphics
pub const DisplayOptions = struct {
    /// Number of columns to display
    columns: ?u32 = null,
    /// Number of rows to display
    rows: ?u32 = null,
    /// X offset within cell
    x_offset: ?u32 = null,
    /// Y offset within cell
    y_offset: ?u32 = null,
    /// Width in pixels (overrides columns)
    width: ?u32 = null,
    /// Height in pixels (overrides rows)
    height: ?u32 = null,
    /// Cursor movement after display
    cursor_movement: CursorMovement = .none,
};

/// Cursor movement options
pub const CursorMovement = enum {
    /// Do not move cursor
    none,
    /// Move cursor to after image
    after,
    /// Move cursor to start of next line
    next_line,
};

/// Image placement options
pub const PlacementOptions = struct {
    /// Image ID
    image_id: u32,
    /// Parent image ID (for animation frames)
    parent_image_id: ?u32 = null,
    /// Placement ID (for multiple placements of same image)
    placement_id: ?u32 = null,
};

test "KittyGraphics detection" {
    // This test depends on environment variables
    // Just verify it doesn't crash
    _ = KittyGraphics.isSupported();
}
