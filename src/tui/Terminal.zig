//! Terminal — raw I/O, ANSI rendering, and input event loop
const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;

const Cell = @import("Cell.zig").Cell;
const Style = @import("Style.zig").Style;
const Color = @import("Style.zig").Color;
const Screen = @import("Screen.zig").Screen;
const Window = @import("Window.zig").Window;
const Key = @import("Key.zig").Key;
const tui_root = @import("root.zig");
const Winsize = tui_root.Winsize;
const Event = tui_root.Event;

/// Terminal manages raw-mode I/O, screen rendering, and input parsing.
pub const Terminal = struct {
    // Fixed memory budget
    const MAX_COLS: u16 = 320;
    const MAX_ROWS: u16 = 100;
    const MAX_CELLS: usize = @as(usize, MAX_COLS) * MAX_ROWS;
    const RENDER_BUF_SIZE: usize = 65536;
    const FLUSH_THRESHOLD: usize = 60000;

    fd: posix.fd_t,
    owned_fd: bool,
    original_termios: posix.termios,
    screen: Screen,
    back_buf: []Cell,
    cell_storage: []Cell, // single allocation, split: [0..MAX_CELLS] = screen, [MAX_CELLS..2*MAX_CELLS] = back
    _allocator: std.mem.Allocator, // only for freeing cell_storage in deinit
    first_render: bool = true,

    // Fixed render buffer — no per-frame allocation
    render_buf: [RENDER_BUF_SIZE]u8 = undefined,
    render_len: usize = 0,

    // Event loop
    event_thread: ?std.Thread = null,
    queue: EventQueue = .{},
    should_quit: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    // Self-pipe for waking the reader on SIGWINCH / quit
    signal_pipe: [2]posix.fd_t = .{ -1, -1 },
    readloop_alive: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    render_failed: bool = false,

    const EventQueue = Queue(Event, 512);

    // ── lifecycle ────────────────────────────────────────────────────

    pub fn init(allocator: std.mem.Allocator) !Terminal {
        comptime if (builtin.os.tag == .windows) @compileError("Terminal requires a POSIX system");

        var owned_fd = true;
        const fd = if (std.posix.getenv("TUIA_TTY_FD")) |fd_str| blk: {
            owned_fd = false;
            break :blk std.fmt.parseInt(posix.fd_t, fd_str, 10) catch
                return error.InvalidTtyFd;
        } else blk: {
            // Prefer stdin when it's a tty (works in both real terminals and pty contexts),
            // fall back to /dev/tty for cases where stdin is redirected (pipes, etc.)
            if (posix.isatty(posix.STDIN_FILENO)) {
                owned_fd = false;
                break :blk posix.STDIN_FILENO;
            }
            // Use raw syscall to avoid Zig's unexpectedErrno stack trace on ENXIO
            const rc = std.posix.system.open("/dev/tty", @bitCast(std.posix.O{ .ACCMODE = .RDWR }), @as(posix.mode_t, 0));
            if (rc < 0) return error.NoTerminal;
            break :blk @as(posix.fd_t, @intCast(rc));
        };
        errdefer if (owned_fd) posix.close(fd);

        const original = try posix.tcgetattr(fd);
        var raw = original;

        raw.iflag.IGNBRK = false;
        raw.iflag.BRKINT = false;
        raw.iflag.PARMRK = false;
        raw.iflag.ISTRIP = false;
        raw.iflag.INLCR = false;
        raw.iflag.IGNCR = false;
        raw.iflag.ICRNL = false;
        raw.iflag.IXON = false;

        raw.oflag.OPOST = false;

        raw.lflag.ECHO = false;
        raw.lflag.ECHONL = false;
        raw.lflag.ICANON = false;
        raw.lflag.ISIG = false;
        raw.lflag.IEXTEN = false;

        raw.cflag.CSIZE = .CS8;
        raw.cflag.PARENB = false;

        raw.cc[@intFromEnum(posix.V.MIN)] = 1;
        raw.cc[@intFromEnum(posix.V.TIME)] = 0;

        try posix.tcsetattr(fd, .FLUSH, raw);

        const ws = try getWinsize(fd);
        const cols = @min(ws.cols, MAX_COLS);
        const rows = @min(ws.rows, MAX_ROWS);

        // Single allocation for both screen and back buffer
        const cell_storage = try allocator.alloc(Cell, 2 * MAX_CELLS);
        errdefer allocator.free(cell_storage);

        const screen_buf = cell_storage[0..MAX_CELLS];
        const back_buf = cell_storage[MAX_CELLS .. 2 * MAX_CELLS];

        const screen = Screen.init(screen_buf, cols, rows);
        @memset(back_buf[0 .. @as(usize, cols) * rows], Cell{});

        const pipe = try posix.pipe();

        return .{
            .fd = fd,
            .owned_fd = owned_fd,
            .original_termios = original,
            .screen = screen,
            .back_buf = back_buf[0 .. @as(usize, cols) * rows],
            .cell_storage = cell_storage,
            ._allocator = allocator,
            .signal_pipe = pipe,
        };
    }

    pub fn deinit(self: *Terminal) void {
        // Exit alt screen + reset style + show cursor
        const file = std.fs.File{ .handle = self.fd };
        file.writeAll("\x1b[?1049l\x1b[0m\x1b[?25h") catch {};

        posix.tcsetattr(self.fd, .FLUSH, self.original_termios) catch {};
        if (self.owned_fd) posix.close(self.fd);

        self.screen.deinit();
        self._allocator.free(self.cell_storage);

        if (self.signal_pipe[0] != -1) posix.close(self.signal_pipe[0]);
        if (self.signal_pipe[1] != -1) posix.close(self.signal_pipe[1]);
    }

    // ── alt screen ──────────────────────────────────────────────────

    pub fn enterAltScreen(self: *Terminal) !void {
        const file = std.fs.File{ .handle = self.fd };
        try file.writeAll("\x1b[?1049h\x1b[?25l");
    }

    /// No-op — we don't query terminal capabilities in the minimal layer
    pub fn queryTerminal(self: *Terminal) void {
        _ = self;
    }

    // ── screen access ───────────────────────────────────────────────

    pub fn window(self: *Terminal) Window {
        return .{
            .x_off = 0,
            .y_off = 0,
            .width = self.screen.width,
            .height = self.screen.height,
            .screen = &self.screen,
        };
    }

    /// Resize screen and back buffer within pre-allocated storage. No allocation.
    pub fn resize(self: *Terminal, ws: Winsize) void {
        const cols = @min(ws.cols, MAX_COLS);
        const rows = @min(ws.rows, MAX_ROWS);
        self.screen.resize(self.cell_storage[0..MAX_CELLS], cols, rows);
        const len = @as(usize, cols) * rows;
        self.back_buf = self.cell_storage[MAX_CELLS .. MAX_CELLS + len];
        @memset(self.back_buf, Cell{});
        self.first_render = true;
    }

    // ── rendering ───────────────────────────────────────────────────

    pub fn render(self: *Terminal) !void {
        self.render_len = 0;

        // Sync start + hide cursor
        self.appendLiteral("\x1b[?2026h\x1b[?25l");

        var last_style: Style = .{};
        var last_row: ?u16 = null;
        var last_col: u16 = 0;
        var need_sgr_reset = true; // first cell always needs style

        const w: usize = self.screen.width;
        const h: usize = self.screen.height;

        for (0..h) |row| {
            for (0..w) |col| {
                const idx = row * w + col;
                if (idx >= self.screen.buf.len) break;
                const cell = self.screen.buf[idx];

                if (!self.first_render and idx < self.back_buf.len and cellEql(cell, self.back_buf[idx])) {
                    need_sgr_reset = true;
                    continue;
                }

                // Flush if approaching buffer limit
                if (self.render_len >= FLUSH_THRESHOLD) {
                    self.flushRenderBuf();
                }

                // Move cursor if not sequential
                const r: u16 = @intCast(row);
                const c: u16 = @intCast(col);
                if (last_row != r or last_col != c) {
                    var pos: [16]u8 = undefined;
                    const n = std.fmt.bufPrint(&pos, "\x1b[{d};{d}H", .{ r + 1, c + 1 }) catch continue;
                    self.appendBytes(n);
                    need_sgr_reset = true;
                }

                // Emit SGR if style changed
                if (need_sgr_reset or !styleEql(cell.style, last_style)) {
                    self.emitSgrFixed(cell.style);
                    last_style = cell.style;
                    need_sgr_reset = false;
                }

                // Skip padding cells (width == 0, part of a wide char)
                if (cell.char.width == 0) {
                    last_row = r;
                    last_col = c + 1;
                    continue;
                }

                // Emit grapheme
                self.appendBytes(cell.char.grapheme);

                last_row = r;
                last_col = c + @as(u16, cell.char.width);
            }
        }

        // Reset style, sync end
        self.appendLiteral("\x1b[0m\x1b[?2026l");

        // Final flush
        self.flushRenderBuf();

        if (self.render_failed) return error.RenderFailed;

        // Copy screen → back buffer
        if (self.screen.buf.len == self.back_buf.len) {
            @memcpy(self.back_buf, self.screen.buf);
        }
        self.first_render = false;
    }

    // ── render buffer helpers ───────────────────────────────────────

    fn appendBytes(self: *Terminal, bytes: []const u8) void {
        const avail = RENDER_BUF_SIZE - self.render_len;
        const n = @min(bytes.len, avail);
        @memcpy(self.render_buf[self.render_len .. self.render_len + n], bytes[0..n]);
        self.render_len += n;
    }

    fn appendLiteral(self: *Terminal, comptime literal: []const u8) void {
        self.appendBytes(literal);
    }

    fn appendByte(self: *Terminal, byte: u8) void {
        if (self.render_len < RENDER_BUF_SIZE) {
            self.render_buf[self.render_len] = byte;
            self.render_len += 1;
        }
    }

    fn flushRenderBuf(self: *Terminal) void {
        if (self.render_len == 0) return;
        const file = std.fs.File{ .handle = self.fd };
        file.writeAll(self.render_buf[0..self.render_len]) catch {
            self.render_failed = true;
        };
        self.render_len = 0;
    }

    // ── SGR encoding (fixed buffer) ─────────────────────────────────

    fn emitSgrFixed(self: *Terminal, style: Style) void {
        self.appendLiteral("\x1b[0");
        if (style.bold) self.appendLiteral(";1");
        if (style.dim) self.appendLiteral(";2");
        if (style.italic) self.appendLiteral(";3");
        switch (style.ul_style) {
            .single => self.appendLiteral(";4"),
            .double => self.appendLiteral(";4:2"),
            .curly => self.appendLiteral(";4:3"),
            .dotted => self.appendLiteral(";4:4"),
            .dashed => self.appendLiteral(";4:5"),
            .off => {},
        }
        if (style.blink) self.appendLiteral(";5");
        if (style.reverse) self.appendLiteral(";7");
        if (style.invisible) self.appendLiteral(";8");
        if (style.strikethrough) self.appendLiteral(";9");

        self.emitColorFixed(style.fg, 38);
        self.emitColorFixed(style.bg, 48);

        self.appendByte('m');
    }

    fn emitColorFixed(self: *Terminal, color: Color, base: u8) void {
        var tmp: [24]u8 = undefined;
        switch (color) {
            .rgb => |rgb| {
                const s = std.fmt.bufPrint(&tmp, ";{d};2;{d};{d};{d}", .{ base, rgb[0], rgb[1], rgb[2] }) catch return;
                self.appendBytes(s);
            },
            .index => |idx| {
                const s = std.fmt.bufPrint(&tmp, ";{d};5;{d}", .{ base, idx }) catch return;
                self.appendBytes(s);
            },
            .default => {},
        }
    }

    // ── event loop ──────────────────────────────────────────────────

    pub fn start(self: *Terminal) !void {
        if (self.event_thread != null) return;

        // Install SIGWINCH handler
        installSigwinch(self.signal_pipe[1]);

        // Post initial winsize
        const ws = try getWinsize(self.fd);
        self.queue.push(.{ .winsize = ws });

        self.event_thread = try std.Thread.spawn(.{}, readLoop, .{self});
    }

    pub fn stop(self: *Terminal) void {
        self.should_quit.store(true, .release);
        // Wake the reader
        _ = posix.write(self.signal_pipe[1], &[_]u8{0}) catch {};
        if (self.event_thread) |t| {
            t.join();
            self.event_thread = null;
        }
    }

    pub fn nextEvent(self: *Terminal) ?Event {
        while (true) {
            if (self.queue.tryPopTimeout(500_000_000)) |event| return event;
            if (self.should_quit.load(.acquire)) return null;
            if (!self.readloop_alive.load(.acquire)) return null;
        }
    }

    /// Like nextEvent but returns null on timeout instead of blocking.
    pub fn nextEventTimeout(self: *Terminal, timeout_ns: u64) ?Event {
        if (self.queue.tryPopTimeout(timeout_ns)) |event| return event;
        // Return null on timeout — caller should NOT treat this as quit
        return null;
    }

    // ── background reader ───────────────────────────────────────────

    fn readLoop(self: *Terminal) void {
        self.readloop_alive.store(true, .release);
        defer self.readloop_alive.store(false, .release);

        var parse_buf: [256]u8 = undefined;
        var buf_len: usize = 0;

        while (!self.should_quit.load(.acquire)) {
            // poll on tty fd + signal pipe
            var fds = [_]posix.pollfd{
                .{ .fd = self.fd, .events = posix.POLL.IN, .revents = 0 },
                .{ .fd = self.signal_pipe[0], .events = posix.POLL.IN, .revents = 0 },
            };
            const n = posix.poll(&fds, 100) catch continue; // 100ms timeout
            if (n == 0) continue;

            // SIGWINCH pipe
            if (fds[1].revents & posix.POLL.IN != 0) {
                var drain: [16]u8 = undefined;
                _ = posix.read(self.signal_pipe[0], &drain) catch {};
                if (getWinsize(self.fd)) |ws| {
                    self.queue.push(.{ .winsize = ws });
                } else |_| {}
            }

            // TTY input
            if (fds[0].revents & posix.POLL.IN != 0) {
                const avail = parse_buf.len - buf_len;
                if (avail == 0) {
                    buf_len = 0;
                    continue;
                }
                const nr = posix.read(self.fd, parse_buf[buf_len..]) catch continue;
                if (nr == 0) continue;
                buf_len += nr;

                var pos: usize = 0;
                while (pos < buf_len) {
                    const result = parseKey(parse_buf[pos..buf_len]);
                    if (result.len == 0) break; // need more data
                    self.queue.push(.{ .key = result.key });
                    pos += result.len;
                }
                // Shift remaining bytes
                if (pos > 0 and pos < buf_len) {
                    std.mem.copyForwards(u8, &parse_buf, parse_buf[pos..buf_len]);
                    buf_len -= pos;
                } else if (pos >= buf_len) {
                    buf_len = 0;
                }
            }
        }
    }

    // ── escape sequence parser ──────────────────────────────────────

    const ParseResult = struct { key: Key, len: usize };

    fn parseKey(buf: []const u8) ParseResult {
        if (buf.len == 0) return .{ .key = .{}, .len = 0 };

        const b = buf[0];

        // ESC — start of escape sequence
        if (b == 0x1B) {
            if (buf.len == 1) {
                return .{ .key = .{ .codepoint = Key.escape }, .len = 1 };
            }
            if (buf[1] == '[') return parseCsi(buf);
            if (buf[1] == 'O') return parseSs3(buf);
            // Alt + character
            if (buf.len >= 2) {
                return .{
                    .key = .{ .codepoint = buf[1], .mods = .{ .alt = true } },
                    .len = 2,
                };
            }
        }

        // Backspace
        if (b == 0x7F) {
            return .{ .key = .{ .codepoint = Key.backspace }, .len = 1 };
        }

        // Tab (0x09 = Ctrl+I, but we want it as Tab)
        if (b == 0x09) {
            return .{ .key = .{ .codepoint = Key.tab }, .len = 1 };
        }

        // Enter / carriage return (0x0D = Ctrl+M, 0x0A = Ctrl+J, but we want Enter)
        if (b == 0x0D or b == 0x0A) {
            return .{ .key = .{ .codepoint = Key.enter }, .len = 1 };
        }

        // Ctrl+letter (0x01..0x1A), excluding Tab (0x09) and Enter (0x0D, 0x0A)
        if (b >= 1 and b <= 26) {
            return .{
                .key = .{ .codepoint = @as(u21, b) + 'a' - 1, .mods = .{ .ctrl = true } },
                .len = 1,
            };
        }

        // Regular printable ASCII
        if (b >= 0x20 and b <= 0x7E) {
            return .{ .key = .{ .codepoint = b }, .len = 1 };
        }

        // UTF-8 multi-byte
        if (b >= 0x80) {
            const seq_len = std.unicode.utf8ByteSequenceLength(b) catch return .{ .key = .{}, .len = 1 };
            if (buf.len < seq_len) return .{ .key = .{}, .len = 0 }; // need more
            const cp = std.unicode.utf8Decode(buf[0..seq_len]) catch return .{ .key = .{}, .len = seq_len };
            return .{ .key = .{ .codepoint = cp }, .len = seq_len };
        }

        // Unrecognized — skip
        return .{ .key = .{}, .len = 1 };
    }

    fn parseCsi(buf: []const u8) ParseResult {
        // buf starts with ESC [
        if (buf.len < 3) return .{ .key = .{}, .len = 0 };
        const final = buf[2];
        // Simple CSI: ESC [ <letter>
        switch (final) {
            'A' => return .{ .key = .{ .codepoint = Key.up }, .len = 3 },
            'B' => return .{ .key = .{ .codepoint = Key.down }, .len = 3 },
            'C' => return .{ .key = .{ .codepoint = Key.right }, .len = 3 },
            'D' => return .{ .key = .{ .codepoint = Key.left }, .len = 3 },
            'H' => return .{ .key = .{ .codepoint = Key.home }, .len = 3 },
            'F' => return .{ .key = .{ .codepoint = Key.end }, .len = 3 },
            'Z' => return .{ .key = .{ .codepoint = Key.tab, .mods = .{ .shift = true } }, .len = 3 },
            else => {},
        }
        // Parameterised CSI: ESC [ <digits> ~  or  ESC [ 1 ; <mod> <letter>
        var i: usize = 2;
        while (i < buf.len) : (i += 1) {
            const c = buf[i];
            if ((c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z') or c == '~') {
                if (c == '~') {
                    const param = std.fmt.parseInt(u16, buf[2..i], 10) catch 0;
                    return .{
                        .key = .{ .codepoint = tildeCp(param) },
                        .len = i + 1,
                    };
                }
                const key = switch (c) {
                    'A' => Key.up,
                    'B' => Key.down,
                    'C' => Key.right,
                    'D' => Key.left,
                    'H' => Key.home,
                    'F' => Key.end,
                    'P' => Key.f1,
                    'Q' => Key.f2,
                    'R' => Key.f3,
                    'S' => Key.f4,
                    else => @as(u21, 0),
                };
                return .{ .key = .{ .codepoint = key }, .len = i + 1 };
            }
        }
        return .{ .key = .{}, .len = 0 };
    }

    fn parseSs3(buf: []const u8) ParseResult {
        if (buf.len < 3) return .{ .key = .{}, .len = 0 };
        const key: u21 = switch (buf[2]) {
            'P' => Key.f1,
            'Q' => Key.f2,
            'R' => Key.f3,
            'S' => Key.f4,
            'A' => Key.up,
            'B' => Key.down,
            'C' => Key.right,
            'D' => Key.left,
            'H' => Key.home,
            'F' => Key.end,
            else => 0,
        };
        return .{ .key = .{ .codepoint = key }, .len = 3 };
    }

    fn tildeCp(param: u16) u21 {
        return switch (param) {
            1 => Key.home,
            2 => Key.insert,
            3 => Key.delete,
            4 => Key.end,
            5 => Key.page_up,
            6 => Key.page_down,
            11 => Key.f1,
            12 => Key.f2,
            13 => Key.f3,
            14 => Key.f4,
            15 => Key.f5,
            17 => Key.f6,
            18 => Key.f7,
            19 => Key.f8,
            20 => Key.f9,
            21 => Key.f10,
            23 => Key.f11,
            24 => Key.f12,
            else => 0,
        };
    }

    // ── helpers ─────────────────────────────────────────────────────

    fn getWinsize(fd: posix.fd_t) !Winsize {
        var ws: posix.winsize = undefined;
        const rc = std.posix.system.ioctl(fd, std.posix.T.IOCGWINSZ, @intFromPtr(&ws));
        if (rc != 0) return error.IoctlFailed;
        return .{
            .rows = ws.row,
            .cols = ws.col,
            .x_pixel = ws.xpixel,
            .y_pixel = ws.ypixel,
        };
    }

    // Global SIGWINCH handler — writes to a pipe to wake the reader
    var g_sigwinch_pipe: posix.fd_t = -1;

    fn installSigwinch(pipe_w: posix.fd_t) void {
        g_sigwinch_pipe = pipe_w;
        const sa = posix.Sigaction{
            .handler = .{ .handler = sigwinchHandler },
            .mask = switch (builtin.os.tag) {
                .macos => 0,
                else => posix.sigemptyset(),
            },
            .flags = posix.SA.RESTART,
        };
        posix.sigaction(posix.SIG.WINCH, &sa, null);
    }

    fn sigwinchHandler(_: c_int) callconv(.c) void {
        if (g_sigwinch_pipe != -1) {
            _ = posix.write(g_sigwinch_pipe, &[_]u8{1}) catch {};
        }
    }

    // ── comparison helpers ──────────────────────────────────────────

    fn cellEql(a: Cell, b: Cell) bool {
        return std.mem.eql(u8, a.char.grapheme, b.char.grapheme) and
            a.char.width == b.char.width and styleEql(a.style, b.style);
    }

    fn styleEql(a: Style, b: Style) bool {
        return colorEql(a.fg, b.fg) and colorEql(a.bg, b.bg) and
            a.bold == b.bold and a.dim == b.dim and
            a.italic == b.italic and a.ul_style == b.ul_style and
            a.blink == b.blink and a.reverse == b.reverse and
            a.invisible == b.invisible and a.strikethrough == b.strikethrough;
    }

    fn colorEql(a: Color, b: Color) bool {
        const tag_a: u2 = switch (a) {
            .default => 0,
            .index => 1,
            .rgb => 2,
        };
        const tag_b: u2 = switch (b) {
            .default => 0,
            .index => 1,
            .rgb => 2,
        };
        if (tag_a != tag_b) return false;
        return switch (a) {
            .default => true,
            .index => |ia| ia == b.index,
            .rgb => |ra| ra[0] == b.rgb[0] and ra[1] == b.rgb[1] and ra[2] == b.rgb[2],
        };
    }
};

// ── thread-safe ring queue ──────────────────────────────────────────

fn Queue(comptime T: type, comptime N: usize) type {
    return struct {
        buf: [N]T = undefined,
        head: usize = 0,
        tail: usize = 0,
        count: usize = 0,
        mutex: std.Thread.Mutex = .{},
        not_empty: std.Thread.Condition = .{},

        const Self = @This();

        pub fn push(self: *Self, item: T) void {
            self.mutex.lock();
            defer self.mutex.unlock();
            if (self.count == N) {
                // Drop oldest
                self.head = (self.head + 1) % N;
                self.count -= 1;
            }
            self.buf[self.tail] = item;
            self.tail = (self.tail + 1) % N;
            self.count += 1;
            self.not_empty.signal();
        }

        pub fn pop(self: *Self) T {
            self.mutex.lock();
            defer self.mutex.unlock();
            while (self.count == 0) {
                self.not_empty.wait(&self.mutex);
            }
            const item = self.buf[self.head];
            self.head = (self.head + 1) % N;
            self.count -= 1;
            return item;
        }

        pub fn tryPopTimeout(self: *Self, timeout_ns: u64) ?T {
            self.mutex.lock();
            defer self.mutex.unlock();
            while (self.count == 0) {
                self.not_empty.timedWait(&self.mutex, timeout_ns) catch return null;
            }
            const item = self.buf[self.head];
            self.head = (self.head + 1) % N;
            self.count -= 1;
            return item;
        }
    };
}
