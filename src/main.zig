const tb = @import("termbox2");
const std = @import("std");

const Attr = tb.AttributeSet;

fn printCells(width: i32, height: i32) !void {
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

fn animation(w: i32, h: i32) !void {
    while (true) {
        try printCells(w, h);
    }
}

fn handler() !void {
    const event = try tb.pollEvent();

    if (eqlStr(@tagName(event.kind), "key")) {
        std.os.exit(0);
    }
}

fn eqlStr(a: [:0]const u8, b: [:0]const u8) bool {
    if (a.len != b.len) return false;
    if (a.ptr == b.ptr) return true;

    for (a, b) |a_el, b_el| {
        if (a_el != b_el) return false;
    }

    return true;
}

pub fn main() !void {
    try tb.init();

    const width: i32 = try tb.width();
    const height: i32 = try tb.height();

    {
        const t0 = try std.Thread.spawn(.{}, animation, .{ width, height });
        defer t0.join();
        const t1 = try std.Thread.spawn(.{}, handler, .{});
        defer t1.join();
    }
}
