const std = @import("std");
const build_options = @import("build_options");

test "default" {
    const exe_path = build_options.exe_path;
    const argv = [_][]const u8{ exe_path, "--time=short" };
    const proc = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &argv,
    });

    defer std.testing.allocator.free(proc.stdout);
    defer std.testing.allocator.free(proc.stderr);

    const term = proc.term;

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}

test "columns" {
    const exe_path = build_options.exe_path;
    const argv = [_][]const u8{ exe_path, "--time=short", "-s=columns" };
    const proc = try std.process.Child.run(.{
        .allocator = std.testing.allocator,
        .argv = &argv,
    });

    defer std.testing.allocator.free(proc.stdout);
    defer std.testing.allocator.free(proc.stderr);

    const term = proc.term;

    try std.testing.expectEqual(term, std.process.Child.Term{ .Exited = 0 });
}
