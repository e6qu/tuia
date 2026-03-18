//! Feature modules
const std = @import("std");

pub const images = @import("images/root.zig");

// Code execution
pub const executor = @import("executor/root.zig");
pub const CodeExecutor = executor.CodeExecutor;
pub const ExecutionResult = executor.ExecutionResult;
pub const Language = executor.Language;
pub const ExecutorRegistry = executor.ExecutorRegistry;

// Slide transitions
pub const transitions = @import("transitions/root.zig");
pub const TransitionManager = transitions.TransitionManager;
pub const TransitionType = transitions.TransitionType;
pub const TransitionConfig = transitions.TransitionConfig;

// Remote control
pub const remote = @import("remote/root.zig");
pub const RemoteServer = remote.RemoteServer;

// Media support
pub const media = @import("media/root.zig");
pub const MediaPlayer = media.MediaPlayer;
pub const MediaElement = media.MediaElement;
pub const MediaType = media.MediaType;

test {
    _ = @import("images/root.zig");
    _ = @import("executor/root.zig");
    _ = @import("transitions/root.zig");
    _ = @import("remote/root.zig");
    _ = @import("media/root.zig");
}
