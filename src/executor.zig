const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const futures = @import("futures.zig");
const verify = @import("verify.zig");
const Future = futures.Future;

pub const Executor = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        // Rethink this
        //zawait: *const fn (ctx: *anyopaque, future: *const Future(void)) anyerror!void,
        allocator: *const fn (ctx: *const anyopaque) Allocator,
    };

    pub fn allocator(ctx: *const Executor) Allocator {
        return ctx.vtable.allocator(ctx);
    }

    pub fn createFuture(ctx: *Executor, FT: type) !*FT {
        var ex_alloc = ctx.allocator();
        return try ex_alloc.create(FT);
    }

    pub fn destroyFuture(ctx: *const Executor, future: anytype) void {
        verify.assertPointerToFuture(@TypeOf(future));
        future.assertIsOwner();

        const ex_alloc = ctx.allocator();

        const future_info = @typeInfo(@TypeOf(future));
        std.debug.assert(future_info == .pointer);

        ex_alloc.destroy(future);
        return;
    }

    pub fn zawait(ctx: *Executor) !void {
        return try ctx.vtable.poll(ctx);
    }
};

pub const NullExecutor = struct {
    pub fn executor() Executor {
        return .{
            .ptr = undefined,
            .vtable = &.{
                //.zawait = zawait,
                .allocator = undefined,
            },
        };
    }
};

pub const SingleBlockingExecutor = struct {
    inner_allocator: Allocator,
    future: ?Future(void),

    fn zawait(ctx: *anyopaque, future: *Future(void)) void {
        var self: *SingleBlockingExecutor = @alignCast(@ptrCast(ctx));
        return self.blockOn(future);
    }

    fn allocator(ctx: *const anyopaque) Allocator {
        const self: *const SingleBlockingExecutor = @alignCast(@ptrCast(ctx));
        return self.inner_allocator;
    }

    pub fn init(alloc: Allocator) SingleBlockingExecutor {
        return .{
            .inner_allocator = alloc,
            .future = null,
        };
    }

    pub fn deinit(self: *SingleBlockingExecutor) void {
        _ = self;
        // if (self.future) |f| {
        //     self.alloc.destroy(f);
        // }
    }

    pub fn blockOn(self: *SingleBlockingExecutor, future: *Future(void)) void {
        var ex = self.executor();
        self.future = future.*;

        while (true) {
            if (future.poll(&ex)) {
                return;
            } else |e| switch (e) {
                futures.Pending => {},
                else => {
                    std.log.err("SingleBlockingExecutor future failed: {s}\n", .{@errorName(e)});
                },
            }
        }
    }

    pub fn createFuture(self: *SingleBlockingExecutor, FT: type) !*FT {
        std.debug.assert(self.future == null);
        return try self.inner_allocator.create(FT);
    }

    pub fn destroyFuture(self: *SingleBlockingExecutor, future: anytype) void {
        return self.inner_allocator.destroy(future);
    }

    pub fn executor(self: *SingleBlockingExecutor) Executor {
        return .{
            .ptr = self,
            .vtable = &.{
                //.zawait = zawait,
                .allocator = allocator,
            },
        };
    }
};

// This is a demonstration executor.
pub const LinearExecutor = struct {
    alloc: Allocator,
    // Reminder: No lifetimes -> not complex (right now), in the future the Executor should own the futures.
    tasks: std.ArrayListUnmanaged(*Future(void)),

    fn zawait(ctx: *anyopaque, future: *Future(void)) void {
        var self: *LinearExecutor = @alignCast(@ptrCast(ctx));
        return self.blockOn(future);
    }

    fn allocator(ctx: *const anyopaque) Allocator {
        const self: *const LinearExecutor = @alignCast(@ptrCast(ctx));
        return self.alloc;
    }

    // This is a demo function, normally a part of the implementation
    pub fn run(self: *LinearExecutor) void {
        var ex = self.executor();

        while (self.tasks.items.len != 0) {
            for (0..self.tasks.items.len) |i| {
                var future = self.tasks.items[i];

                if (future.poll(&ex)) {
                    _ = self.tasks.swapRemove(i);
                    break;
                } else |e| {
                    switch (e) {
                        futures.Pending => {
                            continue;
                        },
                        else => {
                            std.log.err("LinearExecutor future failed: {s}\n", .{@errorName(e)});
                        },
                    }
                }
            }
        }
    }

    pub fn init(alloc: Allocator) LinearExecutor {
        return .{
            .alloc = alloc,
            .tasks = .empty,
        };
    }

    // Passes ownership of futs
    pub fn initWithFutures(alloc: Allocator, futs: []*Future(void)) LinearExecutor {
        std.debug.assert(futures.len != 0);
        return .{
            .alloc = alloc,
            .tasks = .fromOwnedSlice(futs),
        };
    }

    pub fn deinit(self: *LinearExecutor) void {
        self.tasks.deinit(self.alloc);
    }

    pub fn pushFuture(self: *LinearExecutor, future: *Future(void)) !void {
        try self.tasks.append(self.alloc, future);
    }

    pub fn blockOn(self: *LinearExecutor, future: *Future(void)) void {
        while (true) {
            future.poll(self.executor()) catch |e| switch (e) {
                futures.Pending => {},
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
                //.zawait = zawait,
                .allocator = allocator,
            },
        };
    }
};
