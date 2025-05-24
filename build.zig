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
    exe.addCSourceFile(.{ .file = b.path("src/termbox.c") });
    exe.linkLibC();
    exe.root_module.addImport("cova", cova_mod);
    exe.root_module.addOptions("build_options", build_options);

    build_options.addOption([]const u8, "version", version(b));
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
    unit_tests.addCSourceFile(.{ .file = b.path("src/termbox.c") });
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

    const merge_step = b.addSystemCommand(&.{ "kcov", "--merge" });
    merge_step.addDirectoryArg(b.path("coverage"));
    merge_step.addDirectoryArg(b.path("kcov-unit"));
    merge_step.addDirectoryArg(b.path("kcov-int"));

    const kcov_unit = b.addSystemCommand(&.{ "kcov", "--include-path=src" });
    kcov_unit.addDirectoryArg(b.path("kcov-unit"));
    kcov_unit.addArtifactArg(unit_tests);
    merge_step.step.dependOn(&kcov_unit.step);

    const kcov_int = b.addSystemCommand(&.{ "kcov", "--include-path=src" });
    kcov_int.addDirectoryArg(b.path("kcov-int"));
    kcov_int.addArtifactArg(integration_tests);
    merge_step.step.dependOn(&kcov_int.step);

    const coverage_step = b.step("coverage", "Generate test coverage (kcov)");
    coverage_step.dependOn(&merge_step.step);

    const clean_step = b.step("clean", "Clean up project directory");
    clean_step.dependOn(&b.addRemoveDirTree(b.path("zig-out")).step);
    clean_step.dependOn(&b.addRemoveDirTree(b.path(".zig-cache")).step);
}

fn version(b: *std.Build) []const u8 {
    const semver = manifest.version;
    var gxt = Ghext.init(std.heap.page_allocator) catch return semver;
    const hash = gxt.hash_short(Worktree.Checked);
    return b.fmt("{s} {s}", .{ semver, hash });
}

const manifest: struct {
    const Dependency = struct {
        url: []const u8,
        hash: []const u8,
        lazy: bool = false,
    };

    name: enum { xtxf },
    version: []const u8,
    fingerprint: u64,
    paths: []const []const u8,
    minimum_zig_version: []const u8,
    dependencies: struct {
        termbox2: Dependency,
        cova: Dependency,
        ghext: Dependency,
    },
} = @import("build.zig.zon");

const std = @import("std");
const builtin = @import("builtin");
const Ghext = @import("ghext").Ghext;
const Worktree = Ghext.Worktree;
