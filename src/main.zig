const std = @import("std");
const tb = @cImport({
    @cInclude("termbox2.h");
});

const Thread = std.Thread;
const Mutex = Thread.Mutex;
const log = std.log.scoped(.xtxf);

const Mode = enum { binary, decimal };
const Style = enum { default, columns, crypto, grid, blocks };
const Color = enum { default, red, green, blue, yellow };

const FRAME = 39730492;

const Core = struct {
    allocator: std.mem.Allocator,
    mutex: Mutex = Mutex{},
    active: bool = false,
    rendering: bool = false,
    pulse: bool = false,
    color: Color = Color.default,
    bg: u32 = tb.TB_DEFAULT,
    width: i32 = 0,
    height: i32 = 0,
    width_g_arr: std.ArrayListAligned(u32, null) = undefined,
    height_g_arr: std.ArrayListAligned(u32, null) = undefined,

    fn setActive(self: *@This(), value: bool) void {
        self.active = value;
    }

    fn setRendering(self: *@This(), value: bool) void {
        self.rendering = value;
    }

    fn updateTermSize(self: *@This()) !void {
        self.width = tb.tb_width();
        self.height = tb.tb_height();
    }

    fn updateWidthSec(self: *@This(), adv: u32) !void {
        self.width_g_arr.clearAndFree();
        self.width_g_arr = try getNthValues(self.width, adv, self.allocator);
    }

    fn updateHeightSec(self: *@This(), adv: u32) !void {
        self.height_g_arr.clearAndFree();
        self.height_g_arr = try getNthValues(self.height, adv, self.allocator);
    }

    fn updateStyle(self: *@This(), style: Style) !void {
        if (style == Style.grid) {
            self.mutex.lock();
            defer self.mutex.unlock();

            try self.updateWidthSec(2);
            try self.updateHeightSec(2);
        } else if (style == Style.crypto) {
            self.mutex.lock();
            defer self.mutex.unlock();

            try self.updateWidthSec(5);
            try self.updateHeightSec(3);
        } else if (style == Style.blocks) {
            self.mutex.lock();
            defer self.mutex.unlock();

            try self.updateWidthSec(10);
            try self.updateHeightSec(6);
        } else if (style == Style.columns) {
            self.mutex.lock();
            defer self.mutex.unlock();

            try self.updateWidthSec(4);
        }
    }

    fn init(self: *@This()) void {
        _ = tb.tb_init();

        self.width_g_arr = std.ArrayList(u32).init(self.allocator);
        self.height_g_arr = std.ArrayList(u32).init(self.allocator);
        self.setActive(true);

        try self.updateTermSize();
    }

    fn shutdown(self: *@This(), args: [][:0]u8, allocator: *std.heap.GeneralPurposeAllocator(.{})) void {
        if (!self.active) {
            _ = tb.tb_shutdown();
        }

        self.width_g_arr.deinit();
        self.height_g_arr.deinit();

        std.process.argsFree(self.allocator, args);
        _ = allocator.deinit();
    }
};

const Handler = struct {
    mutex: Mutex = Mutex{},
    halt: bool = true,
    duration: u32 = 0,
    pause: bool = false,
    mode: Mode = Mode.binary,
    style: Style = Style.default,

    fn setHalt(self: *@This(), value: bool) void {
        self.halt = value;
    }

    fn setPause(self: *@This(), value: bool) void {
        self.pause = value;
    }

    fn run(self: *@This(), core: *Core) !void {
        try core.updateStyle(self.style);

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
                self.setPause(true);

                while (core.rendering) {
                    std.time.sleep(FRAME / 2);
                }

                try core.updateTermSize();
                try core.updateStyle(self.style);

                self.setPause(false);
            }
        }
    }
};

fn printCells(core: *Core, handler: *Handler, mode: u8, rand: std.rand.Random) !void {
    handler.mutex.lock();
    defer handler.mutex.unlock();

    if (!handler.pause) {
        core.setRendering(true);

        for (1..@intCast(core.width)) |w| {
            if (handler.style != Style.default) {
                if (checkSec(&core.width_g_arr, w)) {
                    continue;
                }
            }

            for (1..@intCast(core.height)) |h| {
                if (handler.style != Style.default) {
                    if (checkSec(&core.height_g_arr, h)) {
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

                    // small probability
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
        core.setRendering(false);
        std.time.sleep(FRAME);
    }
}

fn animation(handler: *Handler, core: *Core) !void {
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

fn checkSec(arr: *std.ArrayListAligned(u32, null), value: usize) bool {
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
    var core = Core{ .allocator = gpallocator.allocator() };
    var handler = Handler{};

    const args = try std.process.argsAlloc(core.allocator);

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
        \\  -s, --style     Set style [default, columns, crypto, grid, blocks]
        \\  -t, --time      Set duration [loop, short]
        \\  -p, --pulse     Pulse blocks
        \\  -d, --decimal   Decimal mode
        \\  -h, --help      Print this message
    ;

    for (args) |arg| {
        if (eqlStr(arg, "--help") or eqlStr(arg, "-h")) {
            const stdout = std.io.getStdOut();
            try stdout.writer().print("{s}{s}", .{ help_message, "\n" });

            core.shutdown(args, &gpallocator);
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
        } else if (eqlStr(arg, "--style=blocks") or eqlStr(arg, "-s=blocks")) {
            handler.style = Style.blocks;
        } else if (eqlStr(arg, "--style=grid") or eqlStr(arg, "-s=grid")) {
            handler.style = Style.grid;
        }
    }

    core.init();

    if (core.width < 4 or core.height < 2) {
        core.setActive(false);
        core.shutdown(args, &gpallocator);
        log.warn("Insufficient terminal dimensions: W {}, H {}", .{ core.width, core.height });
        std.process.exit(0);
    }

    if (core.active) {
        const t_h = try std.Thread.spawn(.{}, Handler.run, .{ &handler, &core });
        defer t_h.join();

        const t_a = try std.Thread.spawn(.{}, animation, .{ &handler, &core });
        defer t_a.join();
    }

    core.shutdown(args, &gpallocator);
}

test "handler" {
    var core = Core{ .allocator = std.testing.allocator, .active = true };
    var handler = Handler{ .duration = 1 };

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

    try std.testing.expect(checkSec(&array1, 2));
    try std.testing.expect(!checkSec(&array2, 2));
    try std.testing.expect(!checkSec(&array3, 2));
}

test "sections" {
    const array = try getNthValues(12, 4, std.testing.allocator);
    defer array.deinit();

    try std.testing.expect(array.items[0] == 4);
    try std.testing.expect(array.items[1] == 8);
    try std.testing.expect(array.items[2] == 12);
    try std.testing.expect(array.items.len == 3);
}
