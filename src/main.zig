const tb = @import("termbox2");
const std = @import("std");

const Attr = tb.AttributeSet;

fn printCell(width: i32, height: i32) !void {
    var rand = std.rand.DefaultPrng.init(@as(u64, @bitCast(std.time.milliTimestamp())));

    for (0..@intCast(width)) |w| {
        for (0..@intCast(height)) |h| {
            const number = @mod(rand.random().int(i8), 2);
            const int: u8 = @intCast(number);

            var buf: [2]u8 = undefined;
            var slice: [:0]u8 = try std.fmt.bufPrintZ(&buf, "{d}", .{int});

            _ = try tb.print(@intCast(w), @intCast(h), Attr.init(.red).add(.bold), Attr.init(.default), slice);
        }

        try tb.present();
    }
}

pub fn main() !void {
    try tb.init();

    const width: i32 = try tb.width();
    const height: i32 = try tb.height();

    try printCell(width, height);

    _ = try tb.pollEvent();
    try tb.shutdown();
}
