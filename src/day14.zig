const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day14.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day14_test.txt"), "\n");

const max_x = 101;
const max_y = 103;
const mid_x = max_x / 2;
const mid_y = max_y / 2;

fn scanNumber(data: []const u8, idx: *usize) ?isize {
    var number: ?isize = null;
    var isNegative = false;
    if (idx.* >= data.len) return number;
    var char = data[idx.*];
    if (char == '-') {
        idx.* += 1;
        if (idx.* >= data.len) return null;
        char = data[idx.*];
        isNegative = true;
    }
    while (char >= '0' and char <= '9') {
        const v = char - '0';
        number = if (number) |n| n * 10 + (char - '0') else v;
        idx.* += 1;
        if (idx.* >= data.len) break;
        char = data[idx.*];
    }
    return if (isNegative) number.? * -1 else number;
}

fn Pos(comptime T: type) type {
    return struct {
        x: T,
        y: T,

        pub fn eql(a: Pos(T), b: Pos(T)) bool {
            return a.x == b.x and a.y == b.y;
        }
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

const Robot = struct {
    pos: Pos(isize),
    vec: Vec2(isize),
    max: Pos(isize),

    pub fn move(self: *Robot, times: isize) void {
        self.pos.x = @mod(self.pos.x + (self.vec.x * times), self.max.x);
        self.pos.y = @mod(self.pos.y + (self.vec.y * times), self.max.y);
    }

    pub fn inIn(self: *Robot, low_pos: Pos(isize), high_pos: Pos(isize)) bool {
        return self.pos.x >= low_pos.x and self.pos.x < high_pos.x and
            self.pos.y >= low_pos.y and self.pos.y < high_pos.y;
    }
};

test "move" {
    var robot: Robot = .{
        .pos = .{ .x = 2, .y = 4 },
        .vec = .{ .x = 2, .y = -3 },
        .max = .{ .x = 11, .y = 7 },
    };
    const expected: Pos(isize) = .{ .x = 4, .y = 1 };
    robot.move(1);
    std.testing.expect(robot.pos.eql(expected)) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ robot.pos, expected });
        return err;
    };
}

fn scanLine(line: []const u8, max: Pos(isize)) Robot {
    var idx: usize = 2;
    const x = scanNumber(line, &idx) orelse unreachable;
    idx += 1;
    const y = scanNumber(line, &idx) orelse unreachable;
    idx += 3;
    const vec_x = scanNumber(line, &idx) orelse unreachable;
    idx += 1;
    const vec_y = scanNumber(line, &idx) orelse unreachable;
    return Robot{
        .pos = .{ .x = x, .y = y },
        .vec = .{ .x = vec_x, .y = vec_y },
        .max = max,
    };
}

test "scanLine" {
    const line = "p=0,4 v=3,-3";
    const max = Pos(isize){ .x = 11, .y = 7 };
    const expect = Robot{
        .pos = .{ .x = 0, .y = 4 },
        .vec = .{ .x = 3, .y = -3 },
        .max = max,
    };
    const result = scanLine(line, max);
    std.testing.expect(result.pos.eql(expect.pos)) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result.pos, expect.pos });
        return err;
    };
    std.testing.expect(result.vec.eql(expect.vec)) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result.vec, expect.vec });
        return err;
    };
}

const Quandrant = struct {
    low_pos: Pos(isize),
    high_pos: Pos(isize),
};

fn quadrants(max: Pos(isize)) [4]Quandrant {
    return [4]Quandrant{
        .{ .low_pos = .{ .x = 0, .y = 0 }, .high_pos = .{ .x = @divFloor(max.x, 2), .y = @divFloor(max.y, 2) } },
        .{ .low_pos = .{ .x = @divFloor(max.x, 2) + 1, .y = 0 }, .high_pos = .{ .x = max.x, .y = @divFloor(max.y, 2) } },
        .{ .low_pos = .{ .x = 0, .y = @divFloor(max.y, 2) + 1 }, .high_pos = .{ .x = @divFloor(max.x, 2), .y = max.y } },
        .{ .low_pos = .{ .x = @divFloor(max.x, 2) + 1, .y = @divFloor(max.y, 2) + 1 }, .high_pos = .{ .x = max.x, .y = max.y } },
    };
}

