const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zasync = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
    });

    {
        const zasync_test = b.addTest(.{
            .name = "zasynctest",
            .root_source_file = b.path("src/test.zig"),
            .target = target,
            .optimize = optimize,
        });

        zasync_test.root_module.addImport("zasync", zasync);

        const test_step = b.step("test", "Run tests");
        test_step.dependOn(&b.addRunArtifact(zasync_test).step);
    }
}
