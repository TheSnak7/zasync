const fut = @import("futures.zig");
const ex = @import("executor.zig");
const vc = @import("futures/void_callback.zig");

pub const Future = fut.Future;
pub const FutureState = fut.State;
pub const EternalFuture = fut.EternalFuture;
pub const FutureOwner = fut.Owner;

pub const futures = struct {
    pub const State = fut.State;
    pub const EternalFuture = fut.EternalFuture;
    pub const Owner = fut.Owner;

    pub const voidCallback = vc.voidCallback;
};

pub const Executor = ex.Executor;
pub const SingleBlockingExecutor = ex.SingleBlockingExecutor;
pub const LinearExecutor = ex.LinearExecutor;
pub const NullExecutor = ex.NullExecutor;
