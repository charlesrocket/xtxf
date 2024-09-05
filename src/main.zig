const std = @import("std");
const tb = @cImport({
    @cInclude("termbox2.h");
});

const cova = @import("cova");
const cli = @import("cli.zig");
const build_opt = @import("build_options");

pub const CommandT = cli.CommandT;
pub const setup_cmd = cli.setup_cmd;

const Thread = std.Thread;
const Mutex = Thread.Mutex;
const log = std.log.scoped(.xtxf);
const assets = @import("assets.zig");

const HEAD_HASH = build_opt.gxt.hash[0..7];
const VERSION = if (build_opt.gxt.dirty == null) HEAD_HASH ++ "-unverified" else switch (build_opt.gxt.dirty.?) {
    true => HEAD_HASH ++ "-dirty",
    false => HEAD_HASH,
};

const FRAME = 39730492;

pub const Speed = enum { slow, fast };
pub const Mode = enum { binary, decimal, hexadecimal, textual };
pub const Style = enum { default, columns, crypto, grid, blocks, rain };
pub const Color = enum(u32) { default = tb.TB_DEFAULT, red = tb.TB_RED, green = tb.TB_GREEN, blue = tb.TB_BLUE, yellow = tb.TB_YELLOW, magenta = tb.TB_MAGENTA };

var sbuf: [2]u8 = undefined;
var mbuf: [3]u8 = undefined;
var lbuf: [4]u8 = undefined;

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
    lines: ?std.ArrayListAligned([]?u8, null) = null,
    width_gaps: ?std.ArrayListAligned(u32, null) = null,
    height_gaps: ?std.ArrayListAligned(u32, null) = null,

    fn setActive(self: *Core, value: bool) void {
        self.active = value;
    }

    fn setRendering(self: *Core, value: bool) void {
        self.rendering = value;
    }

    fn updateTermSize(self: *Core) !void {
        const width: i32 = tb.tb_width();
        const height: i32 = tb.tb_height();

        self.width = if (width < 0) 120 else width;
        self.height = if (height < 0) 120 else height;
    }

    fn updateWidthSec(self: *Core, adv: u32) !void {
        self.width_gaps.?.clearAndFree();
        self.width_gaps = try getNthValues(self.width, adv, self.allocator);
    }

    fn updateHeightSec(self: *Core, adv: u32) !void {
        self.height_gaps.?.clearAndFree();
        self.height_gaps = try getNthValues(self.height, adv, self.allocator);
    }

    fn updateStyle(self: *Core, style: Style) !void {
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

    fn init(gpallocator: std.mem.Allocator) Core {
        return .{ .allocator = gpallocator };
    }

    fn start(self: *Core) void {
        _ = tb.tb_init();

        if (self.lines == null) {
            self.lines = std.ArrayList([]?u8).init(self.allocator);
        }

        if (self.width_gaps == null) {
            self.width_gaps = std.ArrayList(u32).init(self.allocator);
        }

        if (self.height_gaps == null) {
            self.height_gaps = std.ArrayList(u32).init(self.allocator);
        }

        self.setActive(true);

        try self.updateTermSize();
    }

    fn shutdown(self: *Core) void {
        if (!self.active) {
            _ = tb.tb_shutdown();
        }

        if (self.lines) |lines| {
            for (lines.items) |line| {
                self.allocator.free(line);
            }
            lines.deinit();
        }

        if (self.width_gaps != null) {
            self.width_gaps.?.deinit();
        }

        if (self.height_gaps != null) {
            self.height_gaps.?.deinit();
        }
    }
};

