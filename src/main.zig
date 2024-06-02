const std = @import("std");
const tb = @cImport({
    @cInclude("termbox.h");
});

const Thread = std.Thread;
const Mutex = Thread.Mutex;

const Mode = enum { binary, decimal };
const Style = enum { default, columns, crypto };
const Color = enum { default, red, green, blue, yellow };

const Core = struct {
    mutex: Mutex,
    active: bool,
    duration: u32,
    mode: Mode,
    style: Style,
    pulse: bool,
    color: Color,
    bg: u32,
    width: i32,
    height: i32,
    width_sec: []u8,
    height_sec: []u8,

    pub fn setActive(self: *Core, value: bool) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        self.active = value;
    }
};

fn printCells(core: *Core, mode: u8, rand: std.rand.Random) !void {
    for (1..@intCast(core.width)) |w| {
        if (core.style != Style.default) {
            if (checkSec(core.width_sec, w)) {
                continue;
            }
        }

        for (1..@intCast(core.height)) |h| {
            if (core.style != Style.default) {
                if (checkSec(core.height_sec, h)) {
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

    std.time.sleep(39730492);
    _ = tb.tb_present();
}

fn animation(core: *Core) !void {
    var prng = std.rand.DefaultPrng.init(@as(u64, @bitCast(std.time.milliTimestamp())));
    const mode: u8 = switch (core.mode) {
        Mode.binary => 2,
        Mode.decimal => 10,
    };

    const rand = prng.random();

    while (core.active) {
        try printCells(core, mode, rand);
    }
}

fn handler(core: *Core) !void {
    var timer = try std.time.Timer.start();
    const duration = core.duration * 1000000000;

    while (core.active) {
        var event = tb.tb_event{
            .type = 0,
        };

        if (timer.read() >= duration and core.duration != 0) {
            core.setActive(false);
        }

        _ = tb.tb_peek_event(&event, 100);

        if (@as(u8, @intCast(event.type)) > 0) {
            core.setActive(false);
        }
    }
}

fn getNthValues(allocator: std.mem.Allocator, number: i32, n: u8) ![]u8 {
    var array = std.ArrayList(u8).init(allocator);
    var adv = n;

    defer array.deinit();

    while (adv <= number) {
        try array.append(adv);
        adv += n;
    }

    return array.toOwnedSlice();
}

fn checkSec(arr: []u8, value: usize) bool {
    for (arr) |el| {
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
    const allocator = gpallocator.allocator();
    defer _ = gpallocator.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var core = Core{ .mutex = Mutex{}, .active = true, .duration = 0, .width = undefined, .height = undefined, .width_sec = undefined, .height_sec = undefined, .pulse = false, .bg = tb.TB_DEFAULT, .style = Style.default, .mode = Mode.binary, .color = Color.default };

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
            std.debug.print("{s}\n", .{help_message});
            std.process.exit(0);
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
            core.mode = Mode.decimal;
        }

        if (eqlStr(arg, "--pulse") or eqlStr(arg, "-p")) {
            core.pulse = true;
        }

        if (eqlStr(arg, "--time=short") or eqlStr(arg, "-t=short")) {
            core.duration = 1;
        }

        if (eqlStr(arg, "--style=crypto") or eqlStr(arg, "-s=crypto")) {
            core.style = Style.crypto;
        } else if (eqlStr(arg, "--style=columns") or eqlStr(arg, "-s=columns")) {
            core.style = Style.columns;
        }
    }

    _ = tb.tb_init();

    core.width = tb.tb_width();
    core.height = tb.tb_height();

    if (core.width < 4 or core.height < 2) {
        _ = tb.tb_shutdown();
        std.debug.print("Insufficient terminal dimensions: W {}, H {}\nExiting\n", .{ core.width, core.height });
        std.process.exit(0);
    }

    if (core.style == Style.crypto) {
        core.width_sec = try getNthValues(allocator, core.width, 5);
        core.height_sec = try getNthValues(allocator, core.height, 3);
    }

    if (core.style == Style.columns) {
        core.width_sec = try getNthValues(allocator, core.width, 4);
    }

    defer {
        allocator.free(core.width_sec);
        allocator.free(core.height_sec);
    }

    {
        const t0 = try std.Thread.spawn(.{}, animation, .{&core});
        defer t0.join();

        const t1 = try std.Thread.spawn(.{}, handler, .{&core});
        defer t1.join();
    }

    _ = tb.tb_shutdown();
}

test "handler" {
    var core = Core{ .mutex = undefined, .active = true, .duration = 1, .mode = undefined, .pulse = undefined, .style = undefined, .color = undefined, .bg = undefined, .width = undefined, .height = undefined, .width_sec = undefined, .height_sec = undefined };
    try handler(&core);
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
    var array1 = [_]u8{ 1, 2, 3 };
    var array2 = [_]u8{ 1, 3 };
    var array3 = [_]u8{1};

    try std.testing.expect(checkSec(&array1, 2));
    try std.testing.expect(!checkSec(&array2, 2));
    try std.testing.expect(!checkSec(&array3, 2));
}

test "get nth values" {
    const allocator = std.testing.allocator;
    const array: []u8 = try getNthValues(allocator, 12, 4);
    defer allocator.free(array);

    try std.testing.expect(array[0] == 4);
    try std.testing.expect(array[1] == 8);
    try std.testing.expect(array[2] == 12);
    try std.testing.expect(array.len == 3);
}
