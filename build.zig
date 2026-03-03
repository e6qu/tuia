const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Get vaxis dependency
    const vaxis_dep = b.dependency("vaxis", .{
        .target = target,
        .optimize = optimize,
    });

    // Create library module (for tests and imports)
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    // Add vaxis for TUI/rendering in library modules
    root_module.addImport("vaxis", vaxis_dep.module("vaxis"));

    // Main executable - uses main.zig directly
    const exe_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    // Add tuia module to executable so it can import other modules
    exe_module.addImport("tuia", root_module);
    // Add vaxis for TUI
    exe_module.addImport("vaxis", vaxis_dep.module("vaxis"));

    const exe = b.addExecutable(.{
        .name = "tuia",
        .root_module = exe_module,
    });
    // Link libc for CodeExecutor (fork, execvp, waitpid, etc.)
    exe.linkLibC();
    b.installArtifact(exe);

    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const test_step = b.step("test", "Run all tests");

    // Main module tests (library tests)
    const main_tests = b.addTest(.{
        .root_module = root_module,
    });
    const run_main_tests = b.addRunArtifact(main_tests);
    test_step.dependOn(&run_main_tests.step);

    // Integration tests
    const integration_module = b.createModule(.{
        .root_source_file = b.path("tests/integration_tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    integration_module.addImport("tuia", root_module);

    const integration_tests = b.addTest(.{
        .root_module = integration_module,
    });
    const run_integration_tests = b.addRunArtifact(integration_tests);
    test_step.dependOn(&run_integration_tests.step);

    // Format check
    const fmt_step = b.step("fmt", "Format all source files");
    const fmt = b.addFmt(.{
        .paths = &.{
            "src",
            "tests",
            "build.zig",
        },
    });
    fmt_step.dependOn(&fmt.step);

    // Verify step (format check + tests)
    const verify_step = b.step("verify", "Run all checks (format + tests)");
    const fmt_check = b.addFmt(.{
        .paths = &.{
            "src",
            "tests",
            "build.zig",
        },
        .check = true,
    });
    verify_step.dependOn(&fmt_check.step);
    verify_step.dependOn(test_step);

    // Documentation
    const docs_step = b.step("docs", "Generate documentation");
    const install_docs = b.addInstallDirectory(.{
        .source_dir = exe.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    docs_step.dependOn(&install_docs.step);

    // Custom linter tool
    const ziglint_module = b.createModule(.{
        .root_source_file = b.path("tools/ziglint.zig"),
        .target = target,
        .optimize = optimize,
    });

    const ziglint_exe = b.addExecutable(.{
        .name = "ziglint",
        .root_module = ziglint_module,
    });
    b.installArtifact(ziglint_exe);

    const ziglint_step = b.step("ziglint", "Build the custom Zig linter");
    ziglint_step.dependOn(b.getInstallStep());

    // Run linter
    const run_ziglint = b.addRunArtifact(ziglint_exe);
    run_ziglint.addArg("src/");
    const lint_check_step = b.step("lint-check", "Run custom linter on source");
    lint_check_step.dependOn(&run_ziglint.step);

    // Fuzz target for parser
    const fuzz_parser_module = b.createModule(.{
        .root_source_file = b.path("fuzz/parser_fuzz.zig"),
        .target = target,
        .optimize = optimize,
    });
    fuzz_parser_module.addImport("tuia", root_module);

    const fuzz_parser_exe = b.addExecutable(.{
        .name = "fuzz-parser",
        .root_module = fuzz_parser_module,
    });

    const fuzz_parser_step = b.step("fuzz-parser", "Build parser fuzz target");
    fuzz_parser_step.dependOn(&b.addInstallArtifact(fuzz_parser_exe).step);

    // Verify step now includes lint check
    verify_step.dependOn(lint_check_step);
}
