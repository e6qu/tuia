//! Key bindings configuration for presentation navigation
const std = @import("std");
const vaxis = @import("vaxis");

/// Available actions in the presentation
pub const Action = enum {
    next_slide,
    prev_slide,
    first_slide,
    last_slide,
    goto_slide,
    toggle_help,
    toggle_overview,
    quit,
    none,
};

/// Key binding definition
pub const KeyBinding = struct {
    key: vaxis.Key,
    action: Action,
    description: []const u8,
};

/// KeyBindings manages all keyboard shortcuts
pub const KeyBindings = struct {
    bindings: std.ArrayList(KeyBinding),
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize with default bindings
    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .bindings = .empty,
            .allocator = allocator,
        };

        // Set up default bindings
        self.addDefaults() catch |err| {
            std.debug.print("Failed to add default bindings: {s}\n", .{@errorName(err)});
        };

        return self;
    }

    /// Clean up
    pub fn deinit(self: *Self) void {
        self.bindings.deinit(self.allocator);
    }

    /// Add default key bindings
    fn addDefaults(self: *Self) !void {
        // Navigation
        try self.bind(.{ .codepoint = 'j', .mods = .{} }, .next_slide, "Next slide");
        try self.bind(.{ .codepoint = 'k', .mods = .{} }, .prev_slide, "Previous slide");
        try self.bind(.{ .codepoint = 'l', .mods = .{} }, .next_slide, "Next slide");
        try self.bind(.{ .codepoint = 'h', .mods = .{} }, .prev_slide, "Previous slide");
        try self.bind(.{ .codepoint = vaxis.Key.right, .mods = .{} }, .next_slide, "Next slide");
        try self.bind(.{ .codepoint = vaxis.Key.left, .mods = .{} }, .prev_slide, "Previous slide");
        try self.bind(.{ .codepoint = vaxis.Key.down, .mods = .{} }, .next_slide, "Next slide");
        try self.bind(.{ .codepoint = vaxis.Key.up, .mods = .{} }, .prev_slide, "Previous slide");
        try self.bind(.{ .codepoint = ' ', .mods = .{} }, .next_slide, "Next slide");
        try self.bind(.{ .codepoint = vaxis.Key.backspace, .mods = .{} }, .prev_slide, "Previous slide");

        // Jump to slide
        try self.bind(.{ .codepoint = 'g', .mods = .{} }, .first_slide, "First slide");
        try self.bind(.{ .codepoint = 'G', .mods = .{} }, .last_slide, "Last slide");
        try self.bind(.{ .codepoint = '1', .mods = .{} }, .goto_slide, "Go to slide");
        try self.bind(.{ .codepoint = '2', .mods = .{} }, .goto_slide, "Go to slide");
        try self.bind(.{ .codepoint = '3', .mods = .{} }, .goto_slide, "Go to slide");
        try self.bind(.{ .codepoint = '4', .mods = .{} }, .goto_slide, "Go to slide");
        try self.bind(.{ .codepoint = '5', .mods = .{} }, .goto_slide, "Go to slide");
        try self.bind(.{ .codepoint = '6', .mods = .{} }, .goto_slide, "Go to slide");
        try self.bind(.{ .codepoint = '7', .mods = .{} }, .goto_slide, "Go to slide");
        try self.bind(.{ .codepoint = '8', .mods = .{} }, .goto_slide, "Go to slide");
        try self.bind(.{ .codepoint = '9', .mods = .{} }, .goto_slide, "Go to slide");

        // UI toggles
        try self.bind(.{ .codepoint = '?', .mods = .{} }, .toggle_help, "Toggle help");
        try self.bind(.{ .codepoint = vaxis.Key.f1, .mods = .{} }, .toggle_help, "Toggle help");
        try self.bind(.{ .codepoint = 'o', .mods = .{} }, .toggle_overview, "Toggle overview");

        // Quit
        try self.bind(.{ .codepoint = 'q', .mods = .{} }, .quit, "Quit");
        try self.bind(.{ .codepoint = vaxis.Key.escape, .mods = .{} }, .quit, "Quit");
    }

    /// Add a key binding
    pub fn bind(self: *Self, key: vaxis.Key, action: Action, description: []const u8) !void {
        try self.bindings.append(self.allocator, .{
            .key = key,
            .action = action,
            .description = description,
        });
    }

    /// Lookup action for a key event
    pub fn lookup(self: Self, key_event: vaxis.Key) Action {
        for (self.bindings.items) |binding| {
            if (keysEqual(binding.key, key_event)) {
                return binding.action;
            }
        }
        return .none;
    }

    /// Check if two keys are equal
    fn keysEqual(a: vaxis.Key, b: vaxis.Key) bool {
        // Compare codepoint
        if (a.codepoint != b.codepoint) return false;
        if (a.mods.shift != b.mods.shift) return false;
        if (a.mods.ctrl != b.mods.ctrl) return false;
        if (a.mods.alt != b.mods.alt) return false;
        if (a.mods.super != b.mods.super) return false;
        return true;
    }

    /// Get all bindings for help display
    pub fn getBindings(self: Self) []const KeyBinding {
        return self.bindings.items;
    }

    /// Get bindings grouped by category for help
    pub fn getHelpText(_: Self, allocator: std.mem.Allocator) ![]const u8 {
        var result = std.ArrayList(u8).init(allocator);
        defer result.deinit();

        const writer = result.writer();

        try writer.writeAll("Navigation:\n");
        try writer.writeAll("  j, l, →, ↓, Space  Next slide\n");
        try writer.writeAll("  k, h, ←, ↑, Backspace  Previous slide\n");
        try writer.writeAll("  g                  First slide\n");
        try writer.writeAll("  G                  Last slide\n");
        try writer.writeAll("  1-9                Go to slide N\n");
        try writer.writeAll("\n");
        try writer.writeAll("UI:\n");
        try writer.writeAll("  ?, F1              Toggle help\n");
        try writer.writeAll("  o                  Toggle overview\n");
        try writer.writeAll("\n");
        try writer.writeAll("General:\n");
        try writer.writeAll("  q, Esc             Quit\n");

        return result.toOwnedSlice();
    }
};

