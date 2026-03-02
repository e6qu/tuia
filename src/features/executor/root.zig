//! Code execution module for running code blocks in presentations
const std = @import("std");

pub const CodeExecutor = @import("CodeExecutor.zig").CodeExecutor;
pub const ExecutionResult = @import("CodeExecutor.zig").ExecutionResult;
pub const ExecutionConfig = @import("CodeExecutor.zig").ExecutionConfig;

pub const Language = @import("LanguageRunner.zig").Language;
pub const Runner = @import("LanguageRunner.zig").Runner;
pub const getAvailableLanguages = @import("LanguageRunner.zig").getAvailableLanguages;

pub const OutputCapture = @import("OutputCapture.zig").OutputCapture;
pub const OutputLine = @import("OutputCapture.zig").OutputLine;
pub const StreamType = @import("OutputCapture.zig").StreamType;
pub const ExecutionOutputWidget = @import("OutputCapture.zig").ExecutionOutputWidget;

pub const Sandbox = @import("Sandbox.zig").Sandbox;
pub const SandboxConfig = @import("Sandbox.zig").SandboxConfig;
pub const SecurityLevel = @import("Sandbox.zig").SecurityLevel;
pub const SecurityWarning = @import("Sandbox.zig").SecurityWarning;
pub const checkSecurity = @import("Sandbox.zig").checkSecurity;
pub const ResourceLimits = @import("Sandbox.zig").ResourceLimits;

/// Executor registry for managing multiple executors
pub const ExecutorRegistry = struct {
    allocator: std.mem.Allocator,
    executor: CodeExecutor,
    last_result: ?ExecutionResult,
    last_language: ?Language,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, config: ExecutionConfig) Self {
        return .{
            .allocator = allocator,
            .executor = CodeExecutor.init(allocator, config),
            .last_result = null,
            .last_language = null,
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.last_result) |*result| {
            result.deinit(self.allocator);
        }
    }

    /// Execute code and store result
    pub fn execute(self: *Self, code: []const u8, language: Language) !void {
        // Clean up previous result
        if (self.last_result) |*result| {
            result.deinit(self.allocator);
            self.last_result = null;
        }

        const result = try self.executor.execute(code, language);
        self.last_result = result;
        self.last_language = language;
    }

    /// Check if a language is available
    pub fn isLanguageAvailable(_: Self, language: Language) bool {
        const runner = Runner.forLanguage(language);
        return runner.isAvailable();
    }

    /// Get list of available languages
    pub fn listAvailableLanguages(self: Self) ![]Language {
        return try getAvailableLanguages(self.allocator);
    }

    /// Get last execution result
    pub fn getLastResult(self: Self) ?ExecutionResult {
        return self.last_result;
    }

    /// Get last execution language
    pub fn getLastLanguage(self: Self) ?Language {
        return self.last_language;
    }

    /// Clear last result
    pub fn clearResult(self: *Self) void {
        if (self.last_result) |*result| {
            result.deinit(self.allocator);
            self.last_result = null;
        }
    }
};
