const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day12.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day12_test.txt"), "\n");
const input_test2 = std.mem.trimRight(u8, @embedFile("day12_test2.txt"), "\n");
const input_test3 = std.mem.trimRight(u8, @embedFile("day12_test3.txt"), "\n");

fn AutoHashSet(comptime T: type) type {
    return std.AutoHashMap(T, void);
}

const PosOrOverflow = struct {
    pos: Pos,
    overflow: u1,
};

const Pos = struct {
    x: usize,
    y: usize,

    pub fn addWithOverflow(self: Pos, other: Vec2) PosOrOverflow {
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

const Vec2 = struct {
    x: isize,
    y: isize,
};

const dirs = [_]Vec2{
    Vec2{ .x = -1, .y = 0 },
    Vec2{ .x = 0, .y = -1 },
    Vec2{ .x = 0, .y = 1 },
    Vec2{ .x = 1, .y = 0 },
};

const SquareMatrix = struct {
    data: []u8,
    cap: usize,

    allocator: std.mem.Allocator,

    fn init(size: usize, allocator: std.mem.Allocator) !SquareMatrix {
        const data = try allocator.alloc(u8, size * size);
        return SquareMatrix{ .data = data, .cap = size, .allocator = allocator };
    }

    fn deinit(self: *SquareMatrix) void {
        self.allocator.free(self.data);
    }

    fn get(self: *const SquareMatrix, x: usize, y: usize) u8 {
        return self.data[self.cap * x + y];
    }

    fn set(self: *SquareMatrix, x: usize, y: usize, value: u8) void {
        self.data[self.cap * x + y] = value;
    }

    fn setRow(self: *SquareMatrix, x: usize, row: []const u8) void {
        std.mem.copyForwards(u8, self.data[self.cap * x .. self.cap * (x + 1)], row);
    }
};

// flood_fill completes the visited AutoHashSet.
// Used in Go (the game) to compute score of a territory.
fn flood_fill(
    allocator: std.mem.Allocator,
    selector: u8,
    start: Pos,
    size: usize,
    matrix: SquareMatrix,
    visited: *AutoHashSet(Pos),
) !void {
    var queue = std.ArrayList(Pos).init(allocator);
    defer queue.deinit();

    try visited.put(start, {});
    try queue.append(start);

    while (queue.items.len > 0) {
        const current = queue.swapRemove(0); // Dequeue the first element

        for (dirs) |dir| {
            const next = current.addWithOverflow(dir);

            if (next.overflow == 1 or next.pos.x >= size or next.pos.y >= size or visited.get(next.pos) != null) {
                continue;
            }

            if (matrix.get(next.pos.x, next.pos.y) == selector) {
                try visited.put(next.pos, {});
                try queue.append(next.pos); // Enqueue the position
            }
        }
    }
}

fn compute_perimeter(visited: AutoHashSet(Pos)) usize {
    var perimeter: usize = 0;
    var it = visited.keyIterator();
    while (it.next()) |pos| {
        for (dirs) |dir| {
            const next = pos.addWithOverflow(dir);
            if (next.overflow == 1 or visited.get(next.pos) == null) {
                perimeter += 1;
            }
        }
    }
    return perimeter;
}

fn print_hashmap(visited: AutoHashSet(Pos)) void {
    var it = visited.keyIterator();
    while (it.next()) |pos| {
        std.debug.print("({}, {}),", .{ pos.x, pos.y });
    }
    std.debug.print("\n", .{});
}

fn day12(allocator: std.mem.Allocator, data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var buffer: [200 * 200 * @sizeOf(u8)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    var matrix = try SquareMatrix.init(200, fba_allocator);
    defer matrix.deinit();

    // Read everything
    var idx: usize = 0;
    while (lines.next()) |line| : (idx += 1) {
        matrix.setRow(idx, line);
    }
    const size = idx;

    var visited = AutoHashSet(Pos).init(allocator);
    defer visited.deinit();

    var region = AutoHashSet(Pos).init(allocator);
    defer region.deinit();

    var acc: usize = 0;
    for (0..size) |i| {
        for (0..size) |j| {
            region.clearRetainingCapacity();

            if (visited.get(.{ .x = i, .y = j }) != null) {
                continue;
            }

            try flood_fill(
                allocator,
                matrix.get(i, j),
                .{ .x = i, .y = j },
                size,
                matrix,
                &region,
            );

            // print_hashmap(region);

            const area = region.count();
            const perimeter = compute_perimeter(region);
            acc += area * perimeter;

            var it = region.keyIterator();
            while (it.next()) |pos| {
                try visited.put(pos.*, {});
            }
        }
    }

    return acc;
}

fn day12p2(_: []const u8) !usize {
    return 0;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day12(std.heap.page_allocator, input);
    const p1_time = timer.lap();
    const result_p2 = try day12p2(input);
    const p2_time = timer.read();
    std.debug.print("day12 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day12 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{
        .track_allocations = true,
    });
    defer bench.deinit();
    try bench.add("day12 p1", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day12(allocator, input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day12 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day12p2(input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day12" {
    const result = try day12(std.heap.page_allocator, input_test);
    const expect = 140;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };

    const result2 = try day12(std.heap.page_allocator, input_test2);
    const expect2 = 772;
    std.testing.expect(result2 == expect2) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result2, expect2 });
        return err;
    };

    const result3 = try day12(std.heap.page_allocator, input_test3);
    const expect3 = 1930;
    std.testing.expect(result3 == expect3) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result3, expect3 });
        return err;
    };
}

test "day12p2" {
    const result = try day12p2(input_test);
    const expect = 0;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
