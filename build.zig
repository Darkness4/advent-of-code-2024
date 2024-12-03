const std = @import("std");

// Learn: https://ziglang.org/learn/build-system/
// Ref: https://ziglang.org/documentation/master/#Zig-Build-System/
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseFast,
    });

    const zbench_module = b.dependency("zbench", .{ .target = target, .optimize = optimize }).module("zbench");

    const days = [_][]const u8{
        "day1",
        "day2",
        "day3",
    };

    const test_run = b.step("test", "Run unit tests");
    const all_run = b.step("all", "Run all");

    var day_run_desc_buf: [24]u8 = undefined;
    var source_path_buf: [24]u8 = undefined;
    for (days) |day| {
        const source_path = b.path(try std.fmt.bufPrint(&source_path_buf, "src/{s}.zig", .{day}));
        const day_exe = b.addExecutable(.{
            .name = day,
            .root_source_file = source_path,
            .target = target,
            .optimize = optimize,
        });
        day_exe.root_module.addImport("zbench", zbench_module);
        const day_run = b.step(day, try std.fmt.bufPrint(&day_run_desc_buf, "Run {s}", .{day}));
        b.installArtifact(day_exe);
        day_run.dependOn(&(b.addRunArtifact(day_exe)).step);
        all_run.dependOn(day_run);

        const day_test = b.addTest(.{
            .name = day,
            .root_source_file = source_path,
            .target = target,
            .optimize = optimize,
        });
        day_test.root_module.addImport("zbench", zbench_module);
        test_run.dependOn(&(b.addRunArtifact(day_test)).step);
    }
}
