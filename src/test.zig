const std = @import("std");
const zasync = @import("zasync");
const Future = zasync.Future;
const EternalFuture = zasync.EternalFuture;
const Executor = zasync.Executor;
const SingleBlockingExecutor = zasync.SingleBlockingExecutor;

test "EternalFuture" {
    var eternal = EternalFuture.init();
    var fut = eternal.future();

    for (0..20) |_| {
        fut.poll() catch |e| switch (e) {
            Future.Pending => {},
            else => {
                return error.WrongFutureState;
            },
        };
    }
}

const CountingFuture = struct {
    counter: u32,
    max: u32,

    fn poll(ctx: *anyopaque) Future.State!void {
        var self: *CountingFuture = @alignCast(@ptrCast(ctx));

        if (self.counter < self.max) {
            self.counter += 1;
            std.debug.print("\nIncremented counter: {}", .{self.counter});
            return Future.Pending;
        } else {
            return Future.Ready;
        }
    }

    pub fn init(max: u32) CountingFuture {
        return .{
            .counter = 0,
            .max = max,
        };
    }

    pub fn future(self: *CountingFuture) Future {
        return .{
            .ptr = self,
            .vtable = &.{
                .poll = poll,
            },
        };
    }
};

test "CountingFuture" {
    var counting_future = CountingFuture.init(10);
    var fut = counting_future.future();

    var sbe = SingleBlockingExecutor.init();

    sbe.blockOn(&fut);
}
