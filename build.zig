const std = @import("std");
const Pkg = std.build.Pkg;
const Step = std.build.Step;
const RunStep = std.build.RunStep;
const Builder = std.build.Builder;
const FileSrc = std.build.FileSource;
const InstallDir = std.build.InstallDir;

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("idl", "src/main.zig");
    exe.addPackage(Idla.pkg);
    exe.addPackage(Idpk.pkg);
    exe.addPackage(Core.pkg);
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}

const Idla = struct {
    pub const pkg = Pkg{ .name = "idla", .path = FileSrc{.path = "./lib/idla/src/main.zig"}, .dependencies = null};
};
const Idpk = struct {
    pub const pkg = Pkg{ .name = "idpkg", .path = FileSrc{.path = "./lib/idpk/src/main.zig"}, .dependencies = null};
};
const Core = struct {
    pub const pkg = Pkg{ .name = "core", .path = FileSrc{.path = "./lib/src/main.zig"}, .dependencies = null};
};
