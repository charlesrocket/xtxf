const std = @import("std");
const Ghext = @import("ghext").Ghext;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const build_options = b.addOptions();

    const exe = b.addExecutable(.{
        .name = "xtxf",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const cova_dep = b.dependency("cova", .{
        .target = target,
        .optimize = optimize,
    });

    const cova_mod = cova_dep.module("cova");

    if (target.query.cpu_arch == null) {
        const cova_gen = @import("cova").addCovaDocGenStep(b, cova_dep, exe, .{
            .kinds = &.{.all},
        });

        const meta_doc_gen = b.step("gen-doc", "Generate Meta Docs");
        meta_doc_gen.dependOn(&cova_gen.step);
    }

    exe.addIncludePath(b.dependency("termbox2", .{}).path("."));
    exe.addCSourceFile(.{ .file = b.path("src/termbox_impl.c") });
    exe.linkLibC();
    exe.root_module.addImport("cova", cova_mod);
    exe.root_module.addOptions("build_options", build_options);

    build_options.addOption(Ghext, "gxt", try read_repo());
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
    const test_live = b.option(bool, "test_live", "Live integration tests") orelse false;
    test_options.addOption(bool, "test_live", test_live);
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

inline fn read_repo() !Ghext {
    const gxt = Ghext.read(std.heap.page_allocator) catch unreachable;
    return gxt;
}
