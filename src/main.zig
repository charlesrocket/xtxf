const std = @import("std");
const tb = @cImport({
    @cInclude("termbox2.h");
});

const cova = @import("cova");
const build_opt = @import("build_options");

const Thread = std.Thread;
const Mutex = Thread.Mutex;
const log = std.log.scoped(.xtxf);
const assets = @import("assets.zig");

pub const Error = error{
    InvalidColor,
    InvalidStyle,
    IndalidMode,
};

const HEAD_HASH = build_opt.gxt.hash[0..7];
const VERSION = if (build_opt.gxt.dirty == null) HEAD_HASH ++ "-unverified" else switch (build_opt.gxt.dirty.?) {
    true => HEAD_HASH ++ "-dirty",
    false => HEAD_HASH,
};

const FRAME = 39730492;

const Mode = enum(u8) { binary = 2, decimal = 10 };
const Style = enum { default, columns, crypto, grid, blocks };
const Color = enum(u32) { default = tb.TB_DEFAULT, red = tb.TB_RED, green = tb.TB_GREEN, blue = tb.TB_BLUE, yellow = tb.TB_YELLOW, magenta = tb.TB_MAGENTA };

pub const CommandT = cova.Command.Custom(.{
    .global_help_prefix = "xtxf",
    .help_header_fmt = assets.help_message,
    .help_category_order = &.{
        .Prefix, .Header, .Aliases, .Examples, .Commands, .Options, .Values,
    },
    .examples_header_fmt = assets.examples_header,
    .global_usage_fn = struct {
        fn usage(self: anytype, writer: anytype, _: ?std.mem.Allocator) !void {
            const CmdT = @TypeOf(self.*);
            const OptT = CmdT.OptionT;
            const indent_fmt = CmdT.indent_fmt;
            var no_args = true;
            var pre_sep: []const u8 = "";

            try writer.print("USAGE:\n", .{});
            if (self.opts) |opts| {
                no_args = false;
                try writer.print("{s}{s} [", .{
                    indent_fmt,
                    self.name,
                });
                for (opts) |opt| {
                    try writer.print("{s} {s}{s} <{s}>", .{
                        pre_sep,
                        OptT.long_prefix orelse opt.short_prefix,
                        opt.long_name orelse &.{opt.short_name orelse 0},
                        opt.val.childTypeName(),
                    });
                    pre_sep = "\n  " ++ indent_fmt ++ indent_fmt;
                }
                try writer.print(" ]\n\n", .{});
            }
            if (self.sub_cmds) |cmds| {
                no_args = false;
                try writer.print("{s}{s} [", .{
                    indent_fmt,
                    self.name,
                });
                pre_sep = "";
                for (cmds) |cmd| {
                    try writer.print("{s} {s} ", .{
                        pre_sep,
                        cmd.name,
                    });
                    pre_sep = "|";
                }
                try writer.print("]\n\n", .{});
            }
            if (no_args) try writer.print("{s}{s}{s}", .{
                indent_fmt,
                indent_fmt,
                self.name,
            });
        }
    }.usage,
    .opt_config = .{
        .usage_fmt = assets.opt_usage,
    },
    .val_config = .{
        .custom_types = &.{
            Color,
            Style,
            Mode,
        },
        .child_type_parse_fns = &.{
            .{
                .ChildT = Color,
                .parse_fn = struct {
                    pub fn parseColor(color: [:0]const u8) !Color {
                        if (eqlStr("default", color)) {
                            return Color.default;
                        } else if (eqlStr("red", color)) {
                            return Color.red;
                        } else if (eqlStr("green", color)) {
                            return Color.green;
                        } else if (eqlStr("blue", color)) {
                            return Color.blue;
                        } else if (eqlStr("yellow", color)) {
                            return Color.yellow;
                        } else if (eqlStr("magenta", color)) {
                            return Color.magenta;
                        } else {
                            return error.InvalidColor;
                        }
                    }
                }.parseColor,
            },
            .{
                .ChildT = Style,
                .parse_fn = struct {
                    pub fn parseStyle(style: [:0]const u8) !Style {
                        if (eqlStr("default", style)) {
                            return Style.default;
                        } else if (eqlStr("columns", style)) {
                            return Style.columns;
                        } else if (eqlStr("crypto", style)) {
                            return Style.crypto;
                        } else if (eqlStr("grid", style)) {
                            return Style.grid;
                        } else if (eqlStr("blocks", style)) {
                            return Style.blocks;
                        } else {
                            return error.InvalidStyle;
                        }
                    }
                }.parseStyle,
            },
            .{
                .ChildT = Mode,
                .parse_fn = struct {
                    pub fn parseMode(mode: [:0]const u8) !Mode {
                        if (eqlStr("binary", mode)) {
                            return Mode.binary;
                        } else if (eqlStr("decimal", mode)) {
                            return Mode.decimal;
                        } else {
                            return error.InvalidMode;
                        }
                    }
                }.parseMode,
            },
        },
    },
});

