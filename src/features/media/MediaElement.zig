//! Media element types for presentations
const std = @import("std");

/// Media element for audio/video in presentations
pub const MediaElement = struct {
    /// File path or URL
    path: []const u8,
    
    /// Media type
    media_type: MediaType,
    
    /// Display title/caption
    title: ?[]const u8,
    
    /// Auto-play on slide load
    autoplay: bool,
    
    /// Loop playback
    loop: bool,
    
    /// Start time in seconds
    start_time: u32,
    
    /// End time in seconds (0 = until end)
    end_time: u32,
    
    /// Volume (0-100)
    volume: u8,
    
    /// Show controls
    controls: bool,
    
    /// Mute audio
    muted: bool,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, path: []const u8, media_type: MediaType) !Self {
        return .{
            .path = try allocator.dupe(u8, path),
            .media_type = media_type,
            .title = null,
            .autoplay = false,
            .loop = false,
            .start_time = 0,
            .end_time = 0,
            .volume = 100,
            .controls = true,
            .muted = false,
        };
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        allocator.free(self.path);
        if (self.title) |t| allocator.free(t);
    }

    pub fn clone(self: Self, allocator: std.mem.Allocator) !Self {
        var copy = self;
        copy.path = try allocator.dupe(u8, self.path);
        if (self.title) |t| {
            copy.title = try allocator.dupe(u8, t);
        }
        return copy;
    }
};

/// Media type enumeration
pub const MediaType = enum {
    audio,
    video,

    pub fn fromExtension(ext: []const u8) ?MediaType {
        const audio_exts = &[_][]const u8{
            ".mp3", ".wav", ".ogg", ".flac", ".aac", ".m4a", ".wma",
        };
        const video_exts = &[_][]const u8{
            ".mp4", ".avi", ".mkv", ".mov", ".webm", ".flv", ".wmv",
        };

        var lower_buf: [16]u8 = undefined;
        const lower = std.ascii.lowerString(&lower_buf, ext);

        for (audio_exts) |e| {
            if (std.mem.eql(u8, lower, e)) return .audio;
        }
        for (video_exts) |e| {
            if (std.mem.eql(u8, lower, e)) return .video;
        }
        return null;
    }

    pub fn toString(self: MediaType) []const u8 {
        return switch (self) {
            .audio => "audio",
            .video => "video",
        };
    }
};

/// Media widget for rendering media elements in slides
pub const MediaWidget = struct {
    allocator: std.mem.Allocator,
    element: MediaElement,
    is_playing: bool,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, element: MediaElement) !Self {
        return .{
            .allocator = allocator,
            .element = try element.clone(allocator),
            .is_playing = false,
        };
    }

    pub fn deinit(self: *Self) void {
        self.element.deinit(self.allocator);
    }

    /// Draw media placeholder in slide
    pub fn draw(self: Self, win: anytype, theme: anytype) void {
        _ = self;
        _ = win;
        _ = theme;
        // Media elements show as placeholders in TUI
        // Actual playback is handled by external player
    }

    /// Get display text for the media element
    pub fn getDisplayText(self: Self, allocator: std.mem.Allocator) ![]const u8 {
        if (self.element.title) |t| {
            return std.fmt.allocPrint(allocator, "[{s}: {s}]", .{
                self.element.media_type.toString(),
                t,
            });
        } else {
            return std.fmt.allocPrint(allocator, "[{s}: {s}]", .{
                self.element.media_type.toString(),
                std.fs.path.basename(self.element.path),
            });
        }
    }
};

/// Media parser for markdown syntax
/// Supported syntax:
///   ![audio:file.mp3](file.mp3)
///   ![video:intro.mp4](intro.mp4)
///   @audio[autoplay loop](background.mp3)
///   @video[controls muted](demo.mp4)
pub const MediaParser = struct {
    /// Parse media directive from text
    pub fn parse(line: []const u8) ?MediaDirective {
        // Check for @audio or @video directive
        if (std.mem.startsWith(u8, line, "@audio")) {
            return parseDirective(line, .audio);
        } else if (std.mem.startsWith(u8, line, "@video")) {
            return parseDirective(line, .video);
        }
        return null;
    }

    fn parseDirective(line: []const u8, media_type: MediaType) ?MediaDirective {
        var result = MediaDirective{
            .media_type = media_type,
            .path = "",
            .autoplay = false,
            .loop = false,
            .controls = true,
            .muted = false,
        };

        // Find options in brackets [autoplay loop]
        const opts_start = std.mem.indexOf(u8, line, "[");
        const opts_end = std.mem.indexOf(u8, line, "]");

        if (opts_start) |start| {
            if (opts_end) |end| {
                if (end > start) {
                    const opts = line[start + 1 .. end];
                    if (std.mem.containsAtLeast(u8, opts, 1, "autoplay")) {
                        result.autoplay = true;
                    }
                    if (std.mem.containsAtLeast(u8, opts, 1, "loop")) {
                        result.loop = true;
                    }
                    if (std.mem.containsAtLeast(u8, opts, 1, "nocontrols")) {
                        result.controls = false;
                    }
                    if (std.mem.containsAtLeast(u8, opts, 1, "muted")) {
                        result.muted = true;
                    }
                }
            }
        }

        // Find path in parentheses (file.mp3)
        const path_start = std.mem.indexOf(u8, line, "(");
        const path_end = std.mem.indexOf(u8, line, ")");

        if (path_start) |start| {
            if (path_end) |end| {
                if (end > start + 1) {
                    result.path = line[start + 1 .. end];
                    return result;
                }
            }
        }

        return null;
    }
};

/// Media directive parsed from markdown
pub const MediaDirective = struct {
    media_type: MediaType,
    path: []const u8,
    autoplay: bool,
    loop: bool,
    controls: bool,
    muted: bool,
};

// Tests
test "MediaType fromExtension" {
    const testing = std.testing;

    try testing.expectEqual(MediaType.audio, MediaType.fromExtension(".mp3").?);
    try testing.expectEqual(MediaType.audio, MediaType.fromExtension(".wav").?);
    try testing.expectEqual(MediaType.video, MediaType.fromExtension(".mp4").?);
    try testing.expectEqual(MediaType.video, MediaType.fromExtension(".mov").?);
    try testing.expectEqual(null, MediaType.fromExtension(".txt"));
}

test "MediaParser parseDirective" {
    const testing = std.testing;

    const result = MediaParser.parse("@audio[autoplay loop](music.mp3)");
    try testing.expect(result != null);
    try testing.expectEqual(MediaType.audio, result.?.media_type);
    try testing.expectEqualStrings("music.mp3", result.?.path);
    try testing.expect(result.?.autoplay);
    try testing.expect(result.?.loop);

    const result2 = MediaParser.parse("@video[controls muted](demo.mp4)");
    try testing.expect(result2 != null);
    try testing.expectEqual(MediaType.video, result2.?.media_type);
    try testing.expect(result2.?.controls);
    try testing.expect(result2.?.muted);
}

test "MediaElement clone" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var elem = try MediaElement.init(allocator, "test.mp3", .audio);
    defer elem.deinit(allocator);

    elem.title = try allocator.dupe(u8, "Test Title");

    var copy = try elem.clone(allocator);
    defer copy.deinit(allocator);

    try testing.expectEqualStrings(elem.path, copy.path);
    try testing.expectEqualStrings(elem.title.?, copy.title.?);
}
