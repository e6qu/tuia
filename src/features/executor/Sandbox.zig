//! Sandbox for secure code execution
const std = @import("std");

/// Security level for sandboxing
pub const SecurityLevel = enum {
    /// No sandboxing - direct execution
    none,
    /// Basic restrictions - timeout, working directory
    basic,
    /// Restricted - limits resources, network disabled
    restricted,
    /// Maximum security - container-like isolation (not implemented)
    maximum,
};

/// Sandbox configuration
pub const SandboxConfig = struct {
    /// Security level
    level: SecurityLevel = .basic,
    /// Working directory for execution
    working_dir: ?[]const u8 = null,
    /// Maximum execution time in seconds
    timeout_seconds: u32 = 30,
    /// Maximum memory in MB (0 = unlimited)
    max_memory_mb: u32 = 0,
    /// Disable network access
    disable_network: bool = true,
    /// Read-only paths
    read_only_paths: []const []const u8 = &.{},
    /// Environment variables to clear
    clear_env_vars: []const []const u8 = &.{},
    /// Environment variables to set
    env_vars: []const [2][]const u8 = &.{},
};

/// Sandbox context for code execution
pub const Sandbox = struct {
    allocator: std.mem.Allocator,
    config: SandboxConfig,
    temp_dir: ?[]const u8,

    const Self = @This();

    /// Initialize sandbox with configuration
    pub fn init(allocator: std.mem.Allocator, config: SandboxConfig) !Self {
        var self = Self{
            .allocator = allocator,
            .config = config,
            .temp_dir = null,
        };

        // Create temporary directory for execution
        if (config.working_dir == null) {
            self.temp_dir = try self.createTempDir();
        }

        return self;
    }

    /// Clean up sandbox
    pub fn deinit(self: *Self) void {
        if (self.temp_dir) |dir| {
            std.fs.cwd().deleteTree(dir) catch {};
            self.allocator.free(dir);
        }
    }

    /// Get working directory for execution
    pub fn getWorkingDir(self: Self) []const u8 {
        return self.config.working_dir orelse self.temp_dir.?;
    }

    /// Create a temporary directory for sandboxed execution
    fn createTempDir(self: Self) ![]const u8 {
        const timestamp = @as(i64, @intCast(std.time.milliTimestamp()));
        const random = std.crypto.random.int(u32);
        const dir_name = try std.fmt.allocPrint(
            self.allocator,
            ".tuia_sandbox_{d}_{d}",
            .{ timestamp, random },
        );

        try std.fs.cwd().makeDir(dir_name);
        return dir_name;
    }

    /// Prepare environment variables for sandboxed execution
    pub fn prepareEnvironment(
        self: Self,
        allocator: std.mem.Allocator,
    ) ![]const [2][]const u8 {
        var env_list = std.ArrayList([2][]const u8).init(allocator);
        defer env_list.deinit();

        // Copy existing env vars, excluding cleared ones
        const environ = std.c.environ;
        var i: usize = 0;
        while (environ[i] != null) : (i += 1) {
            const env_str = std.mem.span(environ[i].?);
            if (parseEnvVar(env_str)) |pair| {
                if (!self.shouldClearVar(pair[0])) {
                    try env_list.append(pair);
                }
            }
        }

        // Set custom environment variables
        for (self.config.env_vars) |pair| {
            // Remove existing var if present
            for (env_list.items, 0..) |item, idx| {
                if (std.mem.eql(u8, item[0], pair[0])) {
                    _ = env_list.orderedRemove(idx);
                    break;
                }
            }
            try env_list.append(pair);
        }

        // Add sandbox indicator
        try env_list.append(.{ "TUIA_SANDBOX", "1" });
        try env_list.append(.{ "TUIA_SANDBOX_LEVEL", @tagName(self.config.level) });

        return env_list.toOwnedSlice();
    }

    /// Check if an environment variable should be cleared
    fn shouldClearVar(self: Self, name: []const u8) bool {
        for (self.config.clear_env_vars) |pattern| {
            if (std.mem.eql(u8, name, pattern)) {
                return true;
            }
        }

        // Always clear sensitive vars in restricted mode
        if (self.config.level == .restricted) {
            const sensitive = [_][]const u8{
                "SSH_AUTH_SOCK",
                "SSH_AGENT_LAUNCHER",
                "GNOME_KEYRING_CONTROL",
                "AWS_ACCESS_KEY_ID",
                "AWS_SECRET_ACCESS_KEY",
                "GITHUB_TOKEN",
            };
            for (sensitive) |s| {
                if (std.mem.eql(u8, name, s)) return true;
            }
        }

        return false;
    }

    /// Parse environment variable string (KEY=VALUE)
    fn parseEnvVar(env_str: []const u8) ?[2][]const u8 {
        const idx = std.mem.indexOfScalar(u8, env_str, '=') orelse return null;
        return .{ env_str[0..idx], env_str[idx + 1 ..] };
    }

    /// Get resource limits for sandboxed process
    /// Returns rlimit values that should be applied (Linux only)
    pub fn getResourceLimits(self: Self) ResourceLimits {
        return .{
            .max_memory_bytes = if (self.config.max_memory_mb > 0)
                self.config.max_memory_mb * 1024 * 1024
            else
                0,
            .max_cpu_seconds = self.config.timeout_seconds,
        };
    }

    /// Check if code should be allowed to execute based on security policy
    pub fn checkCode(self: Self, code: []const u8) ?[]const u8 {
        if (self.config.level == .none) return null;

        // Check for dangerous patterns
        const dangerous_patterns = [_][]const u8{
            "rm -rf /",
            ":(){ :|:& };:", // Fork bomb
            "dd if=/dev/zero",
            "mkfs.",
            "> /dev/sda",
            "chmod 777 /",
        };

        for (dangerous_patterns) |pattern| {
            if (std.mem.indexOf(u8, code, pattern) != null) {
                return "Code contains potentially dangerous patterns";
            }
        }

        return null;
    }

    /// Apply sandbox restrictions to current process (call after fork, before exec)
    /// This is called in the child process
    pub fn applyRestrictions(self: Self) !void {
        if (self.config.level == .none) return;

        // Change to working directory
        const work_dir = self.getWorkingDir();
        try std.posix.chdir(work_dir);

        // Set resource limits (Linux only)
        if (@import("builtin").os.tag == .linux) {
            const limits = self.getResourceLimits();

            // Set memory limit
            if (limits.max_memory_bytes > 0) {
                const rlimit = std.posix.rlimit{
                    .cur = limits.max_memory_bytes,
                    .max = limits.max_memory_bytes,
                };
                std.posix.setrlimit(std.posix.rlimit_resource.AS, rlimit) catch {};
            }

            // Set CPU time limit
            if (limits.max_cpu_seconds > 0) {
                const rlimit = std.posix.rlimit{
                    .cur = limits.max_cpu_seconds,
                    .max = limits.max_cpu_seconds,
                };
                std.posix.setrlimit(std.posix.rlimit_resource.CPU, rlimit) catch {};
            }
        }

        // TODO: Implement network namespace isolation for disable_network
        // This requires Linux namespaces which is complex
    }
};

