//! Code execution engine for running code blocks
const std = @import("std");
const Language = @import("LanguageRunner.zig").Language;
const Runner = @import("LanguageRunner.zig").Runner;

/// Result of code execution
pub const ExecutionResult = struct {
    /// Exit code (0 = success)
    exit_code: u32,
    /// stdout output
    stdout: []const u8,
    /// stderr output
    stderr: []const u8,
    /// Execution time in milliseconds
    execution_time_ms: u64,
    /// Whether execution was killed (timeout)
    killed: bool = false,

    const Self = @This();

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        allocator.free(self.stdout);
        allocator.free(self.stderr);
    }

    /// Check if execution succeeded
    pub fn success(self: Self) bool {
        return self.exit_code == 0 and !self.killed;
    }
};

/// Code execution configuration
pub const ExecutionConfig = struct {
    /// Maximum execution time in seconds (0 = unlimited)
    timeout_seconds: u32 = 30,
    /// Maximum output size in bytes
    max_output_size: usize = 1024 * 1024, // 1MB
    /// Whether to capture stdout
    capture_stdout: bool = true,
    /// Whether to capture stderr
    capture_stderr: bool = true,
    /// Working directory for execution
    working_dir: ?[]const u8 = null,
    /// Environment variables
    env_vars: ?[]const [2][]const u8 = null,
};