test "KeyBindings defaults" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var bindings = KeyBindings.init(allocator);
    defer bindings.deinit();

    // Test navigation keys
    try testing.expectEqual(Action.next_slide, bindings.lookup(.{ .codepoint = 'j', .mods = .{} }));
    try testing.expectEqual(Action.prev_slide, bindings.lookup(.{ .codepoint = 'k', .mods = .{} }));
    try testing.expectEqual(Action.next_slide, bindings.lookup(.{ .codepoint = vaxis.Key.right, .mods = .{} }));
    try testing.expectEqual(Action.prev_slide, bindings.lookup(.{ .codepoint = vaxis.Key.left, .mods = .{} }));

    // Test slide jumping
    try testing.expectEqual(Action.first_slide, bindings.lookup(.{ .codepoint = 'g', .mods = .{} }));
    try testing.expectEqual(Action.last_slide, bindings.lookup(.{ .codepoint = 'G', .mods = .{} }));

    // Test UI toggles
    try testing.expectEqual(Action.toggle_help, bindings.lookup(.{ .codepoint = '?', .mods = .{} }));
    try testing.expectEqual(Action.toggle_overview, bindings.lookup(.{ .codepoint = 'o', .mods = .{} }));

    // Test quit
    try testing.expectEqual(Action.quit, bindings.lookup(.{ .codepoint = 'q', .mods = .{} }));
    try testing.expectEqual(Action.quit, bindings.lookup(.{ .codepoint = vaxis.Key.escape, .mods = .{} }));

    // Test unbound key
    try testing.expectEqual(Action.none, bindings.lookup(.{ .codepoint = 'z', .mods = .{} }));
}
