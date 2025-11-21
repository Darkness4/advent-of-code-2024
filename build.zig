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
        "day01",
        "day02",
        "day03",
        "day04",
        "day05",
        "day06",
        "day07",
        "day08",
        "day09",
        "day10",
        "day11",
        "day12",
        "day13",
        "day14",
        "day15",
        "day16",
        "day17",
        "day18",
        "day19",
        "day20",
    };

    const test_run = b.step("test", "Run unit tests");
    const all_run = b.step("all", "Run all");

    var day_run_desc_buf: [24]u8 = undefined;
    var source_path_buf: [24]u8 = undefined;
    for (days) |day| {
        const mod = b.createModule(.{
            .root_source_file = b.path(try std.fmt.bufPrint(&source_path_buf, "src/{s}.zig", .{day})),
            .optimize = optimize,
            .target = target,
        });
        const day_exe = b.addExecutable(.{
            .name = day,
            .root_module = mod,
        });
        day_exe.root_module.addImport("zbench", zbench_module);
        const day_run = b.step(day, try std.fmt.bufPrint(&day_run_desc_buf, "Run {s}", .{day}));
        b.installArtifact(day_exe);
        day_run.dependOn(&(b.addRunArtifact(day_exe)).step);
        all_run.dependOn(day_run);

        const day_test = b.addTest(.{
            .name = day,
            .root_module = day_exe.root_module,
        });
        day_test.root_module.addImport("zbench", zbench_module);
        test_run.dependOn(&(b.addRunArtifact(day_test)).step);
    }
}
