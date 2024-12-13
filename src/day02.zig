const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day02.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day02_test.txt"), "\n");

/// scanNumber scans a number in a string. Much more efficient than std.fmt.parseInt
/// since we ignore '-' and other characters that could define a number (like hex, etc...).
/// A very naive implementation, yet the fastest for Advent of Code.
fn scanNumber(comptime T: type, data: []const u8, idx: *usize) ?T {
    var number: ?T = null;
    if (idx.* >= data.len) return number;
    var char = data[idx.*];
    while (char >= '0' and char <= '9') {
        const v = char - '0';
        number = if (number == null) v else number.? * 10 + (char - '0');
        idx.* += 1;
        if (idx.* >= data.len) break;
        char = data[idx.*];
    }
    return number;
}

fn day02(data: []const u8) !u64 {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var acc: u64 = 0;

    line: while (lines.next()) |line| {
        var scan_idx: usize = 0;
        var last: i64 = scanNumber(i64, line, &scan_idx) orelse unreachable;
        scan_idx += 1;
        var last_diff: i64 = 0;
        while (scanNumber(i64, line, &scan_idx)) |l| : (scan_idx += 1) {
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

fn absSub(a: usize, b: usize) usize {
    if (a > b) return a - b;
    return b - a;
}

fn day02p2(data: []const u8) !usize {
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
    const result_p1 = try day02(input);
    const p1_time = timer.lap();
    const result_p2 = try day02p2(input);
    const p2_time = timer.read();
    std.debug.print("day02 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day02 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day02 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day02(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day02 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day02p2(input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day02" {
    const result = try day02(input_test);
    const expect = 2;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day02p2" {
    const result = try day02p2(input_test);
    const expect = 4;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
