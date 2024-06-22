const std = @import("std");
const tb = @cImport({
    @cInclude("termbox.h");
});

const Thread = std.Thread;
const Mutex = Thread.Mutex;

const Mode = enum { binary, decimal };
const Style = enum { default, columns, crypto };
const Color = enum { default, red, green, blue, yellow };

const FRAME = 39730492;

const Core = struct {
    allocator: std.mem.Allocator,
    mutex: Mutex,
    active: bool,
    pulse: bool,
    color: Color,
    bg: u32,
    width: i32,
    height: i32,
    width_g_arr: std.ArrayListAligned(u32, null),
    height_g_arr: std.ArrayListAligned(u32, null),

    fn setActive(self: *@This(), value: bool) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        self.active = value;
    }

    fn updateTermSize(self: *@This()) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        self.width = tb.tb_width();
        self.height = tb.tb_height();
    }

    fn updateWidthSec(self: *@This(), adv: u32) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        self.width_g_arr.clearAndFree();
        self.width_g_arr = try getNthValues(self.width, adv, self.allocator);
    }

    fn updateHeightSec(self: *@This(), adv: u32) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        self.height_g_arr.clearAndFree();
        self.height_g_arr = try getNthValues(self.height, adv, self.allocator);
    }
};

const Handler = struct {
    mutex: Mutex,
    halt: bool,
    duration: u32,
    pause: bool,
    mode: Mode,
    style: Style,

    fn setHalt(self: *@This(), value: bool) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        self.halt = value;
    }

    fn setPause(self: *@This(), value: bool) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        self.pause = value;
    }

    fn run(self: *@This(), core: *Core) !void {
        if (self.style != Style.default) {
            if (self.style == Style.crypto) {
                try core.updateWidthSec(5);
                try core.updateHeightSec(3);
            } else if (self.style == Style.columns) {
                try core.updateWidthSec(4);
            }
        }

        var timer = try std.time.Timer.start();
        const duration = self.duration * 1000000000;

        self.setHalt(false);

        while (core.active) {
            if (timer.read() >= duration and self.duration != 0) {
                core.setActive(false);
            }

            var EVENT = tb.tb_event{
                .type = 0,
            };

            _ = tb.tb_peek_event(&EVENT, 100);

            if (@as(u8, @intCast(EVENT.type)) == 1) {
                core.setActive(false);
            } else if (@as(u8, @intCast(EVENT.type)) == 2) {
                try core.updateTermSize();

                if (self.style == Style.crypto) {
                    try core.updateWidthSec(5);
                    try core.updateHeightSec(3);
                } else if (self.style == Style.columns) {
                    try core.updateWidthSec(4);
                }
            }
        }
    }
};

fn printCells(core: *Core, handler: *Handler, mode: u8, rand: std.rand.Random) !void {
    if (!handler.pause) {
        for (1..@intCast(core.width)) |w| {
            if (handler.style != Style.default) {
                if (checkSec(core.width_g_arr, w)) {
                    continue;
                }
            }

            for (1..@intCast(core.height)) |h| {
                if (handler.style != Style.default) {
                    if (checkSec(core.height_g_arr, h)) {
                        continue;
                    }
                }

                const number = @mod(rand.int(u8), mode);
                const int: u8 = @intCast(number);

                var color: u32 = switch (core.color) {
                    Color.default => tb.TB_DEFAULT,
                    Color.red => tb.TB_RED,
                    Color.green => tb.TB_GREEN,
                    Color.blue => tb.TB_BLUE,
                    Color.yellow => tb.TB_YELLOW,
                };

                const bold = rand.boolean();

                if (core.pulse) {
                    const blank = @mod(rand.int(u8), 255);

                    if (blank >= 254) {
                        core.bg = core.bg | tb.TB_REVERSE;
                    }
                }

                if (bold) {
                    color = color | tb.TB_BOLD;
                }

                var buf: [2]u8 = undefined;
                const slice: [:0]u8 = try std.fmt.bufPrintZ(&buf, "{d}", .{int});

                _ = tb.tb_print(@intCast(w), @intCast(h), @intCast(color), @intCast(core.bg), slice);

                if (core.pulse) {
                    core.bg = tb.TB_DEFAULT;
                }
            }
        }

        _ = tb.tb_present();
        std.time.sleep(FRAME);
    }
}

fn animation(core: *Core, handler: *Handler) !void {
    var prng = std.rand.DefaultPrng.init(@as(u64, @bitCast(std.time.milliTimestamp())));
    const mode: u8 = switch (handler.mode) {
        Mode.binary => 2,
        Mode.decimal => 10,
    };

    const rand = prng.random();

    while (handler.halt) {
        std.time.sleep(FRAME);
    }

    while (core.active) {
        try printCells(core, handler, mode, rand);
    }
}

fn getNthValues(number: i32, adv: u32, allocator: std.mem.Allocator) !std.ArrayListAligned(u32, null) {
    var array = std.ArrayList(u32).init(allocator);
    var val = adv;

    while (val <= @as(u32, @intCast(number))) {
        try array.append(val);
        val += adv;
    }

    return array;
}

