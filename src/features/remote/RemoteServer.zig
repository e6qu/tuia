//! Web server for remote presentation control
const std = @import("std");
const net = std.net;
const posix = std.posix;

const Navigation = @import("../../core/Navigation.zig").Navigation;

/// HTTP server for remote control
pub const RemoteServer = struct {
    allocator: std.mem.Allocator,
    port: u16,
    navigation: ?*Navigation,
    running: bool,
    server_thread: ?std.Thread,
    mutex: std.Thread.Mutex,

    const Self = @This();

    /// Initialize remote server
    pub fn init(allocator: std.mem.Allocator, port: u16) Self {
        return .{
            .allocator = allocator,
            .port = port,
            .navigation = null,
            .running = false,
            .server_thread = null,
            .mutex = .{},
        };
    }

    /// Start the remote server
    pub fn start(self: *Self, navigation: *Navigation) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.running) return;

        self.navigation = navigation;
        self.running = true;

        self.server_thread = try std.Thread.spawn(.{}, serverLoop, .{self});
    }

    /// Stop the remote server
    pub fn stop(self: *Self) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        if (!self.running) return;

        self.running = false;

        if (self.server_thread) |thread| {
            thread.join();
            self.server_thread = null;
        }
    }

    /// Server loop handling HTTP requests
    fn serverLoop(self: *Self) void {
        const address = net.Address.parseIp4("0.0.0.0", self.port) catch return;
        var tcp_server = address.listen(.{
            .kernel_backlog = 128,
        }) catch return;
        defer tcp_server.deinit();

        std.log.info("Remote control server started on http://localhost:{d}", .{self.port});

        while (self.isRunning()) {
            const conn = tcp_server.accept() catch |err| {
                std.log.err("Accept error: {s}", .{@errorName(err)});
                continue;
            };
            defer conn.stream.close();

            self.handleConnection(conn) catch |err| {
                std.log.err("Connection error: {s}", .{@errorName(err)});
            };
        }
    }

    /// Check if server is running
    fn isRunning(self: *Self) bool {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.running;
    }

    /// Handle a single HTTP connection
    fn handleConnection(self: *Self, conn: net.Server.Connection) !void {
        var buf: [4096]u8 = undefined;
        const bytes_read = try conn.stream.read(&buf);
        if (bytes_read == 0) return;

        const request = buf[0..bytes_read];

        // Parse request line
        var lines = std.mem.splitScalar(u8, request, '\n');
        const first_line = lines.next() orelse return;

        var parts = std.mem.splitScalar(u8, first_line, ' ');
        const method = parts.next() orelse return;
        const path = parts.next() orelse return;

        // Handle request
        if (std.mem.eql(u8, method, "GET")) {
            if (std.mem.eql(u8, path, "/")) {
                try self.sendControlPage(conn);
            } else if (std.mem.eql(u8, path, "/api/status")) {
                try self.sendStatus(conn);
            } else if (std.mem.eql(u8, path, "/api/next")) {
                try self.handleNext(conn);
            } else if (std.mem.eql(u8, path, "/api/prev")) {
                try self.handlePrev(conn);
            } else if (std.mem.eql(u8, path, "/api/first")) {
                try self.handleFirst(conn);
            } else if (std.mem.eql(u8, path, "/api/last")) {
                try self.handleLast(conn);
            } else if (std.mem.startsWith(u8, path, "/api/goto/")) {
                const slide_str = path[10..];
                try self.handleGoto(conn, slide_str);
            } else {
                try self.send404(conn);
            }
        } else {
            try self.send405(conn);
        }

        // MED-2 Fix: Properly shut down the write side of the connection
        // This signals to the client that we've finished sending data
        // Uses posix.shutdown directly since net.Stream doesn't expose it
        posix.shutdown(conn.stream.handle, .send) catch {};
    }

    /// Send the control page HTML
    fn sendControlPage(self: *Self, conn: net.Server.Connection) !void {
        const html =
            "<!DOCTYPE html>\n" ++
            "<html lang=\"en\">\n" ++
            "<head>\n" ++
            "<meta charset=\"UTF-8\">\n" ++
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n" ++
            "<title>TUIA Remote</title>\n" ++
            "<style>" ++
            "*{box-sizing:border-box;margin:0;padding:0}" ++
            "body{font-family:sans-serif;background:#1a1a1a;color:#fff;min-height:100vh;display:flex;flex-direction:column;padding:20px}" ++
            ".header{text-align:center;padding:20px;border-bottom:1px solid #333;margin-bottom:20px}" ++
            ".btn{background:#333;border:none;color:#fff;padding:20px;font-size:1.2rem;border-radius:12px;cursor:pointer;width:100%;margin:5px 0}" ++
            ".btn:active{background:#555}" ++
            ".btn.primary{background:#007AFF}" ++
            ".btn.danger{background:#FF3B30}" ++
            ".btn-row{display:flex;gap:10px}" ++
            ".btn-row .btn{flex:1}" ++
            ".goto-section{margin-top:20px;padding-top:20px;border-top:1px solid #333}" ++
            "input{background:#333;border:none;color:#fff;padding:15px;font-size:1.2rem;border-radius:8px;width:100%;text-align:center}" ++
            "</style>\n" ++
            "</head>\n" ++
            "<body>\n" ++
            "<div class=\"header\"><h1>TUIA Remote</h1><p>Slide <span id=\"c\">-</span> / <span id=\"t\">-</span></p></div>\n" ++
            "<div class=\"btn-row\"><button class=\"btn danger\" onclick=\"f('first')\">First</button><button class=\"btn\" onclick=\"f('prev')\">Prev</button></div>\n" ++
            "<button class=\"btn primary\" onclick=\"f('next')\">Next</button>\n" ++
            "<button class=\"btn\" onclick=\"f('prev')\">Prev</button>\n" ++
            "<button class=\"btn primary\" onclick=\"f('last')\">Last</button>\n" ++
            "<div class=\"goto-section\"><input type=\"number\" id=\"g\" placeholder=\"Go to slide\"><button class=\"btn primary\" onclick=\"gt()\">Go</button></div>\n" ++
            "<script>" ++
            "async function f(a){await fetch('/api/'+a);u()}" ++
            "async function u(){try{const r=await fetch('/api/status');const d=await r.json();document.getElementById('c').textContent=d.current;document.getElementById('t').textContent=d.total}catch(e){}}" ++
            "function gt(){const s=document.getElementById('g').value;if(s>0)f('goto/'+s)}" ++
            "document.addEventListener('keydown',e=>{if(e.key==='ArrowRight'||e.key===' ')f('next');else if(e.key==='ArrowLeft')f('prev')})" ++
            "u();setInterval(u,2000)" ++
            "</script>\n" ++
            "</body>\n" ++
            "</html>";

        const response = try std.fmt.allocPrint(
            self.allocator,
            "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n{s}",
            .{ html.len, html },
        );
        defer self.allocator.free(response);
        _ = try conn.stream.write(response);
    }

    /// Send current status as JSON
    fn sendStatus(self: *Self, conn: net.Server.Connection) !void {
        self.mutex.lock();
        const nav = self.navigation;
        self.mutex.unlock();

        if (nav) |n| {
            const json = try std.fmt.allocPrint(
                self.allocator,
                "{{\"current\":{d},\"total\":{d},\"has_next\":{s},\"has_prev\":{s}}}",
                .{
                    n.current_slide + 1,
                    n.total_slides,
                    if (n.current_slide < n.total_slides - 1) "true" else "false",
                    if (n.current_slide > 0) "true" else "false",
                },
            );
            defer self.allocator.free(json);

            const response = try std.fmt.allocPrint(
                self.allocator,
                "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n{s}",
                .{ json.len, json },
            );
            defer self.allocator.free(response);
            _ = try conn.stream.write(response);
        } else {
            try self.sendError(conn, 503, "No presentation loaded");
        }
    }

    /// Handle next slide command
    fn handleNext(self: *Self, conn: net.Server.Connection) !void {
        self.mutex.lock();
        const nav = self.navigation;
        self.mutex.unlock();

        if (nav) |n| {
            n.nextSlide();
            try self.sendJson(conn, "{\"status\":\"ok\"}");
        } else {
            try self.sendError(conn, 503, "No presentation loaded");
        }
    }

    /// Handle previous slide command
    fn handlePrev(self: *Self, conn: net.Server.Connection) !void {
        self.mutex.lock();
        const nav = self.navigation;
        self.mutex.unlock();

        if (nav) |n| {
            n.prevSlide();
            try self.sendJson(conn, "{\"status\":\"ok\"}");
        } else {
            try self.sendError(conn, 503, "No presentation loaded");
        }
    }

    /// Handle first slide command
    fn handleFirst(self: *Self, conn: net.Server.Connection) !void {
        self.mutex.lock();
        const nav = self.navigation;
        self.mutex.unlock();

        if (nav) |n| {
            n.firstSlide();
            try self.sendJson(conn, "{\"status\":\"ok\"}");
        } else {
            try self.sendError(conn, 503, "No presentation loaded");
        }
    }

    /// Handle last slide command
    fn handleLast(self: *Self, conn: net.Server.Connection) !void {
        self.mutex.lock();
        const nav = self.navigation;
        self.mutex.unlock();

        if (nav) |n| {
            n.lastSlide();
            try self.sendJson(conn, "{\"status\":\"ok\"}");
        } else {
            try self.sendError(conn, 503, "No presentation loaded");
        }
    }

    /// Handle goto slide command
    fn handleGoto(self: *Self, conn: net.Server.Connection, slide_str: []const u8) !void {
        const slide_num = std.fmt.parseInt(usize, slide_str, 10) catch {
            try self.sendError(conn, 400, "Invalid slide number");
            return;
        };

        self.mutex.lock();
        const nav = self.navigation;
        self.mutex.unlock();

        if (nav) |n| {
            n.gotoSlide(slide_num);
            try self.sendJson(conn, "{\"status\":\"ok\"}");
        } else {
            try self.sendError(conn, 503, "No presentation loaded");
        }
    }

    /// Send JSON response
    fn sendJson(self: *Self, conn: net.Server.Connection, json: []const u8) !void {
        const response = try std.fmt.allocPrint(
            self.allocator,
            "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n{s}",
            .{ json.len, json },
        );
        defer self.allocator.free(response);
        _ = try conn.stream.write(response);
    }

    /// Send error response
    fn sendError(self: *Self, conn: net.Server.Connection, code: u16, message: []const u8) !void {
        const json = try std.fmt.allocPrint(
            self.allocator,
            "{{\"status\":\"error\",\"message\":\"{s}\"}}",
            .{message},
        );
        defer self.allocator.free(json);

        const status_text = if (code == 400) "Bad Request" else if (code == 404) "Not Found" else if (code == 405) "Method Not Allowed" else "Service Unavailable";
        const response = try std.fmt.allocPrint(
            self.allocator,
            "HTTP/1.1 {d} {s}\r\nContent-Type: application/json\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n{s}",
            .{ code, status_text, json.len, json },
        );
        defer self.allocator.free(response);
        _ = try conn.stream.write(response);
    }

    /// Send 404 response
    fn send404(self: *Self, conn: net.Server.Connection) !void {
        try self.sendError(conn, 404, "Not found");
    }

    /// Send 405 response
    fn send405(self: *Self, conn: net.Server.Connection) !void {
        try self.sendError(conn, 405, "Method not allowed");
    }
};

test "RemoteServer init/deinit" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const server = RemoteServer.init(allocator, 8765);
    try testing.expectEqual(@as(u16, 8765), server.port);
    try testing.expect(!server.running);
}
