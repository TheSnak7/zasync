const std = @import("std");
const zasync = @import("zasync");
const Future = zasync.Future;
const FutureState = zasync.FutureState;
const EternalFuture = zasync.EternalFuture;
const Executor = zasync.Executor;
const SingleBlockingExecutor = zasync.SingleBlockingExecutor;

const CountingFuture = struct {
    counter: u32,
    max: u32,

    fn poll(ctx: *anyopaque) FutureState!void {
        var self: *CountingFuture = @alignCast(@ptrCast(ctx));

        if (self.counter < self.max) {
            self.counter += 1;
            std.debug.print("Incremented counter: {}/{}\n", .{ self.counter, self.max });
            return FutureState.Pending;
        } else {
            std.debug.print("Returned ready: {}/{}\n", .{ self.counter, self.max });
            return;
        }
    }

    fn cancel(_: *anyopaque) void {
        return;
    }

    pub fn init(max: u32) CountingFuture {
        return .{
            .counter = 0,
            .max = max,
        };
    }

    pub fn future(self: *CountingFuture) Future(void) {
        return .{
            .ptr = self,
            .vtable = &.{
                .poll = poll,
                .cancel = cancel,
            },
        };
    }
};

pub fn main() !void {
    var counting_future = CountingFuture.init(10);
    var fut = counting_future.future();

    var sbe = SingleBlockingExecutor.init();

    sbe.blockOn(&fut);
}
