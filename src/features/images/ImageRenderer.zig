//! Unified image renderer that selects the best protocol
const std = @import("std");
const Image = @import("ImageLoader.zig").Image;
const KittyGraphics = @import("KittyGraphics.zig").KittyGraphics;
const ITerm2Graphics = @import("ITerm2Graphics.zig").ITerm2Graphics;
const SixelGraphics = @import("SixelGraphics.zig").SixelGraphics;
const AsciiArt = @import("AsciiArt.zig").AsciiArt;

/// Available image protocols
pub const Protocol = enum {
    kitty,
    iterm2,
    sixel,
    ascii,
    none,
};

/// ImageRenderer automatically selects the best available protocol
pub const ImageRenderer = struct {
    allocator: std.mem.Allocator,
    protocol: Protocol,
    kitty: ?KittyGraphics,
    iterm2: ?ITerm2Graphics,
    sixel: ?SixelGraphics,
    ascii: ?AsciiArt,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        // Auto-detect best protocol
        const protocol = detectBestProtocol();

        return .{
            .allocator = allocator,
            .protocol = protocol,
            .kitty = if (protocol == .kitty) KittyGraphics.init(allocator) else null,
            .iterm2 = if (protocol == .iterm2) ITerm2Graphics.init(allocator) else null,
            .sixel = if (protocol == .sixel) SixelGraphics.init(allocator) else null,
            .ascii = if (protocol == .ascii) AsciiArt.init(allocator) else null,
        };
    }

    pub fn deinit(self: *Self) void {
        // Nothing to deinit for now
        _ = self;
    }

    /// Detect the best available image protocol
    pub fn detectBestProtocol() Protocol {
        // Priority order: Kitty > iTerm2 > Sixel > ASCII
        if (KittyGraphics.isSupported()) return .kitty;
        if (ITerm2Graphics.isSupported()) return .iterm2;
        if (SixelGraphics.isSupported()) return .sixel;
        return .ascii;
    }

    /// Render an image to the terminal
    pub fn render(
        self: Self,
        image: Image,
        options: RenderOptions,
    ) ![]const u8 {
        return switch (self.protocol) {
            .kitty => {
                if (self.kitty) |kitty| {
                    return try kitty.encodeImage(image, .{
                        .columns = options.width_cells,
                        .rows = options.height_cells,
                        .width = options.width_pixels,
                        .height = options.height_pixels,
                    });
                }
                return error.ProtocolNotAvailable;
            },
            .iterm2 => {
                if (self.iterm2) |iterm2| {
                    return try iterm2.encodeImage(image, .{
                        .width = options.width_pixels,
                        .height = options.height_pixels,
                        .width_cells = options.width_cells,
                        .height_cells = options.height_cells,
                        .preserve_aspect_ratio = options.preserve_aspect_ratio,
                        .inline_mode = true,
                    });
                }
                return error.ProtocolNotAvailable;
            },
            .sixel => {
                if (self.sixel) |sixel| {
                    return try sixel.encodeImage(image, .{
                        .width = options.width_pixels,
                        .height = options.height_pixels,
                        .max_width = options.max_width,
                        .max_height = options.max_height,
                    });
                }
                return error.ProtocolNotAvailable;
            },
            .ascii => {
                if (self.ascii) |ascii| {
                    if (options.use_blocks) {
                        return try ascii.convertBlocks(image, .{
                            .width = options.width_cells orelse 80,
                            .height = options.height_cells orelse 24,
                            .invert = options.invert,
                            .use_blocks = true,
                        });
                    } else {
                        return try ascii.convert(image, .{
                            .width = options.width_cells orelse 80,
                            .height = options.height_cells orelse 24,
                            .invert = options.invert,
                            .use_blocks = false,
                        });
                    }
                }
                return error.ProtocolNotAvailable;
            },
            .none => error.NoProtocolAvailable,
        };
    }

    /// Get the name of the current protocol
    pub fn getProtocolName(self: Self) []const u8 {
        return switch (self.protocol) {
            .kitty => "Kitty",
            .iterm2 => "iTerm2",
            .sixel => "Sixel",
            .ascii => "ASCII Art",
            .none => "None",
        };
    }

    /// Check if a specific protocol is supported
    pub fn isProtocolSupported(protocol: Protocol) bool {
        return switch (protocol) {
            .kitty => KittyGraphics.isSupported(),
            .iterm2 => ITerm2Graphics.isSupported(),
            .sixel => SixelGraphics.isSupported(),
            .ascii => true,
            .none => false,
        };
    }
};

/// Render options
pub const RenderOptions = struct {
    /// Width in character columns
    width_cells: ?u32 = null,
    /// Height in character rows
    height_cells: ?u32 = null,
    /// Width in pixels
    width_pixels: ?u32 = null,
    /// Height in pixels
    height_pixels: ?u32 = null,
    /// Maximum width
    max_width: ?u32 = null,
    /// Maximum height
    max_height: ?u32 = null,
    /// Preserve aspect ratio
    preserve_aspect_ratio: bool = true,
    /// Use block characters (for ASCII mode)
    use_blocks: bool = true,
    /// Invert colors (for ASCII mode)
    invert: bool = false,
};

/// Error types
pub const RenderError = error{
    ProtocolNotAvailable,
    NoProtocolAvailable,
    UnsupportedFormat,
    OutOfMemory,
};

test "ImageRenderer protocol detection" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var renderer = ImageRenderer.init(allocator);
    defer renderer.deinit();

    // Should select a valid protocol
    try testing.expect(renderer.protocol != .none);

    // Should have a protocol name
    const name = renderer.getProtocolName();
    try testing.expect(name.len > 0);
}

test "ImageRenderer isProtocolSupported" {
    // ASCII should always be supported
    try std.testing.expect(ImageRenderer.isProtocolSupported(.ascii));
}
