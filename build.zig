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

    const ghext_dep = b.dependency("ghext", .{
        .target = target,
        .optimize = optimize,
    });

    const ghext = ghext_dep.module("ghext");

    exe.addIncludePath(b.dependency("termbox2", .{}).path("."));
    exe.addCSourceFile(.{ .file = b.path("src/termbox_impl.c") });
    exe.linkLibC();
    exe.root_module.addImport("ghext", ghext);

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
        .root_source_file = b.path("test/cli.zig"),
        .target = target,
        .optimize = optimize,
    });

    integration_tests.root_module.addOptions("build_options", test_options);

    test_step.dependOn(&b.addRunArtifact(integration_tests).step);

    const merge_step = b.addSystemCommand(&.{ "kcov", "--merge", "kcov-out", "kcov-test", "kcov-unit" });

    const kcov_int = b.addSystemCommand(&.{ "kcov", "kcov-test", "--include-path=src" });
    kcov_int.addArtifactArg(integration_tests);
    merge_step.step.dependOn(&kcov_int.step);

    const kcov_unit = b.addSystemCommand(&.{ "kcov", "kcov-unit", "--include-path=src" });
    kcov_unit.addArtifactArg(unit_tests);
    merge_step.step.dependOn(&kcov_unit.step);

    const coverage_step = b.step("coverage", "Generate test coverage (kcov)");
    coverage_step.dependOn(&merge_step.step);
}
