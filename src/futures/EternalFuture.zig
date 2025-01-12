const futures = @import("../futures.zig");
const Future = futures.Future;
const Executor = @import("../executor.zig");

const EternalFuture = @This();

fn poll(_: *anyopaque, _: *Executor) futures.State!void {
    return futures.Pending;
}

fn cancel(_: *anyopaque) void {
    return;
}

pub fn init() EternalFuture {
    return .{};
}

pub fn future(self: *EternalFuture) Future(void) {
    return .{
        .ptr = self,
        .vtable = &.{
            .poll = poll,
            .cancel = cancel,
        },
        .is_owner = futures.Owner,
    };
}
