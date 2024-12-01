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
        list_a.appendAssumeCapacity(try std.fmt.parseInt(i64, groups.next().?, 10));
        list_b.appendAssumeCapacity(try std.fmt.parseInt(i64, groups.next().?, 10));
    }

    // Sort the lists (using pdq, which is used by Go)
    std.sort.pdq(i64, list_a.items, {}, comptime std.sort.asc(i64));
    std.sort.pdq(i64, list_b.items, {}, comptime std.sort.asc(i64));

    // Compute the distance
    var acc: u64 = 0;
    for (list_a.items, list_b.items) |a, b| {
        acc += @abs(a - b);
    }

    return acc;
}

fn day1p2(data: []const u8) !i64 {
    var lines = std.mem.splitSequence(u8, data, "\n");

    var list_a = try std.ArrayList(usize).initCapacity(allocator, 1000);
    defer list_a.deinit();

    var occurrences = [_]i64{0} ** 100000;

    // Read two columns of numbers
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        var groups = std.mem.tokenizeAny(u8, line, " ");
        const a = try std.fmt.parseInt(usize, groups.next().?, 10);
        const b = try std.fmt.parseInt(usize, groups.next().?, 10);
        list_a.appendAssumeCapacity(a);
        occurrences[b] += 1;
    }

    // Compute similarity
    var acc: i64 = 0;
    for (list_a.items) |a| {
        acc += @as(i64, @intCast(a)) * occurrences[a];
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
