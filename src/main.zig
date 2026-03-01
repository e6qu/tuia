const std = @import("std");
const vaxis = @import("vaxis");

const Event = union(enum) {
    key: vaxis.Key,
    winsize: vaxis.Winsize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.detectLeaks()) {
            std.log.err("Memory leaks detected!", .{});
        }
    }
    const alloc = gpa.allocator();

    // Initialize vaxis
    var tty_buffer: [4096]u8 = undefined;
    var tty = try vaxis.Tty.init(&tty_buffer);
    defer tty.deinit();

    var vx = try vaxis.init(alloc, .{});
    defer vx.deinit(alloc, tty.writer());

    try vx.enterAltScreen(tty.writer());
    try vx.queryTerminal(tty.writer(), 1 * std.time.ns_per_s);

    // Set up event loop
    var loop: vaxis.Loop(Event) = .{
        .tty = &tty,
        .vaxis = &vx,
    };
    try loop.init();

    try loop.start();
    defer loop.stop();

    // Main event loop
    while (true) {
        const event = loop.nextEvent();
        switch (event) {
            .key => |key| {
                // Quit on Ctrl+C or 'q'
                if (key.codepoint == 'c' and key.mods.ctrl) {
                    break;
                }
                if (key.codepoint == 'q') {
                    break;
                }
            },
            .winsize => {}, // Vaxis handles this internally
        }

        // Render
        const win = vx.window();
        win.clear();

        // Simple welcome message
        const msg = "Welcome to tuia! Press 'q' or Ctrl+C to quit.";
        const col = if (win.width > msg.len) @divTrunc(win.width - @as(u16, @intCast(msg.len)), 2) else 0;
        const row = @divTrunc(win.height, 2);

        win.writeCell(col, row, .{ .char = .{ .grapheme = msg } });

        try vx.render(tty.writer());
    }
}
