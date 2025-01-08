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

// This is a demonstration executor.
pub const LinearExecutor = struct {
    alloc: Allocator,
    // Reminder: No lifetimes -> not complex (right now), in the future the Executor should own the futures.
    tasks: std.ArrayListUnmanaged(*Future),

    fn zawait(ctx: *anyopaque, future: *Future) void {
        var self: LinearExecutor = @alignCast(@ptrCast(ctx));
        return self.blockOn(future);
    }

    // This is a demo function, normally a part of the implementation
    pub fn run(self: *LinearExecutor) void {
        while (self.tasks.items.len != 0) {
            for (0..self.tasks.items.len) |i| {
                var future = self.tasks.items[i];

                future.poll() catch |e| switch (e) {
                    Future.Ready => {
                        _ = self.tasks.swapRemove(i);
                        break;
                    },
                    Future.Pending => {
                        continue;
                    },
                    else => {
                        std.log.err("LinearExecutor future failed: {s}\n", .{@errorName(e)});
                    },
                };
            }
        }
    }

    pub fn init(alloc: Allocator) LinearExecutor {
        return .{
            .alloc = alloc,
            .tasks = .empty,
        };
    }

    pub fn initWithFutures(alloc: Allocator, futures: []*Future) LinearExecutor {
        std.debug.assert(futures.len != 0);
        return .{
            .alloc = alloc,
            .tasks = .empty,
        };
    }

    pub fn deinit(self: *LinearExecutor) void {
        self.tasks.deinit(self.alloc);
    }

    pub fn pushFuture(self: *LinearExecutor, future: *Future) !void {
        try self.tasks.append(self.alloc, future);
    }

    pub fn blockOn(_: *LinearExecutor, future: *Future) void {
        while (true) {
            future.poll() catch |e| switch (e) {
                Future.Pending => {},
                Future.Ready => return,
                else => {
                    std.log.err("LinearExecutor future failed: {s}\n", .{@errorName(e)});
                },
            };
        }
    }

    pub fn executor(self: *LinearExecutor) Executor {
        return .{
            .ptr = self,
            .vtable = &.{
                .zawait = zawait,
            },
        };
    }
};
