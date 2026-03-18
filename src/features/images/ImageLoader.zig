//! Image loading and caching
const std = @import("std");

/// Supported image formats
pub const ImageFormat = enum {
    png,
    jpeg,
    gif,
    bmp,
    unknown,
};

/// Image data container
pub const Image = struct {
    /// Raw image data (RGBA)
    data: []const u8,
    /// Image width in pixels
    width: u32,
    /// Image height in pixels
    height: u32,
    /// Image format
    format: ImageFormat,
    /// Original file path (if loaded from file)
    path: ?[]const u8,

    const Self = @This();

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
        if (self.path) |p| allocator.free(p);
    }

    /// Get pixel at x, y (RGBA)
    pub fn getPixel(self: Self, x: u32, y: u32) ?[4]u8 {
        if (x >= self.width or y >= self.height) return null;
        const idx = (y * self.width + x) * 4;
        if (idx + 3 >= self.data.len) return null;
        return .{
            self.data[idx],
            self.data[idx + 1],
            self.data[idx + 2],
            self.data[idx + 3],
        };
    }

    /// Get format from file extension
    pub fn formatFromPath(path: []const u8) ImageFormat {
        const ext = std.fs.path.extension(path);
        if (std.mem.eql(u8, ext, ".png")) return .png;
        if (std.mem.eql(u8, ext, ".jpg") or std.mem.eql(u8, ext, ".jpeg")) return .jpeg;
        if (std.mem.eql(u8, ext, ".gif")) return .gif;
        if (std.mem.eql(u8, ext, ".bmp")) return .bmp;
        return .unknown;
    }
};

