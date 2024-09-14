const std = @import("std");

const build_options = @import("build_options");
const exe_path = build_options.exe_path;
const live = build_options.test_live;

const Proc = struct {
    term: std.process.Child.Term,
    out: []u8,
    err: []u8,
};

fn runner(args: [4][]const u8) !Proc {
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

    const out = try stdout.toOwnedSlice();
    const err = try stderr.toOwnedSlice();

    defer {
        std.testing.allocator.free(out);
        std.testing.allocator.free(err);
    }

    return Proc{ .term = term, .out = out, .err = err };
}

test "default" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=default", "-c=default" };
    const proc = try runner(argv);

    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "speed" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=default", "--speed=slow" };
    const proc = try runner(argv);

    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "mode: decimal" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-m=decimal", "-s=default" };
    const proc = try runner(argv);

    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "mode: hexadecimal" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-m=hexadecimal", "-s=default" };
    const proc = try runner(argv);

    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "mode: textual" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-m=textual", "-s=default" };
    const proc = try runner(argv);

    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "color: red" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-c=red", "-s=default" };
    const proc = try runner(argv);

    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "color: green" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-c=green", "-s=default" };
    const proc = try runner(argv);

    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "color: blue" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-c=blue", "-s=default" };
    const proc = try runner(argv);

    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "color: yellow" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-c=yellow", "-s=default" };
    const proc = try runner(argv);

    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "color: magenta" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-c=magenta", "-s=default" };
    const proc = try runner(argv);

    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "style: columns" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=columns", "-m=decimal" };
    const proc = try runner(argv);

    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "style: crypto" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=crypto", "-m=hexadecimal" };
    const proc = try runner(argv);

    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "style: grid" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=grid", "-m=binary" };
    const proc = try runner(argv);

    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "style: blocks" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=blocks", "-m=decimal" };
    const proc = try runner(argv);

    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "style: rain" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=rain", "-m=textual" };
    const proc = try runner(argv);

    try std.testing.expectEqual(proc.term.Exited, 0);
}