const ValueT = CommandT.ValueT;

pub const setup_cmd: CommandT = .{
    .name = "xtxf",
    .description = "Binary matrix.",
    .examples = &.{
        "xtxf -p -m decimal -c red -s crypto",
    },
    .sub_cmds_mandatory = false,
    .sub_cmds = &.{
        .{
            .name = "version",
            .description = "Show the 'xtxf' version.",
        },
    },
    .opts = &.{
        .{
            .name = "color",
            .description = "Set output color (default, red, green, blue, yellow, magenta).",
            .short_name = 'c',
            .long_name = "color",
            .val = ValueT.ofType(Color, .{ .name = "color_val", .default_val = Color.default, .alias_child_type = "string" }),
        },
        .{
            .name = "style",
            .description = "Set output style (default, columns, crypto, grid, blocks).",
            .short_name = 's',
            .long_name = "style",
            .val = ValueT.ofType(Style, .{ .name = "style_val", .default_val = Style.default, .alias_child_type = "string" }),
        },
        .{
            .name = "mode",
            .description = "Set symbol mode (binary, decimal).",
            .short_name = 'm',
            .long_name = "mode",
            .val = ValueT.ofType(Mode, .{ .name = "mode_val", .default_val = Mode.binary, .alias_child_type = "string" }),
        },
        .{
            .name = "pulse",
            .description = "Enable pulse blocks.",
            .short_name = 'p',
            .long_name = "pulse",
            .val = ValueT.ofType(bool, .{
                .name = "pulse_flag",
                .default_val = false,
            }),
        },
        .{
            .name = "time",
            .description = "Set duration (seconds).",
            .short_name = 't',
            .long_name = "time",
            .val = ValueT.ofType(u32, .{
                .name = "time",
                .default_val = 0,
            }),
        },
        .{
            .name = "version",
            .description = "Show the 'xtxf' version.",
            .short_name = 'v',
            .long_name = "version",
            .val = ValueT.ofType(bool, .{
                .name = "version_flag",
                .default_val = false,
            }),
        },
    },
};

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
        core.setRendering(true);

        for (1..@intCast(core.width)) |w| {
            if (handler.style != Style.default) {
                if (checkSec(&core.width_gaps.?, w)) {
                    continue;
                }
            }

            for (1..@intCast(core.height)) |h| {
                if (handler.style != Style.default) {
                    if (checkSec(&core.height_gaps.?, h)) {
                        continue;
                    }
                }

                const number = @mod(rand.int(u8), @intFromEnum(handler.mode));
                const int: u8 = @intCast(number);

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

    var core = Core.init(gpallocator.allocator());
    var handler = Handler.init();

    const stdout = std.io.getStdOut().writer();
    const main_cmd = try setup_cmd.init(core.allocator, .{});
    defer main_cmd.deinit();

    var args_iter = try cova.ArgIteratorGeneric.init(core.allocator);
    defer args_iter.deinit();

    cova.parseArgs(&args_iter, CommandT, main_cmd, stdout, .{}) catch |err| switch (err) {
        error.UsageHelpCalled => {},
        else => return err,
    };

    if ((try main_cmd.getOpts(.{})).get("color")) |color| {
        core.color = try color.val.getAs(Color);
    }

    if ((try main_cmd.getOpts(.{})).get("style")) |style| {
        handler.style = try style.val.getAs(Style);
    }

    if ((try main_cmd.getOpts(.{})).get("mode")) |mode| {
        handler.mode = try mode.val.getAs(Mode);
    }

    if ((try main_cmd.getOpts(.{})).get("time")) |time| {
        handler.duration = try time.val.getAs(u32);
    }

    if ((try main_cmd.getOpts(.{})).get("pulse")) |pulse| {
        core.pulse = try pulse.val.getAs(bool);
    }

    if ((try ((try main_cmd.getOpts(.{})).get("version")).?.val.getAs(bool)) or main_cmd.checkSubCmd("version")) {
        // TODO add SemVer string
        try stdout.print("{s}{s}{s}", .{ "xtxf version ", VERSION, "\n" });
    }

    if (!main_cmd.checkOpts(&.{ "help", "version" }, .{}) and !main_cmd.checkSubCmd("help") and !main_cmd.checkSubCmd("usage") and !main_cmd.checkSubCmd("version")) {
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