const Handler = struct {
    mutex: Mutex = Mutex{},
    halt: bool = true,
    speed: Speed = .fast,
    duration: u32 = 0,
    pause: bool = false,
    mode: Mode = Mode.binary,
    style: Style = Style.default,

    fn setHalt(self: *Handler, value: bool) void {
        self.halt = value;
    }

    fn setPause(self: *Handler, value: bool) void {
        self.pause = value;
    }

    fn run(self: *Handler, core: *Core) !void {
        try core.updateStyle(self.style);

        var timer = try std.time.Timer.start();
        const duration = self.duration;

        self.setHalt(false);

        while (core.active) {
            if ((timer.read() / std.time.ns_per_s) >= duration and self.duration != 0) {
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

    fn init() Handler {
        return .{};
    }
};

fn printCells(core: *Core, handler: *Handler, rand: std.rand.Random) !void {
    handler.mutex.lock();
    defer handler.mutex.unlock();

    if (!handler.pause) {
        _ = tb.tb_clear();
        if (handler.style != .rain) {
            core.setRendering(true);

            for (0..@intCast(core.width)) |w| {
                if (handler.style != Style.default) {
                    if (checkSec(&core.width_gaps.?, w)) {
                        continue;
                    }
                }

                for (0..@intCast(core.height)) |h| {
                    if (handler.style != Style.default) {
                        if (checkSec(&core.height_gaps.?, h)) {
                            continue;
                        }
                    }

                    const rand_int = switch (handler.mode) {
                        .binary => rand.int(u1),
                        .decimal => rand.uintLessThan(u8, 10),
                        .hexadecimal => rand.int(u4),
                        .textual => rand.uintLessThan(u8, 76),
                    };

                    var color = @intFromEnum(core.color);

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

                    const char: [:0]u8 = switch (handler.mode) {
                        .binary, .decimal => try std.fmt.bufPrintZ(&sbuf, "{d}", .{rand_int}),
                        .hexadecimal => try std.fmt.bufPrintZ(&mbuf, "{c}", .{assets.hex_chars[rand_int]}),
                        .textual => try std.fmt.bufPrintZ(&lbuf, "{u}", .{assets.tex_chars[rand_int]}),
                    };

                    tbPrint(w, h, color, core.bg, char);

                    if (core.pulse) {
                        core.bg = tb.TB_DEFAULT;
                    }
                }
            }
        } else {
            height: for (0..@intCast(core.height)) |_| {
                var arr = std.ArrayList(?u8).init(core.allocator);
                defer arr.deinit();

                for (0..@intCast(core.width)) |_| {
                    const rand_int = switch (handler.mode) {
                        .binary => rand.int(u1),
                        .decimal => rand.uintLessThan(u8, 10),
                        .hexadecimal => rand.int(u4),
                        .textual => rand.uintLessThan(u8, 76),
                    };

                    var color = @intFromEnum(core.color);

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

                    const skip = rand.boolean();

                    if (skip) {
                        try arr.append(null);
                    } else {
                        try arr.append(rand_int);
                    }
                }

                const slice = try arr.toOwnedSlice();

                if (core.lines.?.items.len == core.height) {
                    const old_line = core.lines.?.pop();
                    core.allocator.free(old_line);
                    try core.lines.?.insert(0, slice);
                    break :height;
                }

                try core.lines.?.insert(0, slice);
            }

            for (0..core.lines.?.items.len) |h| {
                for (0..@intCast(core.width)) |w| {
                    const rand_int = core.lines.?.items[h][w];
                    if (rand_int == null) continue;
                    const char: [:0]u8 = switch (handler.mode) {
                        .binary, .decimal => try std.fmt.bufPrintZ(&sbuf, "{d}", .{rand_int.?}),
                        .hexadecimal => try std.fmt.bufPrintZ(&mbuf, "{c}", .{assets.hex_chars[rand_int.?]}),
                        .textual => try std.fmt.bufPrintZ(&lbuf, "{u}", .{assets.tex_chars[rand_int.?]}),
                    };

                    tbPrint(w, h, @intFromEnum(core.color), core.bg, char);
                }
            }
        }

        _ = tb.tb_present();
        core.setRendering(false);
        if (handler.style != .rain) {
            std.time.sleep(switch (handler.speed) {
                .slow => FRAME * 2,
                .fast => FRAME,
            });
        } else {
            std.time.sleep(FRAME * 5);
        }
    }
}

fn tbPrint(w: usize, h: usize, c: usize, b: usize, char: [*c]const u8) void {
    _ = tb.tb_print(@intCast(w), @intCast(h), @intCast(c), @intCast(b), char);
}

fn animation(handler: *Handler, core: *Core) !void {
    var prng = std.rand.DefaultPrng.init(@as(u64, @bitCast(std.time.milliTimestamp())));

    const rand = prng.random();

    while (handler.halt) {
        std.time.sleep(FRAME);
    }

    while (core.active) {
        try printCells(core, handler, rand);
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

pub fn main() !void {
    var gpallocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpallocator.deinit();

    var core = Core.init(gpallocator.allocator());
    var handler = Handler.init();

    const stdout = std.io.getStdOut().writer();
    const main_cmd = try setup_cmd.init(core.allocator, .{});
    defer main_cmd.deinit();

    var args_iter = try cova.ArgIteratorGeneric.init(core.allocator);
    defer args_iter.deinit();

    cova.parseArgs(&args_iter, CommandT, main_cmd, stdout, .{ .err_reaction = .Usage }) catch |err| switch (err) {
        error.UsageHelpCalled => {},
        else => return err,
    };

    const opts = try main_cmd.getOpts(.{});

    if (opts.get("color")) |color| {
        core.color = try color.val.getAs(Color);
    }

    if (opts.get("style")) |style| {
        handler.style = try style.val.getAs(Style);
    }

    if (opts.get("mode")) |mode| {
        handler.mode = try mode.val.getAs(Mode);
    }

    if (opts.get("time")) |time| {
        handler.duration = try time.val.getAs(u32);
    }

    if (opts.get("speed")) |speed| {
        handler.speed = try speed.val.getAs(Speed);
    }

    if (opts.get("pulse")) |pulse| {
        core.pulse = try pulse.val.getAs(bool);
    }

    if (main_cmd.checkFlag("version")) {
        // TODO add SemVer string
        try stdout.print("{s}{s}{s}", .{ "xtxf version ", VERSION, "\n" });
    }

    if (!(main_cmd.checkFlag("version") or main_cmd.checkFlag("help") or main_cmd.checkFlag("usage"))) {
        core.start();

        if (core.width < 4 or core.height < 2) {
            core.setActive(false);
            log.warn("Insufficient terminal dimensions: W {}, H {}", .{ core.width, core.height });
        }

        if (core.active) {
            const t_h = try std.Thread.spawn(.{}, Handler.run, .{ &handler, &core });
            defer t_h.join();

            const t_a = try std.Thread.spawn(.{}, animation, .{ &handler, &core });
            defer t_a.join();
        }

        core.shutdown();
    }
}

test "handler" {
    var core = Core{ .allocator = std.testing.allocator, .active = true };
    var handler = Handler{ .duration = 1 };

    try handler.run(&core);

    try std.testing.expect(!core.active);
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
