const std = @import("std");

const counting_future_main = @import("counting_future.zig").main;

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
    std.log.info("Running example: {s}\n", .{example});

    const example_map = std.StaticStringMap(*const fn () anyerror!void).initComptime(.{
        .{ "counting_future", &counting_future_main },
    });

    const example_main = example_map.get(example) orelse return error.InvalidExample;

    try example_main();
}
