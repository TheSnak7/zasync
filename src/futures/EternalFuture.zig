const std = @import("std");
const Allocator = std.mem.Allocator;

const futures = @import("../futures.zig");
const Future = futures.Future;
const Executor = @import("../executor.zig").Executor;

const EternalFuture = @This();

fn poll(_: *anyopaque, _: *Executor) futures.State!void {
    return futures.Pending;
}

fn cancel(_: *anyopaque) void {
    return;
}

fn deinit(ctx: *anyopaque, alloc: ?*Allocator) void {
    if (alloc) |a| {
        const self: *EternalFuture = @alignCast(@ptrCast(ctx));
        return a.destroy(self);
    }
}

pub fn init() EternalFuture {
    return .{};
}

pub fn future(self: *EternalFuture) Future(void) {
    return .{ .ptr = self, .vtable = &.{
        .poll = poll,
        .cancel = cancel,
        .deinit = deinit,
    }, .is_owner = futures.Owner };
}
