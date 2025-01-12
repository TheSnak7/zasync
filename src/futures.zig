const extr = @import("executor.zig");
const Executor = extr.Executor;

pub const State = error{Pending};

pub const Pending = error.Pending;

pub fn Future(output: type) type {
    return struct {
        const Self = @This();
        pub const Output = output;

        ptr: *anyopaque,
        vtable: *const VTable,

        pub const VTable = struct {
            poll: *const fn (ctx: *anyopaque, ex: *Executor) anyerror!Output,
            cancel: *const fn (ctx: *anyopaque) void,
        };

        pub fn poll(ctx: *Self, ex: *Executor) anyerror!Output {
            return try ctx.vtable.poll(ctx.ptr, ex);
        }

        // Cancellation cannot fail
        pub fn cancel(ctx: *Self) void {
            return try ctx.vtable.cancel(ctx.ptr);
        }
    };
}

pub const EternalFuture = struct {
    fn poll(_: *anyopaque, _: *Executor) State!void {
        return Pending;
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
        };
    }
};
