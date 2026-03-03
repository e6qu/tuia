//! Media support module for audio/video in presentations
const std = @import("std");

pub const MediaPlayer = @import("MediaPlayer.zig").MediaPlayer;
pub const MediaElement = @import("MediaElement.zig").MediaElement;
pub const MediaType = @import("MediaElement.zig").MediaType;
pub const MediaWidget = @import("MediaElement.zig").MediaWidget;
pub const MediaParser = @import("MediaElement.zig").MediaParser;
pub const MediaDirective = @import("MediaElement.zig").MediaDirective;
pub const PlaybackState = @import("MediaPlayer.zig").PlaybackState;

test {
    std.testing.refAllDecls(@This());
}
