const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day19.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day19_test.txt"), "\n");

fn is_possible(
    allocator: std.mem.Allocator,
    cache: *std.StringHashMap(bool),
    patterns: [][]const u8,
    elem: []const u8,
) !bool {
    if (cache.get(elem)) |value| {
        return value;
    }

    // Elem has every fragment.
    if (elem.len == 0) {
        try cache.put(elem, true);
        return true;
    }

    var res = false;
    for (patterns) |pattern| {
        if (std.mem.startsWith(u8, elem, pattern)) {
            const remaining = elem[pattern.len..];
            res = res or try is_possible(allocator, cache, patterns, remaining);
            if (res) break;
        }
    }

    try cache.put(elem, res);
    return res;
}

fn day19(allocator: std.mem.Allocator, data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    const pattern_line = lines.next() orelse unreachable;
    var patterns_it = std.mem.splitSequence(u8, pattern_line, ", ");

    var patterns_list = std.BoundedArray([]const u8, 500){};
    while (patterns_it.next()) |line| {
        patterns_list.appendAssumeCapacity(line);
    }
    const patterns = patterns_list.slice();

    var cache = std.StringHashMap(bool).init(allocator);
    defer cache.deinit();

    _ = lines.next() orelse unreachable;

    var acc: usize = 0;
    while (lines.next()) |line| {
        const possible = try is_possible(allocator, &cache, patterns, line);
        acc += if (possible) 1 else 0;
    }

    return acc;
}

fn count(
    allocator: std.mem.Allocator,
    cache: *std.StringHashMap(usize),
    patterns: [][]const u8,
    elem: []const u8,
) !usize {
    if (cache.get(elem)) |value| {
        return value;
    }

    // Elem has every fragment.
    if (elem.len == 0) {
        try cache.put(elem, 1);
        return 1;
    }

    var total: usize = 0;
    for (patterns) |pattern| {
        if (std.mem.startsWith(u8, elem, pattern)) {
            const remaining = elem[pattern.len..];
            total += try count(allocator, cache, patterns, remaining);
        }
    }

    try cache.put(elem, total);
    return total;
}

fn day19p2(allocator: std.mem.Allocator, data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    const pattern_line = lines.next() orelse unreachable;
    var patterns_it = std.mem.splitSequence(u8, pattern_line, ", ");

    var patterns_list = std.BoundedArray([]const u8, 500){};
    while (patterns_it.next()) |line| {
        patterns_list.appendAssumeCapacity(line);
    }
    const patterns = patterns_list.slice();

    var cache = std.StringHashMap(usize).init(allocator);
    defer cache.deinit();

    _ = lines.next() orelse unreachable;

    var acc: usize = 0;
    while (lines.next()) |line| {
        const c = try count(allocator, &cache, patterns, line);
        acc += c;
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day19(std.heap.page_allocator, input);
    const p1_time = timer.lap();
    const result_p2 = try day19p2(std.heap.page_allocator, input);
    const p2_time = timer.read();
    std.debug.print("day19 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day19 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{
        .track_allocations = true,
    });
    defer bench.deinit();
    try bench.add("day19 p1", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day19(allocator, input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day19 p2", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day19p2(allocator, input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day19" {
    const result = try day19(std.heap.page_allocator, input_test);
    const expect = 6;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day19p2" {
    const result = try day19p2(std.heap.page_allocator, input_test);
    const expect = 16;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
