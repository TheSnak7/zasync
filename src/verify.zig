const std = @import("std");
const futures = @import("futures.zig");
const Future = futures.Future;

pub fn assertPointerToFuture(arg: type) void {
    const info = @typeInfo(arg);

    switch (info) {
        .pointer => {
            if (!@hasDecl(arg, "Output")) {
                @compileError("Future must have an Output decl with the Output type");
            }
            const output = arg.Output;
            comptime std.debug.assert(arg == Future(output));
        },
        else => @compileError("Tried to pass a non-pointer to function: " ++ @typeName(arg) ++ ". Futures must be passed by mutable pointer"),
    }
}
