//! Image display module for terminal presentations
const std = @import("std");

pub const ImageLoader = @import("ImageLoader.zig").ImageLoader;
pub const Image = @import("ImageLoader.zig").Image;
pub const ImageFormat = @import("ImageLoader.zig").ImageFormat;
pub const KittyGraphics = @import("KittyGraphics.zig").KittyGraphics;
pub const ITerm2Graphics = @import("ITerm2Graphics.zig").ITerm2Graphics;
pub const SixelGraphics = @import("SixelGraphics.zig").SixelGraphics;
pub const AsciiArt = @import("AsciiArt.zig").AsciiArt;
pub const ImageRenderer = @import("ImageRenderer.zig").ImageRenderer;
pub const Protocol = @import("ImageRenderer.zig").Protocol;

test {
    _ = @import("ImageLoader.zig");
    _ = @import("ImageRenderer.zig");
    _ = @import("KittyGraphics.zig");
    _ = @import("ITerm2Graphics.zig");
    _ = @import("SixelGraphics.zig");
    _ = @import("AsciiArt.zig");
}
