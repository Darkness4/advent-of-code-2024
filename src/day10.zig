const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day10.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day10_test.txt"), "\n");

fn AutoHashSet(comptime T: type) type {
    return std.AutoHashMap(T, void);
}

const Pos = struct {
    x: usize,
    y: usize,
};

const Vec2 = struct {
    x: i64,
    y: i64,
};

const dirs = [_]Vec2{
    Vec2{ .x = -1, .y = 0 },
    Vec2{ .x = 0, .y = -1 },
    Vec2{ .x = 0, .y = 1 },
    Vec2{ .x = 1, .y = 0 },
};

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

    fn get(self: *const Matrix, x: usize, y: usize) u8 {
        return self.data[self.row_cap * x + y];
    }

    fn set(self: *Matrix, x: usize, y: usize, value: u8) void {
        self.data[self.row_cap * x + y] = value;
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
};

// DFS
fn search(start: Pos, matrix: Matrix, visited: *AutoHashSet(Pos)) !usize {
    // Ignore already visited path.
    if (visited.contains(start)) {
        return 0;
    }
    try visited.put(start, {});
    const startv = matrix.get(start.x, start.y);

    // End of trail.
    if (startv == '9') {
        return 1;
    }

    var acc: usize = 0;
    for (dirs) |dir| {
        const x: isize = @as(isize, @intCast(start.x)) + dir.x;
        const y: isize = @as(isize, @intCast(start.y)) + dir.y;

        if (x < 0 or y < 0 or x >= matrix.total_rows or y >= matrix.row_size) {
            continue;
        }

        const next = Pos{
            .x = @intCast(x),
            .y = @intCast(y),
        };
        if (matrix.get(next.x, next.y) == startv + 1) {
            acc += try search(next, matrix, visited);
        }
    }
    return acc;
}

fn day10(allocator: std.mem.Allocator, data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var buffer: [100 * 100 * @sizeOf(u8)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    var matrix = try Matrix.init(100, 100, fba_allocator);
    defer matrix.deinit();

    // Read everything
    while (lines.next()) |line| {
        matrix.appendRow(line);
    }

    var visited = AutoHashSet(Pos).init(allocator);
    defer visited.deinit();

    var acc: usize = 0;
    for (0..matrix.total_rows) |i| {
        for (0..matrix.row_size) |j| {
            visited.clearRetainingCapacity();

            if (matrix.get(i, j) == '0') {
                acc += try search(.{ .x = i, .y = j }, matrix, &visited);
            }
        }
    }

    return acc;
}

// This time it's pure DFS.
fn searchDistinct(start: Pos, matrix: Matrix) usize {
    const startv = matrix.get(start.x, start.y);
    if (startv == '9') {
        return 1;
    }

    var acc: usize = 0;
    for (dirs) |dir| {
        const x: isize = @as(isize, @intCast(start.x)) + dir.x;
        const y: isize = @as(isize, @intCast(start.y)) + dir.y;

        if (x < 0 or y < 0 or x >= matrix.total_rows or y >= matrix.row_size) {
            continue;
        }

        const next = Pos{
            .x = @intCast(x),
            .y = @intCast(y),
        };
        if (matrix.get(next.x, next.y) == startv + 1) {
            acc += searchDistinct(next, matrix);
        }
    }
    return acc;
}

fn day10p2(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var buffer: [100 * 100 * @sizeOf(u8)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    var matrix = try Matrix.init(100, 100, fba_allocator);
    defer matrix.deinit();

    // Read everything
    while (lines.next()) |line| {
        matrix.appendRow(line);
    }

    var acc: usize = 0;
    for (0..matrix.total_rows) |i| {
        for (0..matrix.row_size) |j| {
            if (matrix.get(i, j) == '0') {
                acc += searchDistinct(.{ .x = i, .y = j }, matrix);
            }
        }
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day10(std.heap.page_allocator, input);
    const p1_time = timer.lap();
    const result_p2 = try day10p2(input);
    const p2_time = timer.read();
    std.debug.print("day10 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day10 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{
        .track_allocations = true,
    });
    defer bench.deinit();
    try bench.add("day10 p1", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day10(allocator, input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day10 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day10p2(input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day10" {
    const result = try day10(std.heap.page_allocator, input_test);
    const expect = 36;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day10p2" {
    const result = try day10p2(input_test);
    const expect = 81;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
