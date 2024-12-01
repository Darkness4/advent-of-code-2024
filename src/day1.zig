const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

var input = @embedFile("day1.txt");
var input_test = @embedFile("day1_test.txt");

fn day1(data: []const u8) !u64 {
    var lines = std.mem.splitSequence(u8, data, "\n");

    var list_a = try std.ArrayList(i64).initCapacity(allocator, 1000);
    defer list_a.deinit();

    var list_b = try std.ArrayList(i64).initCapacity(allocator, 1000);
    defer list_b.deinit();

    // Read two columns of numbers
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        var groups = std.mem.tokenizeAny(u8, line, " ");
        try list_a.append(try std.fmt.parseInt(i64, groups.next().?, 10));
        try list_b.append(try std.fmt.parseInt(i64, groups.next().?, 10));
    }

    // Sort the lists
    std.mem.sort(i64, list_a.items, {}, comptime std.sort.asc(i64));
    std.mem.sort(i64, list_b.items, {}, comptime std.sort.asc(i64));

    // Compute the distance
    var acc: u64 = 0;
    for (list_a.items, list_b.items) |a, b| {
        acc += @abs(a - b);
    }

    return acc;
}

fn day1p2(data: []const u8) !i64 {
    var lines = std.mem.splitSequence(u8, data, "\n");

    var occurences_a: [100000]i64 = [_]i64{0} ** 100000;
    var occurences_b: [100000]i64 = [_]i64{0} ** 100000;

    // Read two columns of numbers
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        var groups = std.mem.tokenizeAny(u8, line, " ");
        const a = try std.fmt.parseInt(usize, groups.next().?, 10);
        occurences_a[a] += 1;
        const b = try std.fmt.parseInt(usize, groups.next().?, 10);
        occurences_b[b] += 1;
    }

    // Compute similarity
    var acc: i64 = 0;
    for (0.., occurences_a, occurences_b) |i, a, b| {
        acc += @as(i64, @intCast(i)) * a * b;
    }

    return acc;
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
    const result = try day1(input_test);
    try std.testing.expect(result == 11);
}

test "day1p2" {
    const result = try day1p2(input_test);
    try std.testing.expect(result == 31);
}
