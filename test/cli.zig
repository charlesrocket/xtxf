const Proc = struct {
    term: std.process.Child.Term,
    out: []u8,
    err: []u8,
};

fn runner(args: []const []const u8) !Proc {
    const io = testing.io;
    var proc = try std.process.spawn(io, .{
        .argv = args,
        .stdout = .pipe,
        .stderr = .pipe,
    });

    var stdout_buf: [13312]u8 = undefined;
    var stderr_buf: [13312]u8 = undefined;

    var stdout_reader = proc.stdout.?.reader(io, &stdout_buf);
    var stderr_reader = proc.stderr.?.reader(io, &stderr_buf);

    var stdout: std.ArrayListUnmanaged(u8) = .empty;
    var stderr: std.ArrayListUnmanaged(u8) = .empty;

    try stdout_reader.interface.appendRemaining(allocator, &stdout, .unlimited);
    try stderr_reader.interface.appendRemaining(allocator, &stderr, .unlimited);

    const term = try proc.wait(io);

    return Proc{
        .term = term,
        .out = try stdout.toOwnedSlice(allocator),
        .err = try stderr.toOwnedSlice(allocator),
    };
}

test "default" {
    const argv = [4][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-s=default",
        "-c=default",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.default);
    try std.testing.expectEqual(proc.term.exited, 0);
}

test "accents" {
    const argv = [4][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-s=default",
        "--accents=bold,dim,bright,pulse",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.accents);
    try std.testing.expectEqual(proc.term.exited, 0);
}

test "speed" {
    const argv = [4][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-s=default",
        "--speed=slow",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.default);
    try std.testing.expectEqual(proc.term.exited, 0);
}

test "mode: decimal" {
    const argv = [4][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-m=decimal",
        "-s=default",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.decimal);
    try std.testing.expectEqual(proc.term.exited, 0);
}

test "mode: hexadecimal" {
    const argv = [_][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-m=hexadecimal",
        "-s=default",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.hexadecimal);
    try std.testing.expectEqual(proc.term.exited, 0);
}

test "mode: textual" {
    const argv = [4][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-m=textual",
        "-s=default",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.textual);
    try std.testing.expectEqual(proc.term.exited, 0);
}

test "color: red" {
    const argv = [4][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-c=red",
        "-s=default",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.red);
    try std.testing.expectEqual(proc.term.exited, 0);
}

test "color: green" {
    const argv = [4][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-c=green",
        "-s=default",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.green);
    try std.testing.expectEqual(proc.term.exited, 0);
}

test "color: blue" {
    const argv = [4][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-c=blue",
        "-s=default",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.blue);
    try std.testing.expectEqual(proc.term.exited, 0);
}

test "color: yellow" {
    const argv = [4][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-c=yellow",
        "-s=default",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.yellow);
    try std.testing.expectEqual(proc.term.exited, 0);
}

test "color: magenta" {
    const argv = [4][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-c=magenta",
        "-s=default",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.magenta);
    try std.testing.expectEqual(proc.term.exited, 0);
}

test "style: columns" {
    const argv = [4][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-s=columns",
        "-m=decimal",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.columns);
    try std.testing.expectEqual(proc.term.exited, 0);
}

test "style: crypto" {
    const argv = [4][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-s=crypto",
        "-m=hexadecimal",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.crypto);
    try std.testing.expectEqual(proc.term.exited, 0);
}

test "style: grid" {
    const argv = [4][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-s=grid",
        "-m=binary",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.grid);
    try std.testing.expectEqual(proc.term.exited, 0);
}

test "style: blocks" {
    const argv = [4][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-s=blocks",
        "-m=decimal",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.blocks);
    try std.testing.expectEqual(proc.term.exited, 0);
}

test "style: rain" {
    const argv = [4][]const u8{
        exe_path,
        if (live) "--time=1" else "--debug",
        "-s=rain",
        "-m=textual",
    };

    const proc = try runner(&argv);
    defer {
        allocator.free(proc.out);
        allocator.free(proc.err);
    }

    if (!live) try std.testing.expectStringEndsWith(proc.err, streams.rain);
    try std.testing.expectEqual(proc.term.exited, 0);
}

const std = @import("std");
const testing = std.testing;
const streams = @import("streams.zig");
const allocator = std.testing.allocator;

const build_options = @import("build_options");
const exe_path = build_options.exe_path;
const live = build_options.test_live;
