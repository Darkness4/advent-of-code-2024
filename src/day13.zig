const std = @import("std");

const zbench = @import("zbench");

const input = @embedFile("day13.txt");
const input_test = @embedFile("day13_test.txt");

/// scanNumber scans a number in a string. Much more efficient than std.fmt.parseInt
/// since we ignore '-' and other characters that could define a number (like hex, etc...).
/// A very naive implementation, yet the fastest for Advent of Code.
fn scanNumber(comptime T: type, data: []const u8, idx: *usize) ?T {
    var number: ?T = null;
    if (idx.* >= data.len) return number;
    var char = data[idx.*];
    while (char >= '0' and char <= '9') {
        const v = char - '0';
        number = if (number == null) v else number.? * 10 + (char - '0');
        idx.* += 1;
        if (idx.* >= data.len) break;
        char = data[idx.*];
    }
    return number;
}

fn Pos(comptime T: type) type {
    return struct {
        x: T,
        y: T,
    };
}

fn Vec2(comptime T: type) type {
    return struct {
        x: T,
        y: T,

        pub fn eql(a: Vec2(T), b: Vec2(T)) bool {
            return a.x == b.x and a.y == b.y;
        }
    };
}

fn scanButtonLine(line: []const u8) Vec2(isize) {
    var idx: usize = comptime "Button A: X+".len;

    const x = scanNumber(isize, line, &idx) orelse unreachable;
    idx += comptime ", Y+".len;
    const y = scanNumber(isize, line, &idx) orelse unreachable;
    return .{ .x = x, .y = y };
}

test "scanButtonLine" {
    const line = "Button A: X+94, Y+34";
    const result = scanButtonLine(line);
    const expect = Vec2(isize){ .x = 94, .y = 34 };
    std.testing.expect(result.eql(expect)) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

fn scanPrizeLine(line: []const u8) Pos(isize) {
    var idx: usize = comptime "Prize: X=".len;
    const x = scanNumber(isize, line, &idx) orelse unreachable;
    idx += comptime ", Y=".len;
    const y = scanNumber(isize, line, &idx) orelse unreachable;
    return .{ .x = x, .y = y };
}

test "scanPrizeLine" {
    const line = "Prize: X=14400, Y=1768";
    const result = scanPrizeLine(line);
    const expect = Pos(isize){ .x = 14400, .y = 1768 };
    std.testing.expect(result.x == expect.x and result.y == expect.y) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

fn solve(vec_a: Vec2(isize), vec_b: Vec2(isize), prize: Pos(isize)) !isize {
    // Equation to solve:
    // a_vec.x*n + b_vec.x*m = prize.x
    // a_vec.y*n + b_vec.y*m = prize.y

    const delta = vec_a.x * vec_b.y - vec_a.y * vec_b.x;
    if (delta == 0) {
        return error.NaN;
    }

    const n = try std.math.divExact(isize, (prize.x * vec_b.y - prize.y * vec_b.x), delta);
    const m = try std.math.divExact(isize, prize.y * vec_a.x - prize.x * vec_a.y, delta);

    // Assert
    if (vec_a.x * n + vec_b.x * m != prize.x or vec_a.y * n + vec_b.y * m != prize.y) {
        unreachable;
    }

    return n * 3 + m;
}

test "solve" {
    const vec_a: Vec2(isize) = .{ .x = 94, .y = 34 };
    const vec_b: Vec2(isize) = .{ .x = 22, .y = 67 };
    const prize: Pos(isize) = .{ .x = 8400, .y = 5400 };
    const result = try solve(vec_a, vec_b, prize);
    const expect: isize = 280;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

fn day13(data: []const u8) !isize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var acc: isize = 0;
    while (lines.next()) |line| {
        const a_vec = scanButtonLine(line);
        const lineb = lines.next() orelse unreachable;
        const b_vec = scanButtonLine(lineb);
        const linec = lines.next() orelse unreachable;
        const prize = scanPrizeLine(linec);
        _ = lines.next() orelse unreachable;

        acc += solve(a_vec, b_vec, prize) catch {
            continue;
        };
    }

    return acc;
}

fn day13p2(data: []const u8) !isize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var acc: isize = 0;
    while (lines.next()) |line| {
        const a_vec = scanButtonLine(line);
        const lineb = lines.next() orelse unreachable;
        const b_vec = scanButtonLine(lineb);
        const linec = lines.next() orelse unreachable;
        var prize = scanPrizeLine(linec);
        _ = lines.next() orelse unreachable;
        prize.x += 10000000000000;
        prize.y += 10000000000000;

        acc += solve(a_vec, b_vec, prize) catch {
            continue;
        };
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day13(input);
    const p1_time = timer.lap();
    const result_p2 = try day13p2(input);
    const p2_time = timer.read();
    std.debug.print("day13 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day13 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day13 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day13(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day13 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day13p2(input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day13" {
    const result = try day13(input_test);
    const expect = 480;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
