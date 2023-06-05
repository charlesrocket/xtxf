const std = @import("std");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var msg =
    \\   /.\|/x\|/.\|/   /
    \\  /__      ___ (  /
    \\  \\--`-'-|`---\\ |
    \\   |' _/   ` __/ /
    \\   '._  W    ,--'
    \\      |_:_._/
    ;

    try stdout.print("{s}\n\n", .{msg});
    try bw.flush();
}
