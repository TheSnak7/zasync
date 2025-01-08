const std = @import("std");
const Allocator = std.mem.Allocator;
const fut = @import("future.zig");
const Future = fut.Future;

pub const Executor = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        zawait: *const fn (ctx: *anyopaque) anyerror!void,
    };

    pub fn zawait(ctx: *Executor) !void {
        return try ctx.vtable.*.poll(ctx);
    }
};

pub const SingleBlockingExecutor = struct {
    fn zawait(ctx: *anyopaque, future: *Future) void {
        var self: SingleBlockingExecutor = @alignCast(@ptrCast(ctx));
        return self.blockOn(future);
    }

    pub fn init() SingleBlockingExecutor {
        return .{};
    }

    pub fn blockOn(_: *SingleBlockingExecutor, future: *Future) void {
        while (true) {
            future.poll() catch |e| switch (e) {
                Future.Pending => {},
                Future.Ready => return,
                else => {
                    std.log.err("SingleBlockingExecutor future failed: {s}\n", .{@errorName(e)});
                },
            };
        }
    }

    pub fn executor(self: *SingleBlockingExecutor) Executor {
        return .{
            .ptr = self,
            .vtable = &.{
                .zawait = zawait,
            },
        };
    }
};
