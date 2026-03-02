//! iTerm2 inline image protocol support
const std = @import("std");
const Image = @import("ImageLoader.zig").Image;

/// iTerm2 inline image protocol implementation
/// https://iterm2.com/documentation-images.html
pub const ITerm2Graphics = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
        };
    }

    /// Check if terminal supports iTerm2 inline images
    pub fn isSupported() bool {
        // Check for iTerm2 specific environment variables
        if (std.process.getEnvVarOwned(std.heap.page_allocator, "TERM_PROGRAM")) |term| {
            defer std.heap.page_allocator.free(term);
            return std.mem.eql(u8, term, "iTerm.app") or
                std.mem.indexOf(u8, term, "iTerm2") != null;
        } else |_| {
            // Also check TERM for WezTerm (also supports the protocol)
            if (std.process.getEnvVarOwned(std.heap.page_allocator, "TERM")) |term| {
                defer std.heap.page_allocator.free(term);
                return std.mem.indexOf(u8, term, "wezterm") != null;
            } else |_| {
                return false;
            }
        }
    }

    /// Encode image data for iTerm2 protocol
    /// Returns a string that should be written to the terminal
    pub fn encodeImage(
        self: Self,
        image: Image,
        options: DisplayOptions,
    ) ![]const u8 {
        var output: std.ArrayList(u8) = .empty;
        errdefer output.deinit(self.allocator);
        const writer = output.writer(self.allocator);

        // Convert image to PNG format
        // For now, we'll encode the raw RGBA data
        const image_data = image.data;

        // Encode to base64
        const base64_len = std.base64.standard.Encoder.calcSize(image_data.len);
        const base64_buf = try self.allocator.alloc(u8, base64_len);
        defer self.allocator.free(base64_buf);
        const base64_data = std.base64.standard.Encoder.encode(base64_buf, image_data);

        // Write OSC 1337 sequence
        try writer.writeAll("\x1b]1337;File=");

        // Add optional parameters
        var first_param = true;

        if (options.width) |w| {
            if (!first_param) try writer.writeAll(";");
            first_param = false;
            try writer.print("width={d}", .{w});
        }

        if (options.height) |h| {
            if (!first_param) try writer.writeAll(";");
            first_param = false;
            try writer.print("height={d}", .{h});
        }

        if (options.preserve_aspect_ratio) {
            if (!first_param) try writer.writeAll(";");
            first_param = false;
            try writer.writeAll("preserveAspectRatio=1");
        }

        if (options.inline_mode) {
            if (!first_param) try writer.writeAll(";");
            first_param = false;
            try writer.writeAll("inline_mode=1");
        }

        // Add size and data
        try writer.print(":size={d}", .{image_data.len});
        try writer.writeAll(";");
        try writer.writeAll(base64_data);
        try writer.writeAll("\x07"); // BEL character to end OSC sequence

        return output.toOwnedSlice(self.allocator);
    }

    /// Create a simple display options struct
    pub fn defaultOptions() DisplayOptions {
        return .{};
    }
};

/// Display options for iTerm2 images
pub const DisplayOptions = struct {
    /// Width in pixels
    width: ?u32 = null,
    /// Height in pixels
    height: ?u32 = null,
    /// Width in cells (character columns)
    width_cells: ?u32 = null,
    /// Height in cells (character rows)
    height_cells: ?u32 = null,
    /// Preserve aspect ratio
    preserve_aspect_ratio: bool = true,
    /// Display inline_mode (true) or download (false)
    inline_mode: bool = true,
    /// Name for the file (when not inline)
    name: ?[]const u8 = null,
};

test "ITerm2Graphics detection" {
    // This test depends on environment variables
    // Just verify it doesn't crash
    _ = ITerm2Graphics.isSupported();
}
