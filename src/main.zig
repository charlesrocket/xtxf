const std = @import("std");
const tb = @cImport({
    @cInclude("termbox.h");
});

const Thread = std.Thread;
const Mutex = Thread.Mutex;

const Mode = enum { binary, decimal };
const Core = struct {
    mutex: Mutex,
    active: bool,
    mode: Mode,

    pub fn stateChange(self: *Core, value: bool) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        self.active = value;
    }
};

fn printCells(width: i32, height: i32, mode: u8) !void {
    var rand = std.rand.DefaultPrng.init(@as(u64, @bitCast(std.time.milliTimestamp())));

    for (0..@intCast(width)) |w| {
        for (0..@intCast(height)) |h| {
            const number = @mod(rand.random().int(u8), mode);
            const int: u8 = @intCast(number);

            var buf: [2]u8 = undefined;
            const slice: [:0]u8 = try std.fmt.bufPrintZ(&buf, "{d}", .{int});

            _ = tb.tb_print(@intCast(w), @intCast(h), tb.TB_RED, tb.TB_DEFAULT, slice);
        }
    }

    _ = tb.tb_present();
}

fn animation(w: i32, h: i32, core: *Core) !void {
    const mode: u8 = switch (core.mode) {
        Mode.binary => 2,
        Mode.decimal => 10,
    };

    while (core.active) {
        try printCells(w, h, mode);
    }
}

fn handler(core: *Core) !void {
    var event = tb.tb_event{
        .type = 0,
    };

    _ = tb.tb_poll_event(&event);

    if (@as(u8, @intCast(event.type)) > 0) {
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
    var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpallocator.allocator();
    defer _ = gpallocator.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var core = Core{ .mutex = Mutex{}, .active = true, .mode = Mode.binary };

    const help_message =
        \\
        \\           ██             ████
        \\          ░██            ░██░
        \\ ██   ██ ██████ ██   ██ ██████
        \\  ██░██    ██░  ░██░██   ░██
        \\   ███     ██    ░███     ██
        \\  ██░██   ░██    ██░██   ░██
        \\ ██   ██   ██   ██  ░██   ██
        \\
        \\ Usage: xtxf [OPTIONS]
        \\
        \\ Options:
        \\   -d, --decimal   Decimal mode
        \\   -h, --help      Print this message
    ;

    for (args) |arg| {
        if (eqlStr(arg, "--help") or eqlStr(arg, "-h")) {
            std.debug.print("{s}\n", .{help_message});
            std.process.exit(0);
        }

        if (eqlStr(arg, "--decimal") or eqlStr(arg, "-d")) {
            core.mode = Mode.decimal;
        }
    }

    _ = tb.tb_init();

    const width: i32 = tb.tb_width();
    const height: i32 = tb.tb_height();

    {
        const t0 = try std.Thread.spawn(.{}, animation, .{ width, height, &core });
        defer t0.join();

        const t1 = try std.Thread.spawn(.{}, handler, .{&core});
        defer t1.join();
    }

    _ = tb.tb_shutdown();
}
