//! ASCII art fallback for image display
const std = @import("std");
const Image = @import("ImageLoader.zig").Image;

/// ASCII art generator for image fallback
pub const AsciiArt = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    /// ASCII characters from light to dark
    const ASCII_CHARS = "@#%*+=-:. ";

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
        };
    }

    /// Convert image to ASCII art
    pub fn convert(
        self: Self,
        image: Image,
        options: ConvertOptions,
    ) ![]const u8 {
        // Validate image dimensions to prevent division by zero
        if (image.width == 0 or image.height == 0) {
            return error.InvalidImageDimensions;
        }

        const target_width = options.width;
        const target_height = options.height;

        // Validate output dimensions
        if (target_width == 0 or target_height == 0) {
            return error.InvalidOutputDimensions;
        }

        // Calculate aspect ratio
        const aspect_ratio = @as(f32, @floatFromInt(image.height)) / @as(f32, @floatFromInt(image.width));

        // Calculate output dimensions
        const output_width = target_width;
        const output_height = @min(target_height, @as(u32, @intFromFloat(@as(f32, @floatFromInt(output_width)) * aspect_ratio * 0.5)));

        // Final validation of calculated dimensions
        if (output_width == 0 or output_height == 0) {
            return error.InvalidOutputDimensions;
        }

        var output: std.ArrayList(u8) = .empty;
        errdefer output.deinit(self.allocator);
        const writer = output.writer(self.allocator);

        // Sample image and convert to ASCII
        var y: u32 = 0;
        while (y < output_height) : (y += 1) {
            var x: u32 = 0;
            while (x < output_width) : (x += 1) {
                // Map output coordinates to image coordinates
                const img_x = @min(@as(u32, @intFromFloat(@as(f32, @floatFromInt(x)) * @as(f32, @floatFromInt(image.width)) / @as(f32, @floatFromInt(output_width)))), image.width - 1);
                const img_y = @min(@as(u32, @intFromFloat(@as(f32, @floatFromInt(y)) * @as(f32, @floatFromInt(image.height)) / @as(f32, @floatFromInt(output_height)))), image.height - 1);

                if (image.getPixel(img_x, img_y)) |pixel| {
                    const ascii_char = pixelToAscii(pixel, options.invert);
                    try writer.writeByte(ascii_char);
                } else {
                    try writer.writeByte(' ');
                }
            }
            try writer.writeByte('\n');
        }

        return output.toOwnedSlice(self.allocator);
    }

    /// Convert pixel to ASCII character
    fn pixelToAscii(pixel: [4]u8, invert: bool) u8 {
        // Calculate luminance
        const r = pixel[0];
        const g = pixel[1];
        const b = pixel[2];
        const a = pixel[3];

        // If fully transparent, return space
        if (a < 128) return ' ';

        // Calculate perceived brightness
        const luminance = @as(u32, r) * 299 + @as(u32, g) * 587 + @as(u32, b) * 114;
        const normalized = @min(luminance / 1000, 255);

        // Map to ASCII character
        const idx = @min(normalized * ASCII_CHARS.len / 256, ASCII_CHARS.len - 1);
        const char = ASCII_CHARS[idx];

        return if (invert) invertChar(char) else char;
    }

    /// Invert ASCII character (light <-> dark)
    fn invertChar(char: u8) u8 {
        const idx = std.mem.indexOf(u8, ASCII_CHARS, &[_]u8{char}) orelse 0;
        const inverted_idx = ASCII_CHARS.len - 1 - idx;
        return ASCII_CHARS[inverted_idx];
    }

    /// Convert image to block characters (Unicode half-blocks)
    /// This gives better vertical resolution than ASCII
    pub fn convertBlocks(
        self: Self,
        image: Image,
        options: ConvertOptions,
    ) ![]const u8 {
        const target_width = options.width;

        // Calculate output dimensions
        // Each block character represents 2 vertical pixels
        const output_width = target_width;
        const output_height = @min(options.height, image.height / 2);

        var output: std.ArrayList(u8) = .empty;
        errdefer output.deinit(self.allocator);
        const writer = output.writer(self.allocator);

        var y: u32 = 0;
        while (y < output_height) : (y += 1) {
            var x: u32 = 0;
            while (x < output_width) : (x += 1) {
                const img_x = @min(x * image.width / output_width, image.width - 1);
                const img_y_top = @min(y * 2 * image.height / (output_height * 2), image.height - 1);
                const img_y_bottom = @min((y * 2 + 1) * image.height / (output_height * 2), image.height - 1);

                const top_pixel = image.getPixel(img_x, img_y_top) orelse .{ 0, 0, 0, 255 };
                const bottom_pixel = image.getPixel(img_x, img_y_bottom) orelse .{ 0, 0, 0, 255 };

                try writeBlockChar(writer, top_pixel, bottom_pixel);
            }
            try writer.writeByte('\n');
        }

        return output.toOwnedSlice(self.allocator);
    }

    /// Write Unicode block character for two pixels
    fn writeBlockChar(writer: anytype, top: [4]u8, bottom: [4]u8) !void {
        // Unicode block elements:
        // ▀ U+2580 - Upper half block
        // ▄ U+2584 - Lower half block
        // █ U+2588 - Full block
        // ░ U+2591 - Light shade
        // ▒ U+2592 - Medium shade
        // ▓ U+2593 - Dark shade

        const top_lum = pixelLuminance(top);
        const bottom_lum = pixelLuminance(bottom);

        const threshold: u8 = 128;

        const top_dark = top_lum < threshold;
        const bottom_dark = bottom_lum < threshold;

        if (top_dark and bottom_dark) {
            try writer.writeAll(" ");
        } else if (!top_dark and !bottom_dark) {
            try writer.writeAll("█");
        } else if (!top_dark and bottom_dark) {
            try writer.writeAll("▀");
        } else {
            try writer.writeAll("▄");
        }
    }

    /// Calculate pixel luminance (0-255)
    fn pixelLuminance(pixel: [4]u8) u8 {
        if (pixel[3] < 128) return 0; // Transparent
        const lum = @as(u16, pixel[0]) * 299 + @as(u16, pixel[1]) * 587 + @as(u16, pixel[2]) * 114;
        return @intCast(@min(lum / 1000, 255));
    }
};

