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

test {
    std.testing.refAllDecls(@This());
}
