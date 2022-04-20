const std = @import("std");

const web_install_dir = std.build.InstallDir{ .custom = "www" };

pub fn build(b: *std.build.Builder) void {
    const target = std.zig.CrossTarget{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
        .abi = .none,
    };
    const mode = b.standardReleaseOptions();

    const web_pkg = std.build.Pkg{
        .name = "mach-web",
        .path = .{ .path = "src/main.zig" },
    };

    // Examples
    inline for (.{"basic"}) |example| {
        const lib = b.addSharedLibrary("web", "src/main.zig", .unversioned);
        lib.setBuildMode(mode);
        lib.setTarget(target);
        lib.addPackage(.{
            .name = "app",
            .path = .{ .path = "examples/" ++ example ++ "/main.zig" },
            .dependencies = &.{web_pkg},
        });
        lib.install();
        lib.install_step.?.dest_dir = web_install_dir;

        // Files to install
        inline for (.{ "src/application.js", "www/application.html" }) |file| {
            const file_install_step = b.addInstallFileWithDir(
                .{ .path = thisDir() ++ "/" ++ file },
                web_install_dir,
                std.fs.path.basename(file),
            );
            lib.install_step.?.step.dependOn(&file_install_step.step);
        }

        const make_step = b.step("make-" ++ example, "Build the " ++ example ++ " example");
        make_step.dependOn(&lib.install_step.?.step);
    }

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
