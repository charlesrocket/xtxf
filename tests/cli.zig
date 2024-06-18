const std = @import("std");
const build_options = @import("build_options");

test "main" {
    const exe_path = build_options.exe_path;
    const argv = [_][]const u8{ exe_path, "--time=short" };
    const proc = try std.ChildProcess.run(.{
        .allocator = std.testing.allocator,
        .argv = &argv,
    });

    defer std.testing.allocator.free(proc.stdout);
    defer std.testing.allocator.free(proc.stderr);

    const term = proc.term;

    try std.testing.expectEqual(term, std.ChildProcess.Term{ .Exited = 0 });
}
