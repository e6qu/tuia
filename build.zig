const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create library module (for tests and imports)
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Main executable - uses main.zig directly
    const exe_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    // Add slidz module to executable so it can import other modules
    exe_module.addImport("slidz", root_module);

    const exe = b.addExecutable(.{
        .name = "slidz",
        .root_module = exe_module,
    });
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
    integration_module.addImport("slidz", root_module);

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
}
