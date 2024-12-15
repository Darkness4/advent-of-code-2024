const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day15.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day15_test.txt"), "\n");
const input_test2 = std.mem.trimRight(u8, @embedFile("day15_test2.txt"), "\n");

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

fn Vec2(comptime T: type) type {
    return struct {
        x: T,
        y: T,

        pub fn eql(a: Vec2(T), b: Vec2(T)) bool {
            return a.x == b.x and a.y == b.y;
        }
    };
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

    // Push box to the next position.
    // Move if there is an empty space.
    // If there is a wall, do nothing.
    fn moveBox(self: *Matrix, p: Pos(usize), d: Vec2(isize)) bool {
        const current = self.get(p);
        switch (current) {
            '#' => return false, // Wall.
            '.' => return true, // Empty space.
            'O' => {
                // It's a box.
                const next = p.addWithOverflow(d);
                if (next.overflow == 1) unreachable;
                const canMove = self.moveBox(next.pos, d);
                if (canMove) {
                    self.set(next.pos, 'O');
                }
                return canMove;
            },
            else => {
                std.debug.panic("invalid character: {c}\n", .{current});
            },
        }
    }

    fn print(self: *const Matrix) void {
        for (0..self.total_rows) |x| {
            std.debug.print("{s}\n", .{self.data[self.row_size * x .. self.row_size * (x + 1)]});
        }
    }
};

var dirs = [_]Vec2(isize){
    .{ .x = 0, .y = 1 },
    .{ .x = 1, .y = 0 },
    .{ .x = 0, .y = -1 },
    .{ .x = -1, .y = 0 },
};

fn decodeMove(c: u8) usize {
    return switch (c) {
        '>' => 0,
        'v' => 1,
        '<' => 2,
        '^' => 3,
        else => {
            std.debug.panic("invalid move: {c}\n", .{c});
        },
    };
}

fn day15(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var buffer: [50 * 50 * @sizeOf(u8)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    var matrix = try Matrix.init(50, 50, fba_allocator);
    defer matrix.deinit();

    var current_pos_init: ?Pos(usize) = null;
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
        matrix.appendRow(line);
        if (current_pos_init == null) {
            for (0.., line) |y, c| {
                if (c == '@') {
                    current_pos_init = .{ .x = matrix.total_rows - 1, .y = y };
                    break;
                }
            }
        }
    }
    var current_pos = current_pos_init.?;
    // const got = matrix.get(current_pos);
    // if (got != '@') std.debug.panic("invalid initial position: {c}\n", .{got});

    while (lines.next()) |line| {
        for (line) |c| {
            const move = decodeMove(c);
            const d = dirs[move];
            const next = current_pos.addWithOverflow(d);
            if (next.overflow == 1) unreachable;
            // It's technically impossible to overflow. The area is bounded by walls.

            if (matrix.moveBox(next.pos, d)) {
                matrix.set(current_pos, '.');
                matrix.set(next.pos, '@');
                current_pos = next.pos;
            }
        }
    }

    // Sum all box coordinates.
    var acc: usize = 0;
    for (0..matrix.total_rows) |x| {
        for (0..matrix.row_size) |y| {
            const c = matrix.get(.{ .x = x, .y = y });
            if (c == 'O') {
                acc += y + x * 100;
            }
        }
    }

    return acc;
}

// A chrismas tree would have an abnormal alignment of robots, especially vertically.
fn day15p2(_: []const u8) !usize {
    return 0;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day15(input);
    const p1_time = timer.lap();
    const result_p2 = try day15p2(input);
    const p2_time = timer.read();
    std.debug.print("day15 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day15 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{
        .track_allocations = true,
    });
    defer bench.deinit();
    try bench.add("day15 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day15(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day15 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day15p2(input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day15" {
    const result = try day15(input_test);
    const expect = 2028;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };

    const result2 = try day15(input_test2);
    const expect2 = 10092;
    std.testing.expect(result2 == expect2) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result2, expect2 });
        return err;
    };
}
