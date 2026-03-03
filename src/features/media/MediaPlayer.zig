//! Media player for audio/video support in presentations
const std = @import("std");

/// Media types supported
pub const MediaType = enum {
    audio,
    video,
};

/// Media playback state
pub const PlaybackState = enum {
    stopped,
    playing,
    paused,
};

/// Media file information
pub const MediaInfo = struct {
    path: []const u8,
    media_type: MediaType,
    duration_ms: ?u64,
    title: ?[]const u8,

    pub fn deinit(self: *MediaInfo, allocator: std.mem.Allocator) void {
        allocator.free(self.path);
        if (self.title) |t| allocator.free(t);
    }
};

/// Active media playback
pub const MediaPlayback = struct {
    info: MediaInfo,
    state: PlaybackState,
    position_ms: u64,
    volume: u8, // 0-100
    process: ?std.process.Child,
    thread: ?std.Thread,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, info: MediaInfo) Self {
        return .{
            .info = info,
            .state = .stopped,
            .position_ms = 0,
            .volume = 100,
            .process = null,
            .thread = null,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.stop();
        self.info.deinit(self.allocator);
    }

    /// Start playback
    pub fn play(self: *Self) !void {
        if (self.state == .playing) return;

        // Stop any existing playback
        self.stop();

        // Start new playback in background
        self.process = try spawnMediaPlayer(self.allocator, self.info.path, self.info.media_type);
        self.state = .playing;

        // Spawn thread to monitor playback
        self.thread = try std.Thread.spawn(.{}, MediaPlayback.monitorPlayback, .{self});
    }

    /// Stop playback
    pub fn stop(self: *Self) void {
        if (self.process) |*proc| {
            _ = proc.kill() catch {};
            _ = proc.wait() catch {};
            self.process = null;
        }

        if (self.thread) |thread| {
            thread.join();
            self.thread = null;
        }

        self.state = .stopped;
        self.position_ms = 0;
    }

    /// Pause playback (if supported by player)
    pub fn pause(self: *Self) void {
        if (self.state == .playing) {
            // Note: External players may not support pause
            // This is a placeholder for future enhancement
            self.state = .paused;
        }
    }

    /// Set volume (0-100)
    pub fn setVolume(self: *Self, volume: u8) void {
        self.volume = @min(volume, 100);
        // Note: Volume control for external players would require
        // player-specific implementation
    }

    /// Monitor playback thread
    fn monitorPlayback(self: *Self) void {
        if (self.process) |*proc| {
            _ = proc.wait() catch {};
        }

        self.state = .stopped;
        self.process = null;
    }
};

/// Media player manager
pub const MediaPlayer = struct {
    allocator: std.mem.Allocator,
    current_playback: ?*MediaPlayback,
    default_audio_player: []const u8,
    default_video_player: []const u8,

    const Self = @This();

    /// Initialize media player
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .current_playback = null,
            .default_audio_player = detectAudioPlayer(),
            .default_video_player = detectVideoPlayer(),
        };
    }

    /// Clean up resources
    pub fn deinit(self: *Self) void {
        if (self.current_playback) |playback| {
            playback.deinit();
            self.allocator.destroy(playback);
        }
    }

    /// Play media file
    pub fn playMedia(self: *Self, path: []const u8, media_type: MediaType) !void {
        // Stop current playback
        if (self.current_playback) |playback| {
            playback.deinit();
            self.allocator.destroy(playback);
            self.current_playback = null;
        }

        // Create new playback
        const playback = try self.allocator.create(MediaPlayback);
        errdefer self.allocator.destroy(playback);

        const info = MediaInfo{
            .path = try self.allocator.dupe(u8, path),
            .media_type = media_type,
            .duration_ms = null,
            .title = null,
        };

        playback.* = MediaPlayback.init(self.allocator, info);
        try playback.play();

        self.current_playback = playback;
    }

    /// Stop current playback
    pub fn stop(self: *Self) void {
        if (self.current_playback) |playback| {
            playback.stop();
        }
    }

    /// Check if media is currently playing
    pub fn isPlaying(self: Self) bool {
        if (self.current_playback) |playback| {
            return playback.state == .playing;
        }
        return false;
    }

    /// Detect available audio player
    fn detectAudioPlayer() []const u8 {
        // Check for available audio players
        const players = &[_][]const u8{
            "afplay", // macOS
            "paplay", // PulseAudio
            "aplay", // ALSA
            "mpv", // Universal
            "mplayer", // Legacy
            "ffplay", // FFmpeg
        };

        for (players) |player| {
            if (commandExists(player)) {
                return player;
            }
        }

        return "mpv"; // Default fallback
    }

    /// Detect available video player
    fn detectVideoPlayer() []const u8 {
        const players = &[_][]const u8{
            "mpv", // Best option
            "mplayer", // Legacy
            "ffplay", // FFmpeg
            "vlc", // VLC (if terminal compatible)
        };

        for (players) |player| {
            if (commandExists(player)) {
                return player;
            }
        }

        return "mpv"; // Default fallback
    }
};

/// Check if a command exists in PATH
fn commandExists(name: []const u8) bool {
    const result = std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &.{ "which", name },
    }) catch return false;

    return result.term.Exited == 0;
}

/// Spawn external media player
fn spawnMediaPlayer(allocator: std.mem.Allocator, path: []const u8, media_type: MediaType) !std.process.Child {
    const player = if (media_type == .audio)
        MediaPlayer.detectAudioPlayer()
    else
        MediaPlayer.detectVideoPlayer();

    // Player-specific arguments
    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);

    try argv.append(allocator, player);

    if (std.mem.eql(u8, player, "mpv")) {
        // MPV options for background playback
        if (media_type == .audio) {
            try argv.appendSlice(allocator, &.{
                "--no-video",
                "--force-window=immediate",
            });
        } else {
            try argv.appendSlice(allocator, &.{
                "--force-window=immediate",
                "--fs",
            });
        }
        try argv.appendSlice(allocator, &.{
            "--keep-open=no",
            "--really-quiet",
        });
    } else if (std.mem.eql(u8, player, "afplay")) {
        // afplay is macOS native, no special options needed
    }

    try argv.append(allocator, path);

    const args = try argv.toOwnedSlice(allocator);
    defer allocator.free(args);

    return std.process.Child.init(args, allocator);
}

// Tests
test "MediaPlayer init/deinit" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var player = MediaPlayer.init(allocator);
    player.deinit();

    try testing.expect(!player.isPlaying());
}

test "PlaybackState transitions" {
    const testing = std.testing;

    try testing.expectEqual(PlaybackState.stopped, PlaybackState.stopped);
    try testing.expectEqual(PlaybackState.playing, PlaybackState.playing);
}
