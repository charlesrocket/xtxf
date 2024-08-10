const std = @import("std");

const build_options = @import("build_options");
const exe_path = build_options.exe_path;

fn runner(args: anytype) !std.process.Child.Term {
    const proc = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &args,
    });

    defer std.testing.allocator.free(proc.stdout);
    defer std.testing.allocator.free(proc.stderr);

    return proc.term;
}

test "default" {
    const argv = [_][]const u8{ exe_path, "--time=short", "-s=default", "-c=default" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "color: red" {
    const argv = [_][]const u8{ exe_path, "--time=short", "-c=red" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "color: green" {
    const argv = [_][]const u8{ exe_path, "--time=short", "-c=green" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "color: blue" {
    const argv = [_][]const u8{ exe_path, "--time=short", "-c=blue" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "color: yellow" {
    const argv = [_][]const u8{ exe_path, "--time=short", "-c=yellow" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "color: magenta" {
    const argv = [_][]const u8{ exe_path, "--time=short", "-c=magenta" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "columns" {
    const argv = [_][]const u8{ exe_path, "--time=short", "-s=columns" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "crypto" {
    const argv = [_][]const u8{ exe_path, "--time=short", "-s=crypto" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "grid" {
    const argv = [_][]const u8{ exe_path, "--time=short", "-s=grid" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "blocks" {
    const argv = [_][]const u8{ exe_path, "--time=short", "-s=blocks" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "decimal" {
    const argv = [_][]const u8{ exe_path, "--time=short", "--decimal" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "version" {
    const argv = [_][]const u8{ exe_path, "-v" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}
