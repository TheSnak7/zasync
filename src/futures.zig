const std = @import("std");
const builtin = @import("builtin");

const extr = @import("executor.zig");
const Executor = extr.Executor;

pub const State = error{Pending};

pub const Pending = error.Pending;

pub const Owner = if (builtin.mode == .Debug) true else void;

pub fn Future(output: type) type {
    return struct {
        const Self = @This();
        pub const Output = output;

        ptr: *anyopaque,
        vtable: *const VTable,

        is_owner: if (builtin.mode == .Debug) bool else void,

        pub const VTable = struct {
            poll: *const fn (ctx: *anyopaque, ex: *Executor) anyerror!Output,
            cancel: *const fn (ctx: *anyopaque) void,
        };

        pub fn poll(ctx: *Self, ex: *Executor) anyerror!Output {
            ctx.assertIsOwner();

            return try ctx.vtable.poll(ctx.ptr, ex);
        }

        pub fn setOwnerStatus(future: *Self, status: bool) void {
            if (builtin.mode == .Debug) {
                future.is_owner == status;
            }
        }

        pub fn assertIsOwner(ctx: *Self) void {
            if (builtin.mode == .Debug) {
                std.debug.assert(ctx.is_owner);
            }
        }

        // Cancellation cannot fail
        pub fn cancel(ctx: *Self) void {
            ctx.assertIsOwner();
            return try ctx.vtable.cancel(ctx.ptr);
        }
    };
}
