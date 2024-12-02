const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

var input = @embedFile("day2.txt");
var input_test = @embedFile("day2_test.txt");

// You could SIMD or MPI the sh-t out of this!
// Just compute the derivative and apply the rules.
fn day2(data: []const u8) !u64 {
    var lines = std.mem.splitSequence(u8, data, "\n");

    var acc: u64 = 0;

    line: while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        var levels = std.mem.splitSequence(u8, line, " ");
        var last: ?i64 = null;
        var last_diff: i64 = 0;
        while (levels.next()) |level| {
            const l = try std.fmt.parseInt(i64, level, 10);

            // First char
            if (last == null) {
                last = l;
                continue;
            }

            // Second char or after
            const diff = l - last.?;

            // Rule: The levels are either all increasing or all decreasing.
            if (diff * last_diff < 0) {
                // Invalid
                continue :line;
            }

            // Rule: Any two adjacent levels differ by at least one and at most three.
            if (@abs(diff) > 3 or @abs(diff) == 0) {
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
    var lines = std.mem.splitSequence(u8, data, "\n");

    var acc: u64 = 0;

    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        var lvls = std.mem.splitSequence(u8, line, " ");

        // Read everything
        var levels = try std.ArrayList(i64).initCapacity(allocator, 10);
        defer levels.deinit();
        while (lvls.next()) |level| {
            const l = try std.fmt.parseInt(i64, level, 10);
            try levels.append(l);
        }

        // Loop over with skipping 1 level if needed
        skip: for (0..levels.items.len + 1) |skip_it| {
            var last: ?i64 = null;
            var last_diff: i64 = 0;

            for (0.., levels.items) |idx, l| {
                if (skip_it == idx) {
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
}

test "day2" {
    const result = try day2(input_test);
    std.debug.print("result: {}\n", .{result});
    try std.testing.expect(result == 2);
}

test "day2p2" {
    const result = try day2p2(input_test);
    std.debug.print("result: {}\n", .{result});
    try std.testing.expect(result == 4);
}
