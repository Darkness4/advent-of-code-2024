const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day2.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day2_test.txt"), "\n");

fn day2(data: []const u8) !u64 {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var acc: u64 = 0;

    line: while (lines.next()) |line| {
        var levels = std.mem.splitScalar(u8, line, ' ');
        var last: i64 = try std.fmt.parseInt(i64, levels.next().?, 10);
        var last_diff: i64 = 0;
        while (levels.next()) |level| {
            const l = try std.fmt.parseInt(i64, level, 10);

            // Second char or after
            const diff = l - last;

            // Apply rules
            if (diff * last_diff < 0 or @abs(diff) > 3 or @abs(diff) == 0) {
                // Invalid
                continue :line;
            }

            last = l;
            last_diff = diff;
        }
        acc += 1;
    }

    return acc;
}

fn day2p2(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var acc: u64 = 0;

    var levels: [10]i64 = undefined;

    while (lines.next()) |line| {
        var lvls = std.mem.splitScalar(u8, line, ' ');

        // Read everything
        var idx: usize = 0;
        while (lvls.next()) |level| : (idx += 1) {
            const l = try std.fmt.parseInt(i64, level, 10);
            levels[idx] = l;
        }
        const cap = idx;

        // Loop over with skipping 1 level
        skip: for (0..cap) |skip_it| {
            var last: ?i64 = null;
            var last_diff: i64 = 0;

            for (0.., levels[0..cap]) |i, l| {
                if (skip_it == i) {
                    continue;
                }

                if (last == null) {
                    last = l;
                    continue;
                }

                const diff = l - last.?;
                if (diff * last_diff < 0 or @abs(diff) > 3 or @abs(diff) == 0) {
                    continue :skip;
                }

                last = l;
                last_diff = diff;
            }
            acc += 1;
            break;
        }
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day2(input);
    const p1_time = timer.lap();
    const result_p2 = try day2p2(input);
    const p2_time = timer.read();
    std.debug.print("day2 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day2 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day2 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day2(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day2 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day2p2(input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day2" {
    const result = try day2(input_test);
    try std.testing.expect(result == 2);
}

test "day2p2" {
    const result = try day2p2(input_test);
    try std.testing.expect(result == 4);
}
