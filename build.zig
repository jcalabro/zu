const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zoo_module = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zoo = b.addLibrary(.{
        .name = "zoo",
        .root_module = zoo_module,
    });
    b.installArtifact(zoo);

    const zoo_tests = b.addTest(.{
        .name = "zoo-tests",
        .root_module = zoo_module,
    });
    const run_zoo_tests = b.addRunArtifact(zoo_tests);
    b.installArtifact(zoo_tests);

    const race = b.option(bool, "race", "Build tests with the race detector enabled (default: false)") orelse false;
    zoo_tests.root_module.sanitize_thread = race;

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_zoo_tests.step);

    const docs_dir = b.addInstallDirectory(.{
        .source_dir = zoo.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    const docs_step = b.step("docs", "Generate documentation");
    docs_step.dependOn(&docs_dir.step);
}