/// CodeExecutor manages code execution
pub const CodeExecutor = struct {
    allocator: std.mem.Allocator,
    config: ExecutionConfig,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, config: ExecutionConfig) Self {
        return .{
            .allocator = allocator,
            .config = config,
        };
    }

    /// Execute code in a specific language
    pub fn execute(
        self: Self,
        code: []const u8,
        language: Language,
    ) !ExecutionResult {
        const runner = Runner.forLanguage(language);

        // Check if language is available
        if (!runner.isAvailable()) {
            return error.LanguageNotAvailable;
        }

        // Create temporary file for code
        const temp_file = try self.createTempFile(code, runner.fileExtension());
        defer {
            std.fs.cwd().deleteFile(temp_file) catch {};
            self.allocator.free(temp_file);
        }

        // Build command
        const cmd = try runner.buildCommand(self.allocator, temp_file);
        defer {
            for (cmd) |arg| {
                self.allocator.free(arg);
            }
            self.allocator.free(cmd);
        }

        // Execute with timeout
        return try self.runWithTimeout(cmd);
    }

    /// Create a temporary file with code
    fn createTempFile(self: Self, code: []const u8, extension: []const u8) ![:0]const u8 {
        // Use current directory as temp directory
        const file_name_slice = try std.fmt.allocPrint(self.allocator, ".tuia_{d}.{s}", .{
            @as(i64, @intCast(std.time.milliTimestamp())),
            extension,
        });
        errdefer self.allocator.free(file_name_slice);

        const file = try std.fs.cwd().createFile(file_name_slice, .{});
        defer file.close();

        try file.writeAll(code);

        // Convert to null-terminated
        const file_name = try self.allocator.dupeZ(u8, file_name_slice);
        self.allocator.free(file_name_slice);
        return file_name;
    }

    /// Run command with timeout (POSIX only)
    fn runWithTimeout(self: Self, cmd: []const [:0]const u8) !ExecutionResult {
        if (@import("builtin").os.tag == .windows) {
            return error.NotSupported;
        }
        const start_time = std.time.milliTimestamp();

        // Create pipes for stdout/stderr
        const stdout_pipe = try std.posix.pipe();
        const stderr_pipe = try std.posix.pipe();

        errdefer {
            std.posix.close(stdout_pipe[0]);
            std.posix.close(stdout_pipe[1]);
            std.posix.close(stderr_pipe[0]);
            std.posix.close(stderr_pipe[1]);
        }

        // Fork and execute
        const pid = try std.posix.fork();

        if (pid == 0) {
            // Child process
            std.posix.close(stdout_pipe[0]);
            std.posix.close(stderr_pipe[0]);

            // Redirect stdout/stderr
            try std.posix.dup2(stdout_pipe[1], std.posix.STDOUT_FILENO);
            try std.posix.dup2(stderr_pipe[1], std.posix.STDERR_FILENO);

            std.posix.close(stdout_pipe[1]);
            std.posix.close(stderr_pipe[1]);

            // Execute command - cmd items are already null-terminated from dupe
            const argv = try self.allocator.allocSentinel(?[*:0]const u8, cmd.len, null);
            defer self.allocator.free(argv);

            for (cmd, 0..) |arg, i| {
                argv[i] = @ptrCast(arg.ptr);
            }

            const envp: [*:null]const ?[*:0]const u8 = @ptrCast(@alignCast(std.c.environ));
            std.posix.execvpeZ(argv[0].?, argv.ptr, envp) catch {};
            std.process.exit(127);
        }

        // Parent process
        std.posix.close(stdout_pipe[1]);
        std.posix.close(stderr_pipe[1]);

        // Read output with timeout
        var stdout_buf: std.ArrayList(u8) = .empty;
        var stderr_buf: std.ArrayList(u8) = .empty;
        defer stdout_buf.deinit(self.allocator);
        defer stderr_buf.deinit(self.allocator);

        var killed = false;
        var exit_code: u32 = 0;

        if (self.config.timeout_seconds > 0) {
            // Use poll with timeout
            const timeout_ms = self.config.timeout_seconds * 1000;
            var elapsed: u64 = 0;
            const poll_interval: u64 = 100; // 100ms

            var poll_fds = [_]std.posix.pollfd{
                .{ .fd = stdout_pipe[0], .events = std.posix.POLL.IN, .revents = 0 },
                .{ .fd = stderr_pipe[0], .events = std.posix.POLL.IN, .revents = 0 },
            };

            while (elapsed < timeout_ms) {
                const ready = std.posix.poll(&poll_fds, @intCast(poll_interval)) catch 0;

                if (ready > 0) {
                    if (poll_fds[0].revents & std.posix.POLL.IN != 0) {
                        const buf = try self.allocator.alloc(u8, 4096);
                        defer self.allocator.free(buf);
                        const n = std.posix.read(stdout_pipe[0], buf) catch 0;
                        if (n > 0) {
                            try stdout_buf.appendSlice(self.allocator, buf[0..n]);
                        }
                    }

                    if (poll_fds[1].revents & std.posix.POLL.IN != 0) {
                        const buf = try self.allocator.alloc(u8, 4096);
                        defer self.allocator.free(buf);
                        const n = std.posix.read(stderr_pipe[0], buf) catch 0;
                        if (n > 0) {
                            try stderr_buf.appendSlice(self.allocator, buf[0..n]);
                        }
                    }
                }

                // Check if child exited
                const wait_result = std.posix.waitpid(pid, std.posix.W.NOHANG);
                if (wait_result.status != 0) {
                    exit_code = wait_result.status;
                    break;
                }

                elapsed += poll_interval;
            }

            if (elapsed >= timeout_ms and exit_code == -1) {
                // Kill the process
                std.posix.kill(pid, std.posix.SIG.TERM) catch {};
                std.Thread.sleep(100 * std.time.ns_per_ms);
                std.posix.kill(pid, std.posix.SIG.KILL) catch {};
                killed = true;

                // Wait for child
                _ = std.posix.waitpid(pid, 0);
            }
        } else {
            // No timeout - just wait
            const wait_result = std.posix.waitpid(pid, 0);
            exit_code = wait_result.status;

            // Read remaining output
            var buf: [4096]u8 = undefined;
            while (true) {
                const n = std.posix.read(stdout_pipe[0], &buf) catch break;
                if (n == 0) break;
                try stdout_buf.appendSlice(self.allocator, buf[0..n]);
            }
            while (true) {
                const n = std.posix.read(stderr_pipe[0], &buf) catch break;
                if (n == 0) break;
                try stderr_buf.appendSlice(self.allocator, buf[0..n]);
            }
        }

        std.posix.close(stdout_pipe[0]);
        std.posix.close(stderr_pipe[0]);

        const end_time = std.time.milliTimestamp();

        return ExecutionResult{
            .exit_code = exit_code,
            .stdout = try stdout_buf.toOwnedSlice(self.allocator),
            .stderr = try stderr_buf.toOwnedSlice(self.allocator),
            .execution_time_ms = @intCast(end_time - start_time),
            .killed = killed,
        };
    }
};

/// Error types for code execution
pub const ExecutionError = error{
    LanguageNotAvailable,
    Timeout,
    ProcessSpawnFailed,
    OutOfMemory,
};

test "CodeExecutor language detection" {
    const testing = std.testing;

    // Test language detection
    try testing.expect(Language.fromString("bash") != null);
    try testing.expect(Language.fromString("python") != null);
    try testing.expect(Language.fromString("zig") != null);
    try testing.expect(Language.fromString("unknown") == null);
}

test "CodeExecutor configuration" {
    const testing = std.testing;

    // Test configuration defaults
    const config: ExecutionConfig = .{};
    try testing.expectEqual(@as(u32, 30), config.timeout_seconds);
    try testing.expect(config.capture_stdout);
    try testing.expect(config.capture_stderr);
}

test "CodeExecutor execution result" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Test ExecutionResult structure
    const result = ExecutionResult{
        .exit_code = 0,
        .stdout = try allocator.dupe(u8, "hello"),
        .stderr = try allocator.dupe(u8, ""),
        .execution_time_ms = 100,
        .killed = false,
    };
    defer result.deinit(allocator);

    try testing.expect(result.success());
    try testing.expectEqualStrings("hello", result.stdout);
}
