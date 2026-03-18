//! Slide transitions for presentation animations
const std = @import("std");

const TransitionModule = @import("Transition.zig");
pub const Transition = TransitionModule.TransitionInterface;
pub const TransitionManager = @import("TransitionManager.zig").TransitionManager;

// Re-export common types
pub const TransitionType = TransitionModule.TransitionType;
pub const TransitionState = TransitionModule.TransitionState;
pub const TransitionConfig = TransitionModule.TransitionConfig;
pub const Direction = TransitionModule.Direction;
pub const CellBuffer = TransitionModule.CellBuffer;

// Tests
test {
    _ = @import("Transition.zig");
    _ = @import("TransitionManager.zig");
}
