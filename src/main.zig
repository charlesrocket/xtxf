const tb = @import("termbox2");
const std = @import("std");

const Attr = tb.AttributeSet;

fn printCell(width: i32, height: i32) !void {
    for (0..@intCast(width)) |w| {
        for (0..@intCast(height)) |h| {
            _ = try tb.print(@intCast(w), @intCast(h), Attr.init(.red).add(.bold), Attr.init(.default), "X");
            try tb.present();
        }
    }
}

pub fn main() !void {
    try tb.init();

    const width: i32 = try tb.width();
    const height: i32 = try tb.height();

    try printCell(width, height);

    std.time.sleep(1000000000);

    try tb.shutdown();
}
