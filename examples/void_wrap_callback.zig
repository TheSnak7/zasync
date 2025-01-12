const std = @import("std");
const Allocator = std.mem.Allocator;
const zasync = @import("zasync");
const futures = zasync.futures;
const Future = zasync.Future;
const FutureState = zasync.FutureState;
const FutureOwner = zasync.FutureOwner;
const EternalFuture = zasync.EternalFuture;
const Executor = zasync.Executor;
const SingleBlockingExecutor = zasync.SingleBlockingExecutor;

const FiveReturnFuture = struct {
    ready: bool,

    fn poll(ctx: *anyopaque, _: *Executor) FutureState!i32 {
        var self: *FiveReturnFuture = @alignCast(@ptrCast(ctx));

        if (self.ready) {
            std.log.info("Finished future", .{});
            return 5;
        } else {
            self.ready = true;
            return FutureState.Pending;
        }
    }

    fn cancel(_: *anyopaque) void {
        return;
    }

    fn deinit(ctx: *anyopaque, alloc: ?*Allocator) void {
        if (alloc) |a| {
            const self: *FiveReturnFuture = @alignCast(@ptrCast(ctx));
            return a.destroy(self);
        }
    }

    pub fn init() FiveReturnFuture {
        return .{
            .ready = false,
        };
    }

    pub fn future(self: *FiveReturnFuture) Future(i32) {
        return .{
            .ptr = self,
            .vtable = &.{
                .poll = poll,
                .cancel = cancel,
                .deinit = deinit,
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

    var ex = sbe.executor();

    var five_future = try ex.createFuture(FiveReturnFuture);
    five_future.* = FiveReturnFuture.init();

    var five_fut = five_future.future();

    var callback_wrap_fut = try futures.voidCallback(&ex, &five_fut, printNumber);

    sbe.blockOn(&callback_wrap_fut);
}

fn printNumber(num: i32) void {
    std.log.info("Inner number: {}", .{num});
}
