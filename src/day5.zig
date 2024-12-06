const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day5.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day5_test.txt"), "\n");

var buffer: [26 * 8]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const allocator = fba.allocator();
const max_len = 100;

// scanner from day3
fn scanNumber(data: []const u8, idx: *usize) usize {
    var number: usize = 0;
    if (idx.* >= data.len) return number;
    var char = data[idx.*];
    while (char >= '0' and char <= '9') {
        number = number * 10 + (char - '0');
        next(data, idx) catch return number;
        char = data[idx.*];
    }
    return number;
}

fn next(data: []const u8, idx: *usize) !void {
    idx.* += 1;
    if (idx.* >= data.len) return error.EOF;
}

fn day5(data: []const u8) !u64 {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var rules = [_][max_len]bool{
        [_]bool{false} ** max_len,
    } ** max_len;

    // Read first section.
    while (lines.next()) |line| {
        if (line.len == 0) break;

        var idx: usize = 0;
        const k = scanNumber(line, &idx);
        try next(line, &idx);
        const v = scanNumber(line, &idx);
        rules[k][v] = true;
    }

    // Read second section.
    var acc: u64 = 0;
    var parsed_nums = try std.ArrayList(usize).initCapacity(allocator, 25);
    defer parsed_nums.deinit();
    while (lines.next()) |line| {
        defer parsed_nums.clearRetainingCapacity();

        // Read everything
        var idx: usize = 0;
        while (idx < line.len) : (idx += 1) {
            const n = scanNumber(line, &idx);
            try parsed_nums.append(n);
        }

        var is_valid = true;
        // For each items
        check_constraints: for (
            0..,
            parsed_nums.items,
        ) |cursor, i| {
            // Check if the items before the cursor are supposed to be after the current item.
            for (parsed_nums.items[0..cursor]) |j| {
                if (rules[i][j]) {
                    is_valid = false;
                    break :check_constraints;
                }
            }
        }

        if (is_valid) {
            const mid_idx = parsed_nums.items.len / 2;
            acc += parsed_nums.items[mid_idx];
        }
    }

    return acc;
}

fn day5p2(data: []const u8) !u64 {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var rules = [_][max_len]bool{
        [_]bool{false} ** max_len,
    } ** max_len;

    // Read first section.
    while (lines.next()) |line| {
        if (line.len == 0) break;

        var idx: usize = 0;
        const k = scanNumber(line, &idx);
        try next(line, &idx);
        const v = scanNumber(line, &idx);
        rules[k][v] = true;
    }

    // Read second section.
    var acc: u64 = 0;
    var parsed_nums = try std.ArrayList(usize).initCapacity(allocator, 25);
    defer parsed_nums.deinit();
    while (lines.next()) |line| {
        defer parsed_nums.clearRetainingCapacity();

        // Read everything
        var idx: usize = 0;
        while (idx < line.len) : (idx += 1) {
            const n = scanNumber(line, &idx);
            try parsed_nums.append(n);
        }

        // For each items
        var is_valid = true;
        check_constraints: for (
            0..,
            parsed_nums.items,
        ) |cursor, i| {
            // Check if the items before the cursor are supposed to be after the current item.
            for (parsed_nums.items[0..cursor]) |j| {
                if (rules[i][j]) {
                    is_valid = false;
                    break :check_constraints;
                }
            }
        }

        if (!is_valid) {
            // Sort
            fix(usize, parsed_nums.items, rules);

            const mid_idx = parsed_nums.items.len / 2;
            acc += parsed_nums.items[mid_idx];
        }
    }

    return acc;
}

// Solve by moving the items that are not valid.
fn fix(comptime T: type, items: []T, rules: [max_len][max_len]bool) void {
    var is_valid = false;
    while (!is_valid) {
        // For each items
        check_constraints: for (
            0..,
            items,
        ) |cursor, i| {
            // Check if the items before the cursor are supposed to be after the current item.
            for (0.., items[0..cursor]) |j_idx, j| {
                if (rules[i][j]) {
                    // j is supposed to be after i
                    // Pop and append j
                    is_valid = false;
                    const item = j;
                    std.mem.copyForwards(T, items[j_idx..], items[j_idx + 1 ..]);
                    items[items.len - 1] = item;
                    break :check_constraints;
                }
            }
            is_valid = true;
        }
    }
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day5(input);
    const p1_time = timer.lap();
    const result_p2 = try day5p2(input);
    const p2_time = timer.read();
    std.debug.print("day5 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day5 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day5 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day5(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day5 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day5p2(input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day5" {
    const result = try day5(input_test);
    const expect = 143;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day5p2" {
    const result = try day5p2(input_test);
    const expect = 123;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
