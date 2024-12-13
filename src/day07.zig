const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day07.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day07_test.txt"), "\n");

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

/// Resolve the operators of the equation.
///
/// 'with_concat' is only used for part 2. It allows to test if we can concatenate two numbers.
fn resolve(expected: usize, equation: []usize, idx: usize, with_concat: bool) !void {
    if (idx == 0) {
        if (expected == equation[idx]) {
            return;
        }

        return error.InvalidEquation;
    }
    // Test if divisible. If so, branch it off and test both '-', 'split' and '/' hypothesis.
    if (expected % equation[idx] == 0) {
        const new_expected = expected / equation[idx];
        blk: {
            resolve(new_expected, equation, idx - 1, with_concat) catch {
                // Hypothesis '/' failed, so we try with 'split'.
                break :blk;
            };
            return;
        }
    }

    // Test if we can concatenate the two numbers.
    if (with_concat and numberEndsWith(usize, expected, equation[idx])) {
        const new_expected = mustRemoveEndsWith(usize, expected, equation[idx]);
        blk: {
            resolve(new_expected, equation, idx - 1, with_concat) catch {
                // Hypothesis 'split' failed, so we try with '-'.
                break :blk;
            };
            return;
        }
    }

    const new_expected, const overflow: u1 = @subWithOverflow(expected, equation[idx]);
    if (overflow == 1) { // The equation is not correct
        return error.InvalidEquation;
    }
    return resolve(new_expected, equation, idx - 1, with_concat);
}

fn day07(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var buffer: [31 * @sizeOf(usize)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var equation = try std.ArrayList(usize).initCapacity(allocator, 30);
    defer equation.deinit();

    var acc: usize = 0;

    equations: while (lines.next()) |line| {
        equation.clearRetainingCapacity();
        var scan_idx: usize = 0;
        const result = scanNumber(usize, line, &scan_idx) orelse unreachable;
        scan_idx += 2;

        // Read everything
        while (scanNumber(usize, line, &scan_idx)) |item| : (scan_idx += 1) {
            equation.appendAssumeCapacity(item);
        }

        // Read in reverse to be able to test values!
        // Since equation is evaluated left-to-right. To "resolve" the equation, we need to
        // read it right-to-left.
        resolve(result, equation.items, equation.items.len - 1, false) catch {
            continue :equations;
        };
        acc += result;
    }

    return acc;
}

fn numberEndsWith(comptime T: type, haystack: T, needle: T) bool {
    var divisor: T = 1;
    var temp_ending = needle;
    while (temp_ending > 0) : (temp_ending /= 10) {
        divisor *= 10;
    }
    return haystack % divisor == needle;
}

test "numberEndsWith" {
    const result = numberEndsWith(usize, 123456, 56);
    const expect = true;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };

    const result2 = numberEndsWith(usize, 123456, 57);
    const expect2 = false;
    std.testing.expect(result2 == expect2) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result2, expect2 });
        return err;
    };
}

fn mustRemoveEndsWith(comptime T: type, haystack: T, needle: T) T {
    var divisor: T = 1;
    var temp_ending = needle;
    while (temp_ending > 0) : (temp_ending /= 10) {
        divisor *= 10;
    }
    if (haystack % divisor != needle) {
        unreachable;
    }
    return haystack / divisor;
}

test "removeEndsWith" {
    const result = mustRemoveEndsWith(usize, 123456, 56);
    const expect = 1234;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

fn day07p2(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var buffer: [31 * @sizeOf(usize)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var equation = try std.ArrayList(usize).initCapacity(allocator, 30);
    defer equation.deinit();

    var acc: usize = 0;

    equations: while (lines.next()) |line| {
        equation.clearRetainingCapacity();
        var scan_idx: usize = 0;
        const result = scanNumber(usize, line, &scan_idx) orelse unreachable;
        scan_idx += 2;

        // Read everything
        while (scanNumber(usize, line, &scan_idx)) |item| : (scan_idx += 1) {
            equation.appendAssumeCapacity(item);
        }

        // Read in reverse to be able to test values!
        // Since equation is evaluated left-to-right. To "resolve" the equation, we need to
        // read it right-to-left.
        resolve(result, equation.items, equation.items.len - 1, true) catch {
            continue :equations;
        };
        acc += result;
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day07(input);
    const p1_time = timer.lap();
    const result_p2 = try day07p2(input);
    const p2_time = timer.read();
    std.debug.print("day07 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day07 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day07 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day07(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day07 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day07p2(input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day07" {
    const result = try day07(input_test);
    const expect = 3749;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day07p2" {
    const result = try day07p2(input_test);
    const expect = 11387;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
