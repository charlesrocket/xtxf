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

    return Proc{ .term = term, .out = out, .err = err };
}

test "default" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=default", "-c=default" };
    const proc = try runner(argv);
    defer {
        std.testing.allocator.free(proc.out);
        std.testing.allocator.free(proc.err);
    }

    try std.testing.expectStringEndsWith(proc.err, default_run);
    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "speed" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=default", "--speed=slow" };
    const proc = try runner(argv);
    defer {
        std.testing.allocator.free(proc.out);
        std.testing.allocator.free(proc.err);
    }

    try std.testing.expectStringEndsWith(proc.err, default_run);
    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "mode: decimal" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-m=decimal", "-s=default" };
    const proc = try runner(argv);
    defer {
        std.testing.allocator.free(proc.out);
        std.testing.allocator.free(proc.err);
    }

    try std.testing.expectStringEndsWith(proc.err, decimal_run);
    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "mode: hexadecimal" {
    const argv = [_][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-m=hexadecimal", "-s=default" };
    const proc = try runner(argv);
    defer {
        std.testing.allocator.free(proc.out);
        std.testing.allocator.free(proc.err);
    }

    try std.testing.expectStringEndsWith(proc.err, hexadecimal_run);
    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "mode: textual" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-m=textual", "-s=default" };
    const proc = try runner(argv);
    defer {
        std.testing.allocator.free(proc.out);
        std.testing.allocator.free(proc.err);
    }

    try std.testing.expectStringEndsWith(proc.err, textual_run);
    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "color: red" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-c=red", "-s=default" };
    const proc = try runner(argv);
    defer {
        std.testing.allocator.free(proc.out);
        std.testing.allocator.free(proc.err);
    }

    try std.testing.expectStringEndsWith(proc.err, red_run);
    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "color: green" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-c=green", "-s=default" };
    const proc = try runner(argv);
    defer {
        std.testing.allocator.free(proc.out);
        std.testing.allocator.free(proc.err);
    }

    try std.testing.expectStringEndsWith(proc.err, green_run);
    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "color: blue" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-c=blue", "-s=default" };
    const proc = try runner(argv);
    defer {
        std.testing.allocator.free(proc.out);
        std.testing.allocator.free(proc.err);
    }
    try std.testing.expectStringEndsWith(proc.err, blue_run);
    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "color: yellow" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-c=yellow", "-s=default" };
    const proc = try runner(argv);
    defer {
        std.testing.allocator.free(proc.out);
        std.testing.allocator.free(proc.err);
    }

    try std.testing.expectStringEndsWith(proc.err, yellow_run);
    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "color: magenta" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-c=magenta", "-s=default" };
    const proc = try runner(argv);
    defer {
        std.testing.allocator.free(proc.out);
        std.testing.allocator.free(proc.err);
    }

    try std.testing.expectStringEndsWith(proc.err, magenta_run);
    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "style: columns" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=columns", "-m=decimal" };
    const proc = try runner(argv);
    defer {
        std.testing.allocator.free(proc.out);
        std.testing.allocator.free(proc.err);
    }

    try std.testing.expectStringEndsWith(proc.err, columns_run);
    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "style: crypto" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=crypto", "-m=hexadecimal" };
    const proc = try runner(argv);
    defer {
        std.testing.allocator.free(proc.out);
        std.testing.allocator.free(proc.err);
    }

    try std.testing.expectStringEndsWith(proc.err, crypto_run);
    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "style: grid" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=grid", "-m=binary" };
    const proc = try runner(argv);
    defer {
        std.testing.allocator.free(proc.out);
        std.testing.allocator.free(proc.err);
    }

    try std.testing.expectStringEndsWith(proc.err, grid_run);
    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "style: blocks" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=blocks", "-m=decimal" };
    const proc = try runner(argv);
    defer {
        std.testing.allocator.free(proc.out);
        std.testing.allocator.free(proc.err);
    }

    try std.testing.expectStringEndsWith(proc.err, blocks_run);
    try std.testing.expectEqual(proc.term.Exited, 0);
}

test "style: rain" {
    const argv = [4][]const u8{ exe_path, if (live) "--time=1" else "--debug", "-s=rain", "-m=textual" };
    const proc = try runner(argv);
    defer {
        std.testing.allocator.free(proc.out);
        std.testing.allocator.free(proc.err);
    }

    try std.testing.expectStringEndsWith(proc.err, rain_run);
    try std.testing.expectEqual(proc.term.Exited, 0);
}

const default_run =
    \\info(xtxf): 0: 19x0 0/0
    \\info(xtxf): 0: 19x1 0/0
    \\info(xtxf): 0: 19x2 256/0
    \\info(xtxf): 0: 19x3 256/0
    \\info(xtxf): 0: 19x4 256/0
    \\info(xtxf): 1: 19x5 256/0
    \\info(xtxf): 0: 19x6 256/0
    \\info(xtxf): 1: 19x7 0/0
    \\info(xtxf): 0: 19x8 256/0
    \\info(xtxf): 0: 19x9 0/0
    \\info(xtxf): 1: 19x10 256/0
    \\info(xtxf): 0: 19x11 256/0
    \\info(xtxf): 1: 19x12 0/0
    \\info(xtxf): 1: 19x13 256/0
    \\info(xtxf): 1: 19x14 0/0
    \\info(xtxf): 1: 19x15 0/0
    \\info(xtxf): 1: 19x16 0/0
    \\info(xtxf): 0: 19x17 0/0
    \\info(xtxf): 1: 19x18 0/0
    \\info(xtxf): 1: 19x19 0/0
    \\info(xtxf): Exiting...
    \\
;

const decimal_run =
    \\info(xtxf): 9: 19x10 0/0
    \\info(xtxf): 8: 19x11 0/0
    \\info(xtxf): 2: 19x12 256/0
    \\info(xtxf): 2: 19x13 256/0
    \\info(xtxf): 9: 19x14 256/0
    \\info(xtxf): 6: 19x15 0/0
    \\info(xtxf): 6: 19x16 0/0
    \\info(xtxf): 5: 19x17 256/0
    \\info(xtxf): 0: 19x18 256/0
    \\info(xtxf): 0: 19x19 0/0
    \\info(xtxf): Exiting...
    \\
;

const hexadecimal_run =
    \\info(xtxf): F: 19x12 0/0
    \\info(xtxf): D: 19x13 256/0
    \\info(xtxf): 3: 19x14 0/0
    \\info(xtxf): 7: 19x15 0/0
    \\info(xtxf): D: 19x16 0/0
    \\info(xtxf): 4: 19x17 0/0
    \\info(xtxf): 3: 19x18 0/0
    \\info(xtxf): 9: 19x19 0/0
    \\info(xtxf): Exiting...
    \\
;

const textual_run =
    \\info(xtxf): +: 19x12 0/0
    \\info(xtxf): -: 19x13 0/0
    \\info(xtxf): ｹ: 19x14 0/0
    \\info(xtxf): ﾏ: 19x15 256/0
    \\info(xtxf): V: 19x16 0/0
    \\info(xtxf): ﾅ: 19x17 0/0
    \\info(xtxf): ﾄ: 19x18 0/0
    \\info(xtxf): ｢: 19x19 0/0
    \\info(xtxf): Exiting...
    \\
;

const red_run =
    \\info(xtxf): 1: 19x13 258/0
    \\info(xtxf): 1: 19x14 2/0
    \\info(xtxf): 1: 19x15 2/0
    \\info(xtxf): 1: 19x16 2/0
    \\info(xtxf): 0: 19x17 2/0
    \\info(xtxf): 1: 19x18 2/0
    \\info(xtxf): 1: 19x19 2/0
    \\info(xtxf): Exiting...
    \\
;

const green_run =
    \\info(xtxf): 1: 19x13 259/0
    \\info(xtxf): 1: 19x14 3/0
    \\info(xtxf): 1: 19x15 3/0
    \\info(xtxf): 1: 19x16 3/0
    \\info(xtxf): 0: 19x17 3/0
    \\info(xtxf): 1: 19x18 3/0
    \\info(xtxf): 1: 19x19 3/0
    \\info(xtxf): Exiting...
    \\
;

const blue_run =
    \\info(xtxf): 1: 19x13 261/0
    \\info(xtxf): 1: 19x14 5/0
    \\info(xtxf): 1: 19x15 5/0
    \\info(xtxf): 1: 19x16 5/0
    \\info(xtxf): 0: 19x17 5/0
    \\info(xtxf): 1: 19x18 5/0
    \\info(xtxf): 1: 19x19 5/0
    \\info(xtxf): Exiting...
    \\
;

const yellow_run =
    \\info(xtxf): 1: 19x13 260/0
    \\info(xtxf): 1: 19x14 4/0
    \\info(xtxf): 1: 19x15 4/0
    \\info(xtxf): 1: 19x16 4/0
    \\info(xtxf): 0: 19x17 4/0
    \\info(xtxf): 1: 19x18 4/0
    \\info(xtxf): 1: 19x19 4/0
    \\info(xtxf): Exiting...
    \\
;

const magenta_run =
    \\info(xtxf): 1: 19x13 262/0
    \\info(xtxf): 1: 19x14 6/0
    \\info(xtxf): 1: 19x15 6/0
    \\info(xtxf): 1: 19x16 6/0
    \\info(xtxf): 0: 19x17 6/0
    \\info(xtxf): 1: 19x18 6/0
    \\info(xtxf): 1: 19x19 6/0
    \\info(xtxf): Exiting...
    \\
;

const columns_run =
    \\info(xtxf): 6: 19x14 0/0
    \\info(xtxf): 4: 19x15 0/0
    \\info(xtxf): 3: 19x16 256/0
    \\info(xtxf): 4: 19x17 256/0
    \\info(xtxf): 2: 19x18 0/0
    \\info(xtxf): 3: 19x19 0/0
    \\info(xtxf): Exiting...
    \\
;

const crypto_run =
    \\info(xtxf): 1: 19x11 256/0
    \\info(xtxf): 1: 19x13 0/0
    \\info(xtxf): 3: 19x14 256/0
    \\info(xtxf): E: 19x16 0/0
    \\info(xtxf): 9: 19x17 0/0
    \\info(xtxf): 8: 19x19 0/0
    \\info(xtxf): Exiting...
    \\
;

const grid_run =
    \\info(xtxf): 0: 19x9 256/0
    \\info(xtxf): 1: 19x11 0/0
    \\info(xtxf): 0: 19x13 0/0
    \\info(xtxf): 0: 19x15 0/0
    \\info(xtxf): 0: 19x17 256/0
    \\info(xtxf): 0: 19x19 0/0
    \\info(xtxf): Exiting...
    \\
;

const blocks_run =
    \\info(xtxf): 1: 19x13 0/0
    \\info(xtxf): 2: 19x14 0/0
    \\info(xtxf): 7: 19x15 0/0
    \\info(xtxf): 4: 19x16 256/0
    \\info(xtxf): 5: 19x17 0/0
    \\info(xtxf): 4: 19x19 0/0
    \\info(xtxf): Exiting...
    \\
;

const rain_run =
    \\info(xtxf): ﾄ: 19x14 0/0
    \\info(xtxf): ｾ: 19x15 0/0
    \\info(xtxf): ｰ: 19x16 256/0
    \\info(xtxf): ﾆ: 19x17 0/0
    \\info(xtxf): #: 19x18 0/0
    \\info(xtxf): 6: 19x19 0/0
    \\info(xtxf): Exiting...
    \\
;
