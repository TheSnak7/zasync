const std = @import("std");
const zasync = @import("zasync");
const Future = zasync.Future;
const EternalFuture = zasync.EternalFuture;

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
