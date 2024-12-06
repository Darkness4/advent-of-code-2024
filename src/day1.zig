const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day1.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day1_test.txt"), "\n");

/// scanNumber scans a number in a string. Much more efficient than std.fmt.parseInt
/// since we ignore '-' and other characters that could define a number (like hex, etc...).
/// A very naive implementation, yet the fastest for Advent of Code.
fn scanNumber(comptime T: type, data: []const u8, idx: *T) ?T {
    var number: ?T = null;
    if (idx.* >= data.len) return number;
    var char = data[@as(usize, @intCast(idx.*))];
    while (char >= '0' and char <= '9') {
        const v = char - '0';
        number = if (number == null) v else number.? * 10 + (char - '0');
        idx.* += 1;
        if (idx.* >= data.len) break;
        char = data[@as(usize, @intCast(idx.*))];
    }
    return number;
}

fn day1(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var list_a: [1000]usize = undefined;
    var list_b: [1000]usize = undefined;

    // Read two columns of numbers
    var idx: usize = 0;
    while (lines.next()) |line| : (idx += 1) {
        var ch_idx: usize = 0;
        list_a[idx] = scanNumber(usize, line, &ch_idx) orelse unreachable;
        ch_idx += 3;
        list_b[idx] = scanNumber(usize, line, &ch_idx) orelse unreachable;
    }
    const cap = idx;
    const slice_a = list_a[0..cap];
    const slice_b = list_b[0..cap];

    // Sort the lists (using pdq, which is used by Go)
    std.sort.pdq(usize, slice_a, {}, comptime std.sort.asc(usize));
    std.sort.pdq(usize, slice_b, {}, comptime std.sort.asc(usize));

    // Compute the distance
    var acc: usize = 0;
    for (list_a, list_b) |a, b| {
        acc += absSub(a, b);
    }

    return acc;
}

fn absSub(a: usize, b: usize) usize {
    if (a > b) return a - b;
    return b - a;
}

fn day1p2(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var list_a: [1000]usize = undefined;
    var occurrences = [_]usize{0} ** 100000;

    // Read two columns of numbers
    var idx: usize = 0;
    while (lines.next()) |line| : (idx += 1) {
        var ch_idx: usize = 0;
        const a = scanNumber(usize, line, &ch_idx) orelse unreachable;
        ch_idx += 3;
        const b = scanNumber(usize, line, &ch_idx) orelse unreachable;
        list_a[idx] = a;
        occurrences[b] += 1;
    }
    const cap = idx;

    // Compute similarity
    var acc: usize = 0;
    for (list_a[0..cap]) |a| {
        acc += a * occurrences[a];
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

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day1 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day1(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day1 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day1p2(input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day1" {
    const result = try day1(input_test);
    const expect = 11;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day1p2" {
    const result = try day1p2(input_test);
    const expect = 31;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
