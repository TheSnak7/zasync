const std = @import("std");
const zasync = @import("zasync");
const Future = zasync.Future;
const FutureState = zasync.FutureState;
const EternalFuture = zasync.EternalFuture;
const Executor = zasync.Executor;
const LinearExecutor = zasync.LinearExecutor;

const CountingFuture = struct {
    counter: u32,
    max: u32,

    fn poll(ctx: *anyopaque, _: *Executor) FutureState!void {
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

    pub fn init(start: u32, end: u32) CountingFuture {
        return .{
            .counter = start,
            .max = end,
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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const gpa_alloc = gpa.allocator();

    var small_cf = CountingFuture.init(0, 10);
    var small_fut = small_cf.future();

    var large_cf = CountingFuture.init(100, 110);
    var large_fut = large_cf.future();

    var le = LinearExecutor.init(gpa_alloc);
    defer le.deinit();

    try le.pushFuture(&small_fut);
    try le.pushFuture(&large_fut);
    le.run();
}
