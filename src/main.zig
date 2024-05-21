const tb = @import("termbox2");
const std = @import("std");

const Attr = tb.AttributeSet;
const Thread = std.Thread;
const Mutex = Thread.Mutex;

const Core = struct {
    mutex: Mutex,
    active: bool,

    pub fn stateChange(self: *Core, value: bool) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        self.active = value;
    }
};

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

fn animation(w: i32, h: i32, core: *Core) !void {
    while (core.active) {
        try printCells(w, h);
    }
}

fn handler(core: *Core) !void {
    const event = try tb.pollEvent();

    if (eqlStr(@tagName(event.kind), "key")) {
        core.stateChange(false);
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

    var core = Core{ .mutex = Mutex{}, .active = true };

    {
        const t0 = try std.Thread.spawn(.{}, animation, .{ width, height, &core });
        defer t0.join();

        const t1 = try std.Thread.spawn(.{}, handler, .{&core});
        defer t1.join();
    }

    try tb.shutdown();
}
