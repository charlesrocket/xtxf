const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "xtxf",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.addIncludePath(b.dependency("termbox2", .{}).path("."));
    exe.addCSourceFile(.{ .file = b.path("src/termbox_impl.c") });
    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .name = "unit",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    unit_tests.addIncludePath(b.dependency("termbox2", .{}).path("."));
    unit_tests.addCSourceFile(.{ .file = b.path("src/termbox_impl.c") });
    unit_tests.linkLibC();

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&b.addRunArtifact(unit_tests).step);

    const test_options = b.addOptions();
    test_options.addOptionPath("exe_path", exe.getEmittedBin());

    const integration_tests = b.addTest(.{
        .root_source_file = b.path("tests/cli.zig"),
        .target = target,
        .optimize = optimize,
    });

    integration_tests.root_module.addOptions("build_options", test_options);

    test_step.dependOn(&b.addRunArtifact(integration_tests).step);

    const coverage_step = b.step("coverage", "Generate test coverage (kcov)");
    const merge_step = std.Build.Step.Run.create(b, "merge coverage");
    merge_step.addArgs(&.{ "kcov", "--merge" });
    merge_step.rename_step_with_output_arg = false;
    const merged_coverage_output = merge_step.addOutputFileArg(".");

    {
        const kcov_collect = std.Build.Step.Run.create(b, "collect coverage");
        kcov_collect.addArgs(&.{ "kcov", "--collect-only" });
        kcov_collect.addPrefixedDirectoryArg("--include-pattern=", b.path("src"));
        merge_step.addDirectoryArg(kcov_collect.addOutputFileArg(unit_tests.name));
        kcov_collect.addArtifactArg(unit_tests);
        kcov_collect.enableTestRunnerMode();
    }

    {
        const kcov_collect = std.Build.Step.Run.create(b, "collect coverage");
        kcov_collect.addArgs(&.{ "kcov", "--collect-only" });
        kcov_collect.addPrefixedDirectoryArg("--include-pattern=", b.path("src"));
        merge_step.addDirectoryArg(kcov_collect.addOutputFileArg(integration_tests.name));
        kcov_collect.addArtifactArg(integration_tests);
        kcov_collect.enableTestRunnerMode();
    }

    const install_coverage = b.addInstallDirectory(.{
        .source_dir = merged_coverage_output,
        .install_dir = .{ .custom = "coverage" },
        .install_subdir = "",
    });

    coverage_step.dependOn(&install_coverage.step);
}