fn day14(data: []const u8, comptime max: Pos(isize)) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var buffer: [500]Robot = undefined;
    var robots = std.ArrayList(Robot).initBuffer(&buffer);

    while (lines.next()) |line| {
        const robot = scanLine(line, max);
        robots.appendAssumeCapacity(robot);
    }

    for (robots.items) |*robot| {
        robot.move(100);
    }

    // std.debug.print("robots: {}\n", .{robots.items.len});

    // For each quadrant, counts the number of robots in the quadrant
    var acc: usize = 1;
    for (quadrants(max)) |quadrant| {
        // std.debug.print("quadrant: {} {}\n", .{ quadrant.low_pos, quadrant.high_pos });
        var count: usize = 0;
        for (robots.items) |*robot| {
            if (robot.inIn(quadrant.low_pos, quadrant.high_pos)) {
                count += 1;
                // std.debug.print("robot pos: {}\n", .{robot.pos});
            }
        }
        // std.debug.print("count: {}\n", .{count});
        acc *= count;
    }

    return acc;
}

const Matrix = struct {
    data: []u8,
    size_x: usize,
    size_y: usize,

    allocator: std.mem.Allocator,

    fn init(size_x: usize, size_y: usize, allocator: std.mem.Allocator) !Matrix {
        const data = try allocator.alloc(u8, size_x * size_y);
        @memset(data, '.');
        return Matrix{
            .data = data,
            .size_x = size_x,
            .size_y = size_y,
            .allocator = allocator,
        };
    }

    fn deinit(self: *Matrix) void {
        self.allocator.free(self.data);
    }

    fn get(self: *const Matrix, x: usize, y: usize) u8 {
        return self.data[self.size_x * x + y];
    }

    fn set(self: *Matrix, x: usize, y: usize, value: u8) void {
        self.data[self.size_x * x + y] = value;
    }

    fn clear(self: *Matrix) void {
        @memset(self.data, '.');
    }

    fn print(self: *const Matrix) void {
        for (0..self.size_x) |x| {
            std.debug.print("{s}\n", .{self.data[self.size_x * x .. self.size_x * (x + 1)]});
        }
    }
};

var dirs = [_]Vec2(isize){
    .{ .x = 0, .y = 1 },
    .{ .x = 1, .y = 0 },
    .{ .x = 0, .y = -1 },
    .{ .x = -1, .y = 0 },
};

// A chrismas tree would have an abnormal alignment of robots, especially vertically.
fn day14p2(allocator: std.mem.Allocator, data: []const u8, comptime max: Pos(isize)) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var matrix = try Matrix.init(max.x, max.y, allocator);
    defer matrix.deinit();

    var buffer: [500]Robot = undefined;
    var robots = std.ArrayList(Robot).initBuffer(&buffer);

    while (lines.next()) |line| {
        const robot = scanLine(line, max);
        robots.appendAssumeCapacity(robot);
    }

    var count: usize = 0;
    while (true) : (count += 1) {
        // std.debug.print("count: {}\n", .{count});
        matrix.clear();

        for (robots.items) |*robot| {
            robot.move(1);

            matrix.set(@intCast(robot.pos.x), @intCast(robot.pos.y), 'X');
        }

        var neigh_count: usize = 0;
        for (robots.items) |robot| {
            for (dirs) |dir| {
                const x = robot.pos.x + dir.x;
                const y = robot.pos.y + dir.y;
                if (x < 0 or x >= max.x or y < 0 or y >= max.y) continue;
                if (matrix.get(@intCast(x), @intCast(y)) == 'X') {
                    neigh_count += 1;
                }
            }
        }
        if (neigh_count >= 1000) {
            // matrix.print();
            break;
        }
    }

    return count + 1;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day14(input, .{ .x = max_x, .y = max_y });
    const p1_time = timer.lap();
    const result_p2 = try day14p2(std.heap.page_allocator, input, .{ .x = max_x, .y = max_y });
    const p2_time = timer.read();
    std.debug.print("day14 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day14 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{
        .track_allocations = true,
    });
    defer bench.deinit();
    try bench.add("day14 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day14(input, .{ .x = max_x, .y = max_y }) catch unreachable;
        }
    }.call, .{});
    try bench.add("day14 p2", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day14p2(allocator, input, .{ .x = max_x, .y = max_y }) catch unreachable;
        }
    }.call, .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try bench.run(stdout);
    try stdout.flush();
}

test "day14" {
    const result = try day14(input_test, .{ .x = 11, .y = 7 });
    const expect = 12;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
