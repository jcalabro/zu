const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zu_module = b.addModule("zu", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create a test step
    const zu_tests = b.addTest(.{
        .name = "zu",
        .root_module = zu_module,
    });
    const run_zu_tests = b.addRunArtifact(zu_tests);
    b.installArtifact(zu_tests);

    const race = b.option(bool, "race", "Build tests with the race detector enabled (default: false)") orelse false;
    zu_tests.root_module.sanitize_thread = race;

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_zu_tests.step);

    // Create a docs step
    const docs_dir = b.addInstallDirectory(.{
        .source_dir = zu_tests.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    const docs_step = b.step("docs", "Generate documentation");
    docs_step.dependOn(&docs_dir.step);
}
