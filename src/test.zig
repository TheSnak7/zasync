const std = @import("std");
const zasync = @import("zasync");
const Future = zasync.Future;
const FutureState = zasync.FutureState;
const EternalFuture = zasync.EternalFuture;
const Executor = zasync.Executor;
const SingleBlockingExecutor = zasync.SingleBlockingExecutor;
const NullExecutor = zasync.NullExecutor;
const examples = @import("zasync_examples");
test "EternalFuture" {
    var eternal = EternalFuture.init();
    var fut = eternal.future();

    var ex = NullExecutor.executor();

    for (0..20) |_| {
        fut.poll(&ex) catch |e| switch (e) {
            FutureState.Pending => {},
            else => {
                return error.WrongFutureState;
            },
        };
    }
}

const CountingFuture = struct {
    counter: u32,
    max: u32,

    fn poll(ctx: *anyopaque, _: *Executor) FutureState!void {
        var self: *CountingFuture = @alignCast(@ptrCast(ctx));

        if (self.counter < self.max) {
            self.counter += 1;
            return FutureState.Pending;
        } else {
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

test "CountingFuture" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const gpa_alloc = gpa.allocator();

    var sbe = SingleBlockingExecutor.init(gpa_alloc);
    defer sbe.deinit();

    var counting_future = try sbe.createFuture(CountingFuture);
    defer sbe.destroyFuture(counting_future);

    counting_future.* = CountingFuture.init(10);
    var fut = counting_future.future();

    sbe.blockOn(&fut);
}

test "Interleaved counting" {
    try examples.interleaved_counting_main();
}
