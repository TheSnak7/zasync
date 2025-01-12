const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zasync = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
    });

    const zasync_examples = b.addModule("zasync_examples", .{
        .root_source_file = b.path("examples/main.zig"),
    });

    zasync_examples.addImport("zasync", zasync);

    {
        const zasync_example = b.addExecutable(.{
            .name = "zasync_examples",
            .root_source_file = b.path("examples/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        zasync_example.root_module.addImport("zasync", zasync);

        const example_run_cmd = b.addRunArtifact(zasync_example);
        b.installArtifact(zasync_example);
        example_run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            example_run_cmd.addArgs(args);
        }

        const examples_step = b.step("example", "Run one of the example in the examples folder. (Do not specify the .zig)");
        examples_step.dependOn(&example_run_cmd.step);
    }

    {
        const zasync_test = b.addTest(.{
            .name = "zasynctest",
            .root_source_file = b.path("src/test.zig"),
            .target = target,
            .optimize = optimize,
        });

        zasync_test.root_module.addImport("zasync", zasync);
        zasync_test.root_module.addImport("zasync_examples", zasync_examples);

        const test_step = b.step("test", "Run tests");
        test_step.dependOn(&b.addRunArtifact(zasync_test).step);
    }

    {
        const zasync_check = b.addExecutable(.{
            .name = "zasync_examples",
            .root_source_file = b.path("examples/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        zasync_check.root_module.addImport("zasync", zasync);

        const check = b.step("check", "Check if foo compiles");
        check.dependOn(&zasync_check.step);
    }
}
