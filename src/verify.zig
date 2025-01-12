const std = @import("std");
const futures = @import("futures.zig");
const Future = futures.Future;

pub fn assertPointerToFuture(arg: type) void {
    const info = @typeInfo(arg);

    switch (info) {
        .pointer => |p| {
            if (!@hasDecl(p.child, "Output")) {
                @compileError("Future must have an Output decl with the Output type");
            }
            const output = p.child.Output;
            if (!(p.child == Future(output))) {
                @compileError("Expected " ++ @typeName(output) ++ " but got " ++ @typeName(p.child));
            }
        },
        else => @compileError("Tried to pass a non-pointer to function: " ++ @typeName(arg) ++ ". Futures must be passed by mutable pointer"),
    }
}
