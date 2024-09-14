const std = @import("std");

const build_options = @import("build_options");
const exe_path = build_options.exe_path;
const live = build_options.test_live;

fn runner(args: anytype) !std.process.Child.Term {
    var proc = std.process.Child.init(&args, std.testing.allocator);

    proc.stdout_behavior = .Pipe;
    proc.stderr_behavior = .Pipe;

    var stdout = std.ArrayList(u8).init(std.testing.allocator);
    var stderr = std.ArrayList(u8).init(std.testing.allocator);
    defer {
        stdout.deinit();
        stderr.deinit();
    }

    try proc.spawn();
    try proc.collectOutput(&stdout, &stderr, 13312);

    const term = try proc.wait();

    return term;
}

test "default" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=default", "-c=default" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "speed" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=default", "--speed=slow" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "mode: decimal" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-m=decimal" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "mode: hexadecimal" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-m=hexadecimal" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "mode: textual" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-m=textual" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "color: red" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-c=red" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "color: green" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-c=green" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "color: blue" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-c=blue" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "color: yellow" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-c=yellow" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "color: magenta" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-c=magenta" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "style: columns" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=columns" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "style: crypto" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=crypto" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "style: grid" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=grid" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "style: blocks" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=blocks" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "style: rain" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=rain" };
    const term = try runner(argv);

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}
