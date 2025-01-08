pub const Future = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const Pending = error.Pending;
    pub const Ready = error.Ready;

    pub const State = error{ Pending, Ready };

    pub const VTable = struct {
        poll: *const fn (ctx: *anyopaque) anyerror!void,
    };

    pub fn poll(ctx: *Future) anyerror!void {
        return try ctx.vtable.*.poll(ctx.ptr);
    }
};

pub const EternalFuture = struct {
    fn poll(_: *anyopaque) Future.State!void {
        return Future.Pending;
    }

    pub fn init() EternalFuture {
        return .{};
    }

    pub fn future(self: *EternalFuture) Future {
        return .{
            .ptr = self,
            .vtable = &.{
                .poll = poll,
            },
        };
    }
};
