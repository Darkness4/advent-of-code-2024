const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day1.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day1_test.txt"), "\n");

fn day1(data: []const u8) !u64 {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var list_a: [1000]i64 = undefined;
    var list_b: [1000]i64 = undefined;

    // Read two columns of numbers
    var idx: usize = 0;
    while (lines.next()) |line| : (idx += 1) {
        var groups = std.mem.splitSequence(u8, line, "   ");

        list_a[idx] = try std.fmt.parseInt(i64, groups.next().?, 10);
        list_b[idx] = try std.fmt.parseInt(i64, groups.next().?, 10);
    }
    const cap = idx;
    const slice_a = list_a[0..cap];
    const slice_b = list_b[0..cap];

    // Sort the lists (using pdq, which is used by Go)
    std.sort.pdq(i64, slice_a, {}, comptime std.sort.asc(i64));
    std.sort.pdq(i64, slice_b, {}, comptime std.sort.asc(i64));

    // Compute the distance
    var acc: u64 = 0;
    for (list_a, list_b) |a, b| {
        acc += @abs(a - b);
    }

    return acc;
}

fn day1p2(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var list_a: [1000]usize = undefined;
    var occurrences = [_]usize{0} ** 100000;

    // Read two columns of numbers
    var idx: usize = 0;
    while (lines.next()) |line| : (idx += 1) {
        var groups = std.mem.splitSequence(u8, line, "   ");
        const a = try std.fmt.parseInt(usize, groups.next().?, 10);
        const b = try std.fmt.parseInt(usize, groups.next().?, 10);
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
