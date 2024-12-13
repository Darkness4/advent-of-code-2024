const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day05.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day05_test.txt"), "\n");

const max_len = 100;

/// scanNumber scans a number in a string. Much more efficient than std.fmt.parseInt
/// since we ignore '-' and other characters that could define a number (like hex, etc...).
/// A very naive implementation, yet the fastest for Advent of Code.
fn scanNumber(comptime T: type, data: []const u8, idx: *T) ?T {
    var number: ?T = null;
    if (idx.* >= data.len) return number;
    var char = data[@intCast(idx.*)];
    while (char >= '0' and char <= '9') {
        const v = char - '0';
        number = if (number == null) v else number.? * 10 + (char - '0');
        idx.* += 1;
        if (idx.* >= data.len) break;
        char = data[@intCast(idx.*)];
    }
    return number;
}

fn day05(data: []const u8) !u64 {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var rules = [_][max_len]bool{
        [_]bool{false} ** max_len,
    } ** max_len;

    // Read first section.
    while (lines.next()) |line| {
        if (line.len == 0) break;

        var idx: usize = 0;
        const k = scanNumber(usize, line, &idx) orelse unreachable;
        idx += 1;
        const v = scanNumber(usize, line, &idx) orelse unreachable;
        rules[k][v] = true;
    }

    // Read second section.
    var acc: u64 = 0;
    var pages = std.BoundedArray(usize, 25){};
    while (lines.next()) |line| {
        defer pages.clear();

        // Read everything
        var idx: usize = 0;
        while (idx < line.len) : (idx += 1) {
            const n = scanNumber(usize, line, &idx) orelse unreachable;
            pages.appendAssumeCapacity(n);
        }
        const pages_slice = pages.slice();

        var is_valid = true;
        // For each items
        check_constraints: for (
            0..,
            pages_slice,
        ) |cursor, i| {
            // Check if the items before the cursor are supposed to be after the current item.
            for (pages_slice[0..cursor]) |j| {
                if (rules[i][j]) {
                    is_valid = false;
                    break :check_constraints;
                }
            }
        }

        if (is_valid) {
            const mid_idx = pages_slice.len / 2;
            acc += pages_slice[mid_idx];
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
        const k = scanNumber(usize, line, &idx) orelse unreachable;
        idx += 1;
        const v = scanNumber(usize, line, &idx) orelse unreachable;
        rules[k][v] = true;
    }

    // Read second section.
    var acc: u64 = 0;
    var pages = std.BoundedArray(usize, 25){};
    while (lines.next()) |line| {
        defer pages.clear();

        // Read everything
        var idx: usize = 0;
        while (idx < line.len) : (idx += 1) {
            const n = scanNumber(usize, line, &idx) orelse unreachable;
            pages.appendAssumeCapacity(n);
        }
        const pages_slice = pages.slice();

        var is_valid = false;
        // Flag to add the middle element at the end of the resolution.
        var was_invalid = false;
        redo: while (!is_valid) {
            is_valid = true;
            // For each items
            for (0.., pages_slice) |cursor, i| {
                // Check if the items before the cursor are supposed to be after the current item.
                for (0.., pages_slice[0..cursor]) |j_idx, j| {
                    if (rules[i][j]) {
                        is_valid = false;
                        was_invalid = true;
                        // Pop the item before i and insert it after i (at the end).
                        const item = j;
                        std.mem.copyForwards(usize, pages_slice[j_idx..], pages_slice[j_idx + 1 ..]);
                        pages_slice[pages_slice.len - 1] = item;
                        continue :redo;
                    }
                }
            }

            if (was_invalid) {
                const mid_idx = pages_slice.len / 2;
                acc += pages_slice[mid_idx];
            }
        }
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day05(input);
    const p1_time = timer.lap();
    const result_p2 = try day5p2(input);
    const p2_time = timer.read();
    std.debug.print("day05 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day05 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day05 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day05(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day05 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day5p2(input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day05" {
    const result = try day05(input_test);
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