/// Resource limits for sandboxed processes
pub const ResourceLimits = struct {
    max_memory_bytes: usize,
    max_cpu_seconds: u32,
};

/// Security warning for code execution
pub const SecurityWarning = struct {
    /// Warning message
    message: []const u8,
    /// Whether execution should require confirmation
    requires_confirmation: bool,
    /// Risk level
    level: WarningLevel,

    pub const WarningLevel = enum {
        info,
        warning,
        critical,
    };
};

/// Check code for security issues and return warnings
pub fn checkSecurity(code: []const u8) ?SecurityWarning {
    // Check for file system operations
    const fs_patterns = [_][]const u8{
        "rm ", "mv ", "cp ", "dd ", "> ", ">>",
    };

    for (fs_patterns) |pattern| {
        if (std.mem.indexOf(u8, code, pattern) != null) {
            return .{
                .message = "Code contains file system operations",
                .requires_confirmation = true,
                .level = .warning,
            };
        }
    }

    // Check for network operations
    const network_patterns = [_][]const u8{
        "curl ", "wget ", "http", "socket", "fetch(",
    };

    for (network_patterns) |pattern| {
        if (std.mem.indexOf(u8, code, pattern) != null) {
            return .{
                .message = "Code contains network operations",
                .requires_confirmation = true,
                .level = .warning,
            };
        }
    }

    return null;
}

test "Sandbox basic functionality" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var sandbox = try Sandbox.init(allocator, .{
        .level = .basic,
        .timeout_seconds = 10,
    });
    defer sandbox.deinit();

    // Check temp directory was created
    try testing.expect(sandbox.temp_dir != null);

    // Check working directory
    const work_dir = sandbox.getWorkingDir();
    try testing.expect(work_dir.len > 0);
}

test "Sandbox security checks" {
    const testing = std.testing;

    // Test dangerous code detection
    try testing.expect(Sandbox.checkCode(.{ .level = .basic }, "rm -rf /") != null);
    try testing.expect(Sandbox.checkCode(.{ .level = .basic }, "echo hello") == null);

    // Test security warning
    const warning = checkSecurity("rm -rf /tmp/test");
    try testing.expect(warning != null);
    try testing.expectEqual(SecurityWarning.WarningLevel.warning, warning.?.level);
}

test "Sandbox environment preparation" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var sandbox = try Sandbox.init(allocator, .{
        .level = .restricted,
        .env_vars = &.{.{ "TEST_VAR", "test_value" }},
        .clear_env_vars = &.{"CLEAR_ME"},
    });
    defer sandbox.deinit();

    const env = try sandbox.prepareEnvironment(allocator);
    defer allocator.free(env);

    // Check sandbox indicator is set
    var found_sandbox = false;
    var found_test_var = false;
    for (env) |pair| {
        if (std.mem.eql(u8, pair[0], "TUIA_SANDBOX")) {
            found_sandbox = true;
        }
        if (std.mem.eql(u8, pair[0], "TEST_VAR")) {
            found_test_var = true;
            try testing.expectEqualStrings("test_value", pair[1]);
        }
    }

    try testing.expect(found_sandbox);
    try testing.expect(found_test_var);
}
