const main = @import("main.zig");
const std = @import("std");

const cova = @import("cova");
const assets = @import("assets.zig");

const Color = main.Color;
const Style = main.Style;
const Mode = main.Mode;

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
                        if (std.mem.eql(u8, "default", color)) {
                            return Color.default;
                        } else if (std.mem.eql(u8, "red", color)) {
                            return Color.red;
                        } else if (std.mem.eql(u8, "green", color)) {
                            return Color.green;
                        } else if (std.mem.eql(u8, "blue", color)) {
                            return Color.blue;
                        } else if (std.mem.eql(u8, "yellow", color)) {
                            return Color.yellow;
                        } else if (std.mem.eql(u8, "magenta", color)) {
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
                        if (std.mem.eql(u8, "default", style)) {
                            return Style.default;
                        } else if (std.mem.eql(u8, "columns", style)) {
                            return Style.columns;
                        } else if (std.mem.eql(u8, "crypto", style)) {
                            return Style.crypto;
                        } else if (std.mem.eql(u8, "grid", style)) {
                            return Style.grid;
                        } else if (std.mem.eql(u8, "blocks", style)) {
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
                        if (std.mem.eql(u8, "binary", mode)) {
                            return Mode.binary;
                        } else if (std.mem.eql(u8, "decimal", mode)) {
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
