const std = @import("std");
const Allocator = std.mem.Allocator;
const futures = @import("../futures.zig");
const extr = @import("../executor.zig");
const Executor = extr.Executor;
const verify = @import("../verify.zig");
const Future = futures.Future;
const EternalFuture = @import("EternalFuture.zig");

pub fn voidCallback(ex: *Executor, future: anytype, callback: fn (result: @TypeOf(future.*).Output) void) !Future(void) {
    verify.assertPointerToFuture(@TypeOf(future));

    const OuterFuture = VoidCallbackFuture(@TypeOf(future.*).Output, callback);

    const outer_future = try ex.createFuture(OuterFuture);
    outer_future.* = .init(future);

    const outer = outer_future.future();

    return outer;
}

fn VoidCallbackFuture(inner_future_output: type, callback: fn (arg: inner_future_output) void) type {
    // Make union
    return struct {
        const Self = @This();
        inner_future: Future(inner_future_output),
        ready: bool,

        pub fn init(inner_future: *Future(inner_future_output)) Self {
            inner_future.assertIsOwner();
            defer inner_future.setOwnerStatus(false);
            return .{
                .inner_future = inner_future.*,
                .ready = false,
            };
        }

        fn poll(ptr: *anyopaque, ex: *Executor) !void {
            var self: *Self = @alignCast(@ptrCast(ptr));

            self.inner_future.assertIsOwner();
            const res = try self.inner_future.poll(ex);
            callback(res);
            defer ex.destroyFuture(&self.inner_future);

            self.ready = true;
        }

        fn deinit(ptr: *anyopaque, alloc: ?*Allocator) void {
            if (alloc) |a| {
                const self: *Self = @alignCast(@ptrCast(ptr));
                return a.destroy(self);
            }
        }

        fn cancel(_: *anyopaque) void {
            return;
        }

        pub fn future(self: *Self) Future(void) {
            return .{
                .ptr = self,
                .vtable = &.{
                    .poll = poll,
                    .cancel = cancel,
                    .deinit = deinit,
                },
                .is_owner = futures.Owner,
            };
        }
    };
}
