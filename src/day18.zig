const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day18.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day18_test.txt"), "\n");

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

fn AutoHashSet(comptime T: type) type {
    return std.AutoHashMap(T, void);
}

fn PosOrOverflow(comptime T: type) type {
    return struct {
        pos: Pos(T),
        overflow: u1,
    };
}

fn Pos(comptime T: type) type {
    return struct {
        x: T,
        y: T,

        pub fn eql(a: Pos(T), b: Pos(T)) bool {
            return a.x == b.x and a.y == b.y;
        }

        pub fn addWithOverflow(self: Pos(T), other: Vec2(isize)) PosOrOverflow(T) {
            const x: isize = @as(isize, @intCast(self.x)) + other.x;
            const y: isize = @as(isize, @intCast(self.y)) + other.y;

            if (x < 0 or y < 0) {
                return .{
                    .pos = .{ .x = 0, .y = 0 },
                    .overflow = 1,
                };
            }

            return .{
                .pos = .{ .x = @intCast(x), .y = @intCast(y) },
                .overflow = 0,
            };
        }
    };
}

fn PosScore(comptime T: type) type {
    return struct {
        pos: Pos(T),
        score: usize,
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

// Distance from pos and end.
fn score(pos: Pos(usize), end: Pos(usize)) usize {
    return absSub(pos.x, end.x) + absSub(pos.y, end.y);
}

fn absSub(a: usize, b: usize) usize {
    return if (a > b) a - b else b - a;
}

fn astar(
    matrix: *const Matrix,
    start: Pos(usize),
    allocator: std.mem.Allocator,
) !usize {
    const end: Pos(usize) = .{ .x = matrix.total_rows - 1, .y = matrix.row_size - 1 };
    var open = std.PriorityQueue(PosScore(usize), void, struct {
        fn func(_: void, a: PosScore(usize), b: PosScore(usize)) std.math.Order {
            return std.math.order(a.score, b.score);
        }
    }.func).init(allocator, {});
    defer open.deinit();
    try open.add(.{
        .pos = start,
        .score = 0,
    });

    var best: usize = std.math.maxInt(usize);

    var actual_costs = std.AutoHashMap(Pos(usize), usize).init(allocator);
    defer actual_costs.deinit();
    try actual_costs.put(start, 0);

    var heuristics = std.AutoHashMap(Pos(usize), usize).init(allocator);
    defer heuristics.deinit();
    try heuristics.put(start, score(start, end));

    while (open.count() > 0) {
        const current = open.remove();
        const current_cost = actual_costs.get(current.pos).?;

        // Found a path to the end.
        if (current.pos.eql(end) and current_cost < best) {
            best = current_cost;
        }

        for (dirs) |dir| {
            const next_pos = current.pos.addWithOverflow(dir);
            if (next_pos.overflow == 1) continue;
            if (next_pos.pos.x >= matrix.total_rows or next_pos.pos.y >= matrix.row_size) continue;
            if (matrix.get(next_pos.pos) == '#') continue;

            const new_cost = current_cost + 1;

            if (actual_costs.get(next_pos.pos) == null or new_cost < actual_costs.get(next_pos.pos).?) {
                try actual_costs.put(next_pos.pos, new_cost);

                const heuristic = score(current.pos, end);
                try heuristics.put(next_pos.pos, current_cost + heuristic);

                try open.add(.{ .pos = next_pos.pos, .score = heuristic });
            }
        }
    }

    return best;
}

const Matrix = struct {
    data: []u8,
    row_size: usize = 0,
    total_rows: usize = 0,

    allocator: std.mem.Allocator,

    fn init(total_rows: usize, row_size: usize, allocator: std.mem.Allocator) !Matrix {
        const data = try allocator.alloc(u8, total_rows * row_size);
        @memset(data, '.');
        return Matrix{
            .data = data,
            .total_rows = total_rows,
            .row_size = row_size,
            .allocator = allocator,
        };
    }

    fn deinit(self: *Matrix) void {
        self.allocator.free(self.data);
    }

    fn get(self: *const Matrix, p: Pos(usize)) u8 {
        return self.data[self.row_size * p.x + p.y];
    }

    fn set(self: *Matrix, p: Pos(usize), value: u8) void {
        self.data[self.row_size * p.x + p.y] = value;
    }

    fn print(self: *const Matrix) void {
        for (0..self.total_rows) |x| {
            std.debug.print("{s}\n", .{self.data[self.row_size * x .. (self.row_size * x) + self.row_size]});
        }
    }
};

const dirs = [_]Vec2(isize){
    .{ .x = -1, .y = 0 }, // Up
    .{ .x = 0, .y = 1 }, // Right
    .{ .x = 1, .y = 0 }, // Down
    .{ .x = 0, .y = -1 }, // Left
};

fn day18(
    allocator: std.mem.Allocator,
    data: []const u8,
    comptime size: usize,
    comptime read_until: usize,
) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var buffer: [100 * 100 * @sizeOf(usize)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    var matrix = try Matrix.init(size, size, fba_allocator);
    defer matrix.deinit();

    // Read two columns of numbers
    var idx: usize = 0;
    while (lines.next()) |line| : (idx += 1) {
        if (idx >= read_until) break;
        var ch_idx: usize = 0;
        const a: usize = scanNumber(usize, line, &ch_idx) orelse unreachable;
        ch_idx += 1;
        const b: usize = scanNumber(usize, line, &ch_idx) orelse unreachable;
        matrix.set(.{ .x = a, .y = b }, '#');
    }

    return astar(&matrix, .{ .x = 0, .y = 0 }, allocator);
}

fn day18p2(_: []const u8) !usize {
    return 0;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day18(std.heap.page_allocator, input, 71, 1024);
    const p1_time = timer.lap();
    const result_p2 = try day18p2(input);
    const p2_time = timer.read();
    std.debug.print("day18 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day18 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day18 p1", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day18(allocator, input, 71, 1024) catch unreachable;
        }
    }.call, .{});
    try bench.add("day18 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day18p2(input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day18" {
    const result = try day18(std.heap.page_allocator, input_test, 7, 12);
    const expect = 22;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day18p2" {
    const result = try day18p2(input_test);
    const expect = 0;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
