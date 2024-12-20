const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day20.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day20_test.txt"), "\n");

fn AutoArrayHashSet(comptime T: type) type {
    return std.AutoArrayHashMap(T, void);
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

fn distance(pos: Pos(usize), end: Pos(usize)) usize {
    return absSub(pos.x, end.x) + absSub(pos.y, end.y);
}

fn absSub(a: usize, b: usize) usize {
    return if (a > b) a - b else b - a;
}

const Matrix = struct {
    data: []u8,
    cap: usize,
    row_cap: usize,
    row_size: usize = 0,
    total_rows: usize = 0,

    allocator: std.mem.Allocator,

    fn init(cap: usize, row_cap: usize, allocator: std.mem.Allocator) !Matrix {
        const data = try allocator.alloc(u8, cap * row_cap);
        return Matrix{
            .data = data,
            .cap = cap,
            .row_cap = row_cap,
            .allocator = allocator,
        };
    }

    fn deinit(self: *Matrix) void {
        self.allocator.free(self.data);
    }

    fn get(self: *const Matrix, p: Pos(usize)) u8 {
        return self.data[self.row_cap * p.x + p.y];
    }

    fn set(self: *Matrix, p: Pos(usize), value: u8) void {
        self.data[self.row_cap * p.x + p.y] = value;
    }

    /// appendRow also sets the size of the matrix if the size of the matrix is 0.
    /// Appending more row above the row size will do nothing.
    fn appendRow(self: *Matrix, row: []const u8) void {
        if (self.row_size == 0) {
            self.row_size = row.len;
        } else if (self.row_size != row.len) {
            std.debug.panic("row size mismatch\n", .{});
        }
        std.mem.copyForwards(u8, self.data[self.row_cap * self.total_rows .. self.row_cap * (self.total_rows + 1)], row);
        self.total_rows += 1;
    }

    fn print(self: *const Matrix) void {
        for (0..self.total_rows) |x| {
            std.debug.print("{s}\n", .{self.data[self.row_cap * x .. (self.row_cap * x) + self.row_size]});
        }
    }
};

const dirs = [_]Vec2(isize){
    .{ .x = -1, .y = 0 }, // Up
    .{ .x = 0, .y = 1 }, // Right
    .{ .x = 1, .y = 0 }, // Down
    .{ .x = 0, .y = -1 }, // Left
};

fn find_path(
    matrix: *const Matrix,
    visited: *AutoArrayHashSet(Pos(usize)),
    end: Pos(usize),
    current: Pos(usize),
) !void {
    try visited.put(current, {});

    if (current.eql(end)) {
        return;
    }

    for (dirs) |dir| {
        const next = current.addWithOverflow(dir);
        if (next.overflow == 1) continue;
        if (matrix.get(next.pos) == '#') continue;
        if (visited.contains(next.pos)) continue;

        try find_path(matrix, visited, end, next.pos);
        return; // Return immediately because there is only one path, no fork.
    }
}

fn day20(allocator: std.mem.Allocator, data: []const u8, save: usize) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var buffer: [142 * 142 * @sizeOf(u8)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    var matrix = try Matrix.init(142, 142, fba_allocator);
    defer matrix.deinit();

    var start: ?Pos(usize) = null;
    var end: ?Pos(usize) = null;
    var idx: usize = 0;
    while (lines.next()) |line| : (idx += 1) {
        matrix.appendRow(line);
        if (start == null or end == null) {
            for (0.., line) |y, c| {
                if (start == null) {
                    if (c == 'S') {
                        start = .{ .x = matrix.total_rows - 1, .y = y };
                    }
                }
                if (end == null) {
                    if (c == 'E') {
                        end = .{ .x = matrix.total_rows - 1, .y = y };
                    }
                }
            }
        }
    }

    var visited = AutoArrayHashSet(Pos(usize)).init(allocator);
    defer visited.deinit();
    try find_path(&matrix, &visited, end.?, start.?);

    var acc: usize = 0;
    var poss = visited.keys();
    for (0.., poss[0 .. poss.len - save]) |i, pos| { // Walk path
        for (0.., poss[i + save ..]) |j, next_pos| {
            const d = distance(pos, next_pos);
            if (d <= 2 and d <= j) {
                acc += 1;
            }
        }
    }

    return acc;
}

fn day20p2(allocator: std.mem.Allocator, data: []const u8, save: usize) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var buffer: [142 * 142 * @sizeOf(u8)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    var matrix = try Matrix.init(142, 142, fba_allocator);
    defer matrix.deinit();

    var start: ?Pos(usize) = null;
    var end: ?Pos(usize) = null;
    var idx: usize = 0;
    while (lines.next()) |line| : (idx += 1) {
        matrix.appendRow(line);
        if (start == null or end == null) {
            for (0.., line) |y, c| {
                if (start == null) {
                    if (c == 'S') {
                        start = .{ .x = matrix.total_rows - 1, .y = y };
                    }
                }
                if (end == null) {
                    if (c == 'E') {
                        end = .{ .x = matrix.total_rows - 1, .y = y };
                    }
                }
            }
        }
    }

    var visited = AutoArrayHashSet(Pos(usize)).init(allocator);
    defer visited.deinit();
    try find_path(&matrix, &visited, end.?, start.?);

    var acc: usize = 0;
    var poss = visited.keys();
    for (0.., poss[0 .. poss.len - save]) |i, pos| { // Walk path
        for (0.., poss[i + save ..]) |j, next_pos| {
            const d = distance(pos, next_pos);
            if (d <= 20 and d <= j) {
                acc += 1;
            }
        }
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day20(std.heap.page_allocator, input, 100);
    const p1_time = timer.lap();
    const result_p2 = try day20p2(std.heap.page_allocator, input, 100);
    const p2_time = timer.read();
    std.debug.print("day20 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day20 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{
        .track_allocations = true,
    });
    defer bench.deinit();
    try bench.add("day20 p1", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day20(allocator, input, 100) catch unreachable;
        }
    }.call, .{});
    try bench.add("day20 p2", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day20p2(allocator, input, 100) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day20" {
    const TestCase = struct {
        expect: usize,
        save: usize,
    };
    const tt = [_]TestCase{
        .{ .expect = 1, .save = 64 },
        .{ .expect = 2, .save = 40 },
        .{ .expect = 3, .save = 38 },
        .{ .expect = 4, .save = 36 },
        .{ .expect = 5, .save = 20 },
        .{ .expect = 8, .save = 12 },
        .{ .expect = 10, .save = 10 },
        .{ .expect = 14, .save = 8 },
        .{ .expect = 16, .save = 6 },
        .{ .expect = 30, .save = 4 },
        .{ .expect = 44, .save = 2 },
    };

    for (tt) |tc| {
        const result = try day20(std.heap.page_allocator, input_test, tc.save);
        std.testing.expect(result == tc.expect) catch |err| {
            std.debug.print("got: {}, expect: {}\n", .{ result, tc.expect });
            return err;
        };
    }
}

test "day20p2" {
    const TestCase = struct {
        expect: usize,
        save: usize,
    };
    const tt = [_]TestCase{
        .{ .expect = 3, .save = 76 },
        .{ .expect = 7, .save = 74 },
        .{ .expect = 29, .save = 72 },
        .{ .expect = 41, .save = 70 },
    };

    for (tt) |tc| {
        const result = try day20p2(std.heap.page_allocator, input_test, tc.save);
        std.testing.expect(result == tc.expect) catch |err| {
            std.debug.print("got: {}, expect: {}\n", .{ result, tc.expect });
            return err;
        };
    }
}
