const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day4.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day4_test.txt"), "\n");

var buffer: [140 * 140 * 8 * 4 + 140]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const allocator = fba.allocator();

const Pos = struct {
    x: usize,
    y: usize,
};

const Vec2 = struct {
    x: i64,
    y: i64,
};

const dirs = [_]Vec2{
    Vec2{ .x = -1, .y = -1 },
    Vec2{ .x = -1, .y = 0 },
    Vec2{ .x = -1, .y = 1 },
    Vec2{ .x = 0, .y = -1 },
    Vec2{ .x = 0, .y = 1 },
    Vec2{ .x = 1, .y = 1 },
    Vec2{ .x = 1, .y = 0 },
    Vec2{ .x = 1, .y = -1 },
};

const mas = "MAS";

fn day4(data: []const u8) !u64 {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var rows = try std.ArrayList([]const u8).initCapacity(allocator, 140);
    defer rows.deinit();

    var x_poss = try std.ArrayList(Pos).initCapacity(allocator, 140 * 140);
    defer x_poss.deinit();

    // Read everything and store the coordinates of X
    var idx_row: usize = 0;
    while (lines.next()) |line| : (idx_row += 1) {
        for (0.., line) |idx_col, char| {
            if (char == 'X') {
                x_poss.appendAssumeCapacity(.{ .x = idx_row, .y = idx_col });
            }
        }
        rows.appendAssumeCapacity(line);
    }

    // For each X, find for each dirs if it matches MAS
    var acc: u64 = 0;
    for (x_poss.items) |x_pos| {
        dir: for (dirs) |dir| {
            // Skip if out of bounds
            const max_x = @as(i64, @intCast(x_pos.x)) + dir.x * 3;
            const max_y = @as(i64, @intCast(x_pos.y)) + dir.y * 3;
            if (max_x >= rows.items.len or max_y >= rows.items[0].len or max_x < 0 or max_y < 0) {
                continue;
            }

            for (1..4) |norm| {
                if (rows.items[@as(usize, @intCast(@as(i64, @intCast(x_pos.x)) + dir.x * @as(i64, @intCast(norm))))][@as(usize, @intCast(@as(i64, @intCast(x_pos.y)) + dir.y * @as(i64, @intCast(norm))))] != mas[norm - 1]) {
                    continue :dir;
                }
            }
            acc += 1;
        }
    }

    return acc;
}

fn day4p2(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var rows = try std.ArrayList([]const u8).initCapacity(allocator, 140);
    defer rows.deinit();

    var a_poss = try std.ArrayList(Pos).initCapacity(allocator, 140 * 140);
    defer a_poss.deinit();

    // Read everything and store the coordinates of A
    var idx_row: usize = 0;
    while (lines.next()) |line| : (idx_row += 1) {
        if (idx_row != 0 and lines.peek() != null) {
            for (0.., line) |idx_col, char| {
                if (idx_col == 0 or idx_col == line.len - 1) continue;
                if (char == 'A') {
                    a_poss.appendAssumeCapacity(.{ .x = idx_row, .y = idx_col });
                }
            }
        }
        rows.appendAssumeCapacity(line);
    }

    // For each A, find for each dirs if it matches MAS
    var acc: u64 = 0;
    for (a_poss.items) |a_pos| {
        // It must have MS  two times.
        // "/"
        const p1 = rows.items[a_pos.x - 1][a_pos.y + 1];
        const p2 = rows.items[a_pos.x + 1][a_pos.y - 1];
        // "\"
        const q1 = rows.items[a_pos.x - 1][a_pos.y - 1];
        const q2 = rows.items[a_pos.x + 1][a_pos.y + 1];
        if ((p1 == 'M' and p2 == 'S' or p1 == 'S' and p2 == 'M') and
            (q1 == 'M' and q2 == 'S' or q1 == 'S' and q2 == 'M'))
        {
            acc += 1;
        }
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day4(input);
    const p1_time = timer.lap();
    const result_p2 = try day4p2(input);
    const p2_time = timer.read();
    std.debug.print("day4 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day4 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day4 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day4(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day4 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day4p2(input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day4" {
    const result = try day4(input_test);
    const expect = 18;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day4p2" {
    const result = try day4p2(input_test);
    const expect = 9;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