fn checkSec(arr: std.ArrayListAligned(u32, null), value: usize) bool {
    for (arr.items) |el| {
        if (el == value) {
            return true;
        }
    }

    return false;
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
    defer _ = gpallocator.deinit();

    var core = Core{ .allocator = gpallocator.allocator(), .mutex = Mutex{}, .active = true, .width = undefined, .height = undefined, .width_g_arr = undefined, .height_g_arr = undefined, .pulse = false, .bg = tb.TB_DEFAULT, .color = Color.default };
    var handler = Handler{ .mutex = Mutex{}, .halt = true, .duration = 0, .pause = false, .mode = Mode.binary, .style = Style.default };

    const args = try std.process.argsAlloc(core.allocator);
    defer std.process.argsFree(core.allocator, args);

    core.width_g_arr = std.ArrayList(u32).init(core.allocator);
    core.height_g_arr = std.ArrayList(u32).init(core.allocator);

    defer {
        core.width_g_arr.deinit();
        core.height_g_arr.deinit();
    }

    const help_message =
        \\
        \\          ██             ████
        \\         ░██            ░██░
        \\██   ██ ██████ ██   ██ ██████
        \\ ██ ██░   ██░  ░██ ██   ░██
        \\ ░███     ██     ███░    ██
        \\ ██░██   ░██    ██ ██   ░██
        \\██   ██   ██   ██  ░██   ██
        \\
        \\Usage: xtxf [OPTIONS]
        \\
        \\Example: xtxf -p -c=red -s=crypto
        \\
        \\Options:
        \\  -c, --color     Set color [default, red, green, blue, yellow]
        \\  -s, --style     Set style [default, columns, crypto]
        \\  -t, --time      Set duration [loop, short]
        \\  -p, --pulse     Pulse blocks
        \\  -d, --decimal   Decimal mode
        \\  -h, --help      Print this message
    ;

    for (args) |arg| {
        if (eqlStr(arg, "--help") or eqlStr(arg, "-h")) {
            const stdout_file = std.io.getStdOut().writer();
            var bw = std.io.bufferedWriter(stdout_file);
            const stdout = bw.writer();

            try stdout.print("{s}\n", .{help_message});
            try bw.flush();

            core.active = false;
        }

        if (eqlStr(arg, "--color=default") or eqlStr(arg, "-c=default")) {
            core.color = Color.default;
        } else if (eqlStr(arg, "--color=red") or eqlStr(arg, "-c=red")) {
            core.color = Color.red;
        } else if (eqlStr(arg, "--color=green") or eqlStr(arg, "-c=green")) {
            core.color = Color.green;
        } else if (eqlStr(arg, "--color=blue") or eqlStr(arg, "-c=blue")) {
            core.color = Color.blue;
        } else if (eqlStr(arg, "--color=yellow") or eqlStr(arg, "-c=yellow")) {
            core.color = Color.yellow;
        }
        if (eqlStr(arg, "--decimal") or eqlStr(arg, "-d")) {
            handler.mode = Mode.decimal;
        }

        if (eqlStr(arg, "--pulse") or eqlStr(arg, "-p")) {
            core.pulse = true;
        }

        if (eqlStr(arg, "--time=short") or eqlStr(arg, "-t=short")) {
            handler.duration = 1;
        }

        if (eqlStr(arg, "--style=crypto") or eqlStr(arg, "-s=crypto")) {
            handler.style = Style.crypto;
        } else if (eqlStr(arg, "--style=columns") or eqlStr(arg, "-s=columns")) {
            handler.style = Style.columns;
        }
    }

    _ = tb.tb_init();

    core.width = tb.tb_width();
    core.height = tb.tb_height();

    if (core.width < 4 or core.height < 2) {
        std.log.warn("Insufficient terminal dimensions: W {}, H {}", .{ core.width, core.height });
        core.active = false;
    }

    if (core.active) {
        const t_h = try std.Thread.spawn(.{}, Handler.run, .{ &handler, &core });
        defer t_h.join();

        const t_a = try std.Thread.spawn(.{}, animation, .{ &core, &handler });
        defer t_a.join();
    }

    _ = tb.tb_shutdown();
}

test "handler" {
    var core = Core{ .allocator = std.testing.allocator, .mutex = Mutex{}, .active = true, .width = undefined, .height = undefined, .width_g_arr = undefined, .height_g_arr = undefined, .pulse = undefined, .bg = undefined, .color = undefined };
    var handler = Handler{ .mutex = Mutex{}, .halt = true, .duration = 1, .pause = false, .mode = Mode.binary, .style = Style.default };

    try handler.run(&core);

    try std.testing.expect(!core.active);
}

test "compare strings" {
    const a1 = "deFg13z";
    const a2 = "DeFg13z";
    const b1 = "abcDeFg13z";
    const b2 = "abcdefg11a";
    const c1 = "abcDeFg823_@#$mdh6132";
    const c2 = "abcDeFg823_@#$mdh6132";
    const d1 = "a";
    const d2 = "a";
    const e1 = "b";
    const e2 = "c";

    try std.testing.expect(!eqlStr(a1, a2));
    try std.testing.expect(!eqlStr(b1, b2));
    try std.testing.expect(eqlStr(c1, c2));
    try std.testing.expect(eqlStr(d1, d2));
    try std.testing.expect(!eqlStr(e1, e2));
}

test "check array" {
    var array1 = std.ArrayList(u32).init(std.testing.allocator);
    var array2 = std.ArrayList(u32).init(std.testing.allocator);
    var array3 = std.ArrayList(u32).init(std.testing.allocator);

    defer {
        array1.deinit();
        array2.deinit();
        array3.deinit();
    }

    try array1.append(1);
    try array1.append(2);
    try array1.append(3);

    try array2.append(1);
    try array2.append(3);

    try array3.append(1);

    try std.testing.expect(checkSec(array1, 2));
    try std.testing.expect(!checkSec(array2, 2));
    try std.testing.expect(!checkSec(array3, 2));
}

test "sections" {
    const array = try getNthValues(12, 4, std.testing.allocator);
    defer array.deinit();

    try std.testing.expect(array.items[0] == 4);
    try std.testing.expect(array.items[1] == 8);
    try std.testing.expect(array.items[2] == 12);
    try std.testing.expect(array.items.len == 3);
}
