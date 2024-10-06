const main = @import("main.zig");
const std = @import("std");

const cova = @import("cova");
const assets = @import("assets.zig");

const Speed = main.Speed;
const Color = main.Color;
const Style = main.Style;
const Mode = main.Mode;
const Accent = main.Accent;

pub const CommandT = cova.Command.Custom(.{
    .global_help_prefix = assets.help_prefix,
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

            try writer.print("{s}{s}USAGE:\n", .{ assets.help_prefix, "\n" });
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
            Speed,
            Color,
            Style,
            Mode,
            Accent,
        },
    },
});

const ValueT = CommandT.ValueT;

pub const setup_cmd: CommandT = .{
    .name = "xtxf",
    .description = "2D matrix screensaver.",
    .examples = &.{
        "xtxf -m decimal -s crypto -a bold,dim",
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
            .description = "Set output color " ++ genVals(Color, 0) ++ ".",
            .short_name = 'c',
            .long_name = "color",
            .val = ValueT.ofType(Color, .{
                .name = "color_val",
                .default_val = Color.default,
                .alias_child_type = "string",
            }),
        },
        .{
            .name = "style",
            .description = "Set the output style " ++ genVals(Style, 0) ++ ".",
            .short_name = 's',
            .long_name = "style",
            .val = ValueT.ofType(Style, .{
                .name = "style_val",
                .default_val = Style.default,
                .alias_child_type = "string",
            }),
        },
        .{
            .name = "mode",
            .description = "Symbol mode " ++ genVals(Mode, 0) ++ ".",
            .short_name = 'm',
            .long_name = "mode",
            .val = ValueT.ofType(Mode, .{
                .name = "mode_val",
                .default_val = Mode.binary,
                .alias_child_type = "string",
            }),
        },
        .{
            .name = "accents",
            .description = "Enable symbol accentuations " ++ genVals(Accent, null) ++ ".",
            .short_name = 'a',
            .long_name = "accents",
            .val = ValueT.ofType(Accent, .{
                .name = "accents",
                .alias_child_type = "[string]",
                .set_behavior = .Multi,
                .max_entries = 4,
            }),
        },
        .{
            .name = "time",
            .description = "Set the duration in seconds.",
            .short_name = 't',
            .long_name = "time",
            .val = ValueT.ofType(u32, .{
                .name = "time",
                .default_val = 0,
            }),
        },
        .{
            .name = "speed",
            .description = "Set the output speed " ++ genVals(Speed, 1) ++ ".",
            .long_name = "speed",
            .val = ValueT.ofType(Speed, .{
                .name = "speed_val",
                .default_val = Speed.normal,
                .alias_child_type = "string",
            }),
        },
        .{
            .name = "debug",
            .description = "Enable debug mode.",
            .long_name = "debug",
            .val = ValueT.ofType(bool, .{
                .name = "debug_flag",
                .default_val = false,
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

fn genVals(T: type, default: ?usize) []const u8 {
    return blk: {
        var str: []const u8 = "(";
        const vals = std.meta.fieldNames(T);

        for (vals, 0..) |val, i| {
            str = if (default != null and default == i) dflt: {
                break :dflt str ++ "*" ++ val;
            } else str ++ val;

            if (i < vals.len - 1) {
                str = str ++ ", ";
            }
        }

        str = str ++ ")";
        break :blk str;
    };
}
