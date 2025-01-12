const std = @import("std");

pub const counting_future_main = @import("counting_future.zig").main;
pub const interleaved_counting_main = @import("interleaved_counting.zig").main;
const void_wrap_callback_main = @import("void_wrap_callback.zig").main;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const gpa_alloc = gpa.allocator();

    const args = try std.process.argsAlloc(gpa_alloc);
    defer std.process.argsFree(gpa_alloc, args);

    if (args.len < 2) {
        return error.NoExampleProvided;
    }

    const example = args[1];

    const example_map = std.StaticStringMap(*const fn () anyerror!void).initComptime(.{
        .{ "counting_future", &counting_future_main },
        .{ "interleaved_counting", &interleaved_counting_main },
        .{ "void_wrap_callback", &void_wrap_callback_main },
    });

    if (std.mem.eql(u8, example, "all")) {
        const keys = example_map.keys();
        const vals = example_map.values();

        for (keys, vals) |k, m| {
            std.log.info("Running example: {s}", .{k});

            try m();
        }

        return;
    }

    const example_main = example_map.get(example) orelse return error.InvalidExample;

    std.log.info("Running example: {s}\n", .{example});
    try example_main();
}