/// Conversion options
pub const ConvertOptions = struct {
    /// Output width in characters
    width: u32 = 80,
    /// Output height in characters
    height: u32 = 24,
    /// Invert colors (light background)
    invert: bool = false,
    /// Use block characters instead of ASCII
    use_blocks: bool = true,
};

test "AsciiArt pixelToAscii" {
    const testing = std.testing;

    // Test black pixel
    const black_pixel = [4]u8{ 0, 0, 0, 255 };
    try testing.expectEqual(@as(u8, '@'), AsciiArt.pixelToAscii(black_pixel, false));

    // Test white pixel
    const white_pixel = [4]u8{ 255, 255, 255, 255 };
    try testing.expectEqual(@as(u8, ' '), AsciiArt.pixelToAscii(white_pixel, false));

    // Test transparent pixel
    const transparent_pixel = [4]u8{ 255, 255, 255, 0 };
    try testing.expectEqual(@as(u8, ' '), AsciiArt.pixelToAscii(transparent_pixel, false));
}

test "AsciiArt convert" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Create a simple test image
    const data = try allocator.alloc(u8, 16); // 2x2 RGBA
    defer allocator.free(data);

    // White pixel
    data[0] = 255;
    data[1] = 255;
    data[2] = 255;
    data[3] = 255;
    // Black pixel
    data[4] = 0;
    data[5] = 0;
    data[6] = 0;
    data[7] = 255;
    // Gray pixel
    data[8] = 128;
    data[9] = 128;
    data[10] = 128;
    data[11] = 255;
    // White pixel
    data[12] = 255;
    data[13] = 255;
    data[14] = 255;
    data[15] = 255;

    const image = Image{
        .data = data,
        .width = 2,
        .height = 2,
        .format = .unknown,
        .path = null,
    };

    var ascii = AsciiArt.init(allocator);
    const result = try ascii.convert(image, .{
        .width = 2,
        .height = 2,
        .use_blocks = false,
    });
    defer allocator.free(result);

    // Should produce at least 1 line of ASCII art (aspect ratio reduces height)
    const lines = std.mem.count(u8, result, "\n");
    try testing.expect(lines >= 1);
}
