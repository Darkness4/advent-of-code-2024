const std = @import("std");

var input = @embedFile("day1.txt");
var input_test1 = @embedFile("day1p1_test.txt");
var input_test2 = @embedFile("day1p2_test.txt");

fn day1(data: []const u8) !i64 {
    var lines = std.mem.splitSequence(u8, data, "\n");

    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        std.debug.print("{s}\n", .{line});
    }

    return 0;
}

fn day1p2(data: []const u8) !i64 {
    var lines = std.mem.splitSequence(u8, data, "\n");

    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        std.debug.print("{s}\n", .{line});
    }

    return 0;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day1(input);
    const p1_time = timer.lap();
    const result_p2 = try day1p2(input);
    const p2_time = timer.read();
    std.debug.print("day1 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day1 p2: {} in {}ns\n", .{ result_p2, p2_time });
}

test "day1" {
    const result = try day1(input_test1);
    try std.testing.expect(result == 0);
}

test "day1p2" {
    const result = try day1p2(input_test2);
    try std.testing.expect(result == 0);
}
