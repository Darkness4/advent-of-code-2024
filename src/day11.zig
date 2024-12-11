const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day11.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day11_test.txt"), "\n");

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

const SplitResult = struct {
    usize,
    usize,
};

const NewOrSplitResult = struct {
    isSplit: bool,
    new: ?usize = null,
    split: ?SplitResult = null,
};

fn count_digits(number: usize) usize {
    var num = number;
    var digit_count: usize = 0;
    while (num > 0) {
        digit_count += 1;
        num /= 10;
    }
    return digit_count;
}

// split the digits in two parts
fn split(number: usize, digit_count: usize) SplitResult {
    var divisor: usize = 1;
    for (digit_count - digit_count / 2) |_| {
        divisor *= 10;
    }

    return SplitResult{
        number / divisor,
        number % divisor,
    };
}

fn blink(stone: usize) NewOrSplitResult {
    if (stone == 0) {
        return .{ .isSplit = false, .new = 1 };
    } else {
        const count_digit = count_digits(stone);
        if (count_digit % 2 == 0) {
            return .{
                .isSplit = true,
                .split = split(stone, count_digit),
            };
        } else {
            return .{ .isSplit = false, .new = stone * 2024 };
        }
    }
}

test "split" {
    const l, const r = split(123456, 6);
    const expectL, const expectR = SplitResult{ 123, 456 };
    std.testing.expect(l == expectL and r == expectR) catch |err| {
        std.debug.print("got: {}, {}, expect: {}, {}\n", .{ l, r, expectL, expectR });
        return err;
    };
}

fn doNaive(data: []const u8, count: usize) !usize {
    var list = [_]usize{0} ** 1000000;

    // Read everything
    var ch_idx: usize = 0;
    var idx: usize = 0;
    while (scanNumber(usize, data, &ch_idx)) |num| : ({
        ch_idx += 1;
        idx += 1;
    }) {
        list[idx] = num;
    }
    var size = idx;

    // std.debug.print("{any}\n", .{list[0..size]});

    for (0..count) |_| {
        var cursor: usize = 0;

        var new_size = size;
        while (cursor < size) : (cursor += 1) {
            const stone = &list[cursor];

            // Apply rules
            const res = blink(stone.*);
            if (res.isSplit) {
                const left, const right = res.split.?;
                stone.* = left;
                list[new_size] = right;
                new_size += 1;
            } else {
                stone.* = res.new.?;
            }
        }
        size = new_size;
        // std.debug.print("{any}\n", .{list[0..size]});
    }
    // std.debug.print("{any}\n", .{list[0..size]});

    return size;
}

fn printHashMap(map: std.AutoHashMap(usize, isize)) void {
    var it = map.iterator();
    while (it.next()) |entry| {
        std.debug.print("{}: {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}

// Compress the list by hashing it. A legit use case for a hashmap.
fn doWithCache(allocator: std.mem.Allocator, data: []const u8, count: usize) !usize {
    var compressed_list = std.AutoHashMap(usize, isize).init(allocator);
    defer compressed_list.deinit();

    // Read everything
    var ch_idx: usize = 0;
    while (scanNumber(usize, data, &ch_idx)) |num| : (ch_idx += 1) {
        const entry = try compressed_list.getOrPutValue(num, 0);
        entry.value_ptr.* += 1;
    }
    var staging_list = std.AutoHashMap(usize, isize).init(allocator);
    defer staging_list.deinit();

    for (0..count) |_| {
        staging_list.clearRetainingCapacity();

        var it = compressed_list.iterator();
        while (it.next()) |entry| {
            const stone = entry.key_ptr.*;

            // Apply rules
            const result = blink(stone);

            if (result.isSplit) {
                // Increase the count of left and right
                const left, const right = result.split.?;
                const left_entry = try staging_list.getOrPutValue(left, 0);
                left_entry.value_ptr.* += entry.value_ptr.*;
                const right_entry = try staging_list.getOrPutValue(right, 0);
                right_entry.value_ptr.* += entry.value_ptr.*;
            } else {
                // Increase the count of new value
                const new_entry = try staging_list.getOrPutValue(result.new.?, 0);
                new_entry.value_ptr.* += entry.value_ptr.*;
            }

            // Decrease the count of current value (immediatly as it won't impact the next iteration)
            entry.value_ptr.* = 0;
        }

        // Apply staging list to compressed list
        var stagingit = staging_list.iterator();
        while (stagingit.next()) |staging_entry| {
            const key = staging_entry.key_ptr.*;
            const value = staging_entry.value_ptr.*;
            if (value == 0) continue;

            const compressed_entry = try compressed_list.getOrPutValue(key, 0);
            compressed_entry.value_ptr.* += value;
        }
    }

    var acc: usize = 0;
    var it = compressed_list.iterator();
    while (it.next()) |entry| {
        acc += @intCast(entry.value_ptr.*);
    }
    return acc;
}

fn day11(data: []const u8) !usize {
    return doNaive(data, 25);
}

fn day11p2(allocator: std.mem.Allocator, data: []const u8) !usize {
    return doWithCache(allocator, data, 75);
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day11(input);
    const p1_time = timer.lap();
    const result_p2 = try day11p2(std.heap.page_allocator, input);
    const p2_time = timer.read();
    std.debug.print("day11 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day11 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{
        .track_allocations = true,
    });
    defer bench.deinit();
    try bench.add("day11 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day11(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day11 p2", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day11p2(allocator, input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day11" {
    const result = try day11(input_test);
    const expect = 55312;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day11p2" {
    const result = try doWithCache(std.heap.page_allocator, input_test, 25);
    const expect = 55312;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
