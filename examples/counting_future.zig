const std = @import("std");
const zasync = @import("zasync");
const Future = zasync.Future;
const FutureState = zasync.FutureState;
const FutureOwner = zasync.FutureOwner;
const EternalFuture = zasync.EternalFuture;
const Executor = zasync.Executor;
const SingleBlockingExecutor = zasync.SingleBlockingExecutor;

const CountingFuture = struct {
    counter: u32,
    max: u32,
    // Simple future does not need a state machine
    done: bool,

    fn poll(ctx: *anyopaque, _: *Executor) FutureState!void {
        var self: *CountingFuture = @alignCast(@ptrCast(ctx));

        defer {
            if (self.done) {
                std.log.info("Finished future", .{});
            }
        }

        if (self.counter < self.max) {
            self.counter += 1;
            std.log.info("Incremented counter: {}/{}", .{ self.counter, self.max });
            return FutureState.Pending;
        } else {
            std.log.info("Returned ready: {}/{}", .{ self.counter, self.max });
            self.done = true;
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
            .done = false,
        };
    }

    pub fn future(self: *CountingFuture) Future(void) {
        return .{
            .ptr = self,
            .vtable = &.{
                .poll = poll,
                .cancel = cancel,
            },
            .is_owner = FutureOwner,
        };
    }
};

pub fn main() !void {
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