/// ImageLoader handles loading and caching images
pub const ImageLoader = struct {
    allocator: std.mem.Allocator,
    /// Cache of loaded images (path -> Image)
    cache: std.StringHashMap(Image),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .cache = std.StringHashMap(Image).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        var iter = self.cache.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit(self.allocator);
            self.allocator.free(entry.key_ptr.*);
        }
        self.cache.deinit();
    }

    /// Load image from file path
    /// Returns a borrowed Image. The ImageLoader owns the data — do NOT call deinit on the result.
    pub fn loadFromFile(self: *Self, path: []const u8) !*const Image {
        // Check cache first
        if (self.cache.getPtr(path)) |cached| {
            return cached;
        }

        // Read file
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const stat = try file.stat();
        const file_data = try file.readToEndAlloc(self.allocator, @intCast(stat.size));
        defer self.allocator.free(file_data);

        // Load image
        const image = try self.loadFromMemory(file_data, path);

        // Cache the image
        const path_copy = try self.allocator.dupe(u8, path);
        errdefer self.allocator.free(path_copy);
        try self.cache.put(path_copy, image);

        return self.cache.getPtr(path).?;
    }

    /// Load image from memory
    pub fn loadFromMemory(self: Self, data: []const u8, path: ?[]const u8) !Image {
        const format = if (path) |p| Image.formatFromPath(p) else detectFormat(data);

        return switch (format) {
            .png => try loadPng(self.allocator, data),
            .jpeg => try loadJpeg(self.allocator, data),
            .gif => try loadGif(self.allocator, data),
            .bmp => try loadBmp(self.allocator, data),
            .unknown => error.UnsupportedFormat,
        };
    }

    /// Detect image format from magic bytes
    fn detectFormat(data: []const u8) ImageFormat {
        if (data.len < 4) return .unknown;

        // PNG: 89 50 4E 47
        if (data[0] == 0x89 and data[1] == 0x50 and data[2] == 0x4E and data[3] == 0x47) {
            return .png;
        }

        // JPEG: FF D8 FF
        if (data[0] == 0xFF and data[1] == 0xD8 and data[2] == 0xFF) {
            return .jpeg;
        }

        // GIF: 47 49 46 38
        if (data[0] == 'G' and data[1] == 'I' and data[2] == 'F' and data[3] == '8') {
            return .gif;
        }

        // BMP: 42 4D
        if (data[0] == 'B' and data[1] == 'M') {
            return .bmp;
        }

        return .unknown;
    }

    /// Load PNG image (simplified - just basic structure)
    fn loadPng(allocator: std.mem.Allocator, data: []const u8) !Image {
        // For a real implementation, we'd use libpng or similar
        // This is a placeholder that creates a simple RGBA image
        _ = data;

        // Create a simple placeholder image (1x1 red pixel)
        const rgba = try allocator.alloc(u8, 4);
        rgba[0] = 255; // R
        rgba[1] = 0; // G
        rgba[2] = 0; // B
        rgba[3] = 255; // A

        return Image{
            .data = rgba,
            .width = 1,
            .height = 1,
            .format = .png,
            .path = null,
        };
    }

    /// Load JPEG image
    fn loadJpeg(allocator: std.mem.Allocator, data: []const u8) !Image {
        _ = data;
        // Placeholder
        const rgba = try allocator.alloc(u8, 4);
        rgba[0] = 0; // R
        rgba[1] = 255; // G
        rgba[2] = 0; // B
        rgba[3] = 255; // A

        return Image{
            .data = rgba,
            .width = 1,
            .height = 1,
            .format = .jpeg,
            .path = null,
        };
    }

    /// Load GIF image
    fn loadGif(allocator: std.mem.Allocator, data: []const u8) !Image {
        _ = data;
        // Placeholder
        const rgba = try allocator.alloc(u8, 4);
        rgba[0] = 0; // R
        rgba[1] = 0; // G
        rgba[2] = 255; // B
        rgba[3] = 255; // A

        return Image{
            .data = rgba,
            .width = 1,
            .height = 1,
            .format = .gif,
            .path = null,
        };
    }

    /// Load BMP image
    fn loadBmp(allocator: std.mem.Allocator, data: []const u8) !Image {
        _ = data;
        // Placeholder
        const rgba = try allocator.alloc(u8, 4);
        rgba[0] = 255; // R
        rgba[1] = 255; // G
        rgba[2] = 0; // B
        rgba[3] = 255; // A

        return Image{
            .data = rgba,
            .width = 1,
            .height = 1,
            .format = .bmp,
            .path = null,
        };
    }

    /// Clear the image cache
    pub fn clearCache(self: *Self) void {
        var iter = self.cache.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit(self.allocator);
            self.allocator.free(entry.key_ptr.*);
        }
        self.cache.clearRetainingCapacity();
    }
};

test "Image format detection" {
    const testing = std.testing;

    // Test PNG magic bytes
    const png_data = &[_]u8{ 0x89, 0x50, 0x4E, 0x47 };
    try testing.expectEqual(ImageFormat.png, ImageLoader.detectFormat(png_data));

    // Test JPEG magic bytes
    const jpeg_data = &[_]u8{ 0xFF, 0xD8, 0xFF, 0xE0 };
    try testing.expectEqual(ImageFormat.jpeg, ImageLoader.detectFormat(jpeg_data));

    // Test GIF magic bytes
    const gif_data = &[_]u8{ 'G', 'I', 'F', '8' };
    try testing.expectEqual(ImageFormat.gif, ImageLoader.detectFormat(gif_data));

    // Test BMP magic bytes
    const bmp_data = &[_]u8{ 'B', 'M', 0x00, 0x00 };
    try testing.expectEqual(ImageFormat.bmp, ImageLoader.detectFormat(bmp_data));
}

test "ImageLoader cache" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var loader = ImageLoader.init(allocator);
    defer loader.deinit();

    // Create a test image in memory
    const test_data = &[_]u8{ 0x89, 0x50, 0x4E, 0x47 }; // PNG header
    const img1 = try loader.loadFromMemory(test_data, null);
    defer img1.deinit(allocator);
    try testing.expectEqual(ImageFormat.png, img1.format);
    try testing.expectEqual(@as(u32, 1), img1.width);
    try testing.expectEqual(@as(u32, 1), img1.height);
}
