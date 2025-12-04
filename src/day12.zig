const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day12.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day12_test.txt"), "\n");
const input_test2 = std.mem.trimRight(u8, @embedFile("day12_test2.txt"), "\n");
const input_test3 = std.mem.trimRight(u8, @embedFile("day12_test3.txt"), "\n");

fn AutoHashSet(comptime T: type) type {
    return std.AutoHashMap(T, void);
}

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

        pub fn addWithOverflow(self: Pos(T), other: Vec2) PosOrOverflow(T) {
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

        pub fn add(self: Pos(T), other: Vec2) Pos(T) {
            return .{ .x = self.x + other.x, .y = self.y + other.y };
        }

        pub fn as(self: Pos(T), comptime U: type) Pos(U) {
            return .{ .x = @intCast(self.x), .y = @intCast(self.y) };
        }
    };
}

const Vec2 = struct {
    x: isize,
    y: isize,
};

/// The four cardinal directions. Sorted in clockwise order.
const dirs = [_]Vec2{
    Vec2{ .x = -1, .y = 0 }, // left
    Vec2{ .x = 0, .y = -1 }, // up
    Vec2{ .x = 1, .y = 0 }, // right
    Vec2{ .x = 0, .y = 1 }, // down
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
        @memmove(self.data[self.row_cap * self.total_rows .. (self.row_cap * self.total_rows) + row.len], row);
        self.total_rows += 1;
    }
};

// flood_fill completes the visited AutoHashSet.
// Used in Go (the game) to compute score of a territory.
fn flood_fill(
    allocator: std.mem.Allocator,
    selector: u8,
    start: Pos(usize),
    matrix: Matrix,
    visited: *AutoHashSet(Pos(usize)),
) !void {
    var queue = std.ArrayList(Pos(usize)).empty;
    defer queue.deinit(allocator);

    try visited.put(start, {});
    try queue.append(allocator, start);

    while (queue.items.len > 0) {
        const current = queue.swapRemove(0); // Dequeue the first element

        for (dirs) |dir| {
            const next = current.addWithOverflow(dir);

            if (next.overflow == 1 or next.pos.x >= matrix.total_rows or next.pos.y >= matrix.total_rows or visited.get(next.pos) != null) {
                continue;
            }

            if (matrix.get(next.pos.x, next.pos.y) == selector) {
                try visited.put(next.pos, {});
                try queue.append(allocator, next.pos); // Enqueue the position
            }
        }
    }
}

fn compute_perimeter(visited: AutoHashSet(Pos(usize))) usize {
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

fn print_hashmap(visited: AutoHashSet(Pos(usize))) void {
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

    var matrix = try Matrix.init(200, 200, fba_allocator);
    defer matrix.deinit();

    // Read everything
    while (lines.next()) |line| {
        matrix.appendRow(line);
    }

    var visited = AutoHashSet(Pos(usize)).init(allocator);
    defer visited.deinit();

    var region = AutoHashSet(Pos(usize)).init(allocator);
    defer region.deinit();

    var acc: usize = 0;
    for (0..matrix.total_rows) |i| {
        for (0..matrix.row_size) |j| {
            region.clearRetainingCapacity();

            if (visited.get(.{ .x = i, .y = j }) != null) {
                continue;
            }

            try flood_fill(
                allocator,
                matrix.get(i, j),
                .{ .x = i, .y = j },
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

fn PosDir(comptime T: type) type {
    return struct {
        pos: Pos(T),
        dir_idx: usize,
    };
}

fn compute_sides(allocator: std.mem.Allocator, visited: AutoHashSet(Pos(usize))) !usize {
    var sides: usize = 0;

    var perimeter_tiles = AutoArrayHashSet(PosDir(isize)).init(allocator);
    defer perimeter_tiles.deinit();

    // For each perimeter tiles ('-', '|'), store them with the "normal"
    // (in mathematical sense) direction.
    //
    //     - - -
    //     ↑ ↑ ↑
    // | ← 0 1 2 → |
    //     ↓ ↓ ↓
    //     - - -
    //
    var it = visited.keyIterator();
    while (it.next()) |pos| {
        for (0.., dirs) |dir_idx, dir| {
            const next = pos.addWithOverflow(dir);
            if (next.overflow == 1 or visited.get(next.pos) == null) {
                const next_i = pos.as(isize).add(dir);
                try perimeter_tiles.put(.{
                    .pos = next_i,
                    .dir_idx = dir_idx,
                }, {});
            }
        }
    }

    // For each tiles, combine the sides that are in the same direction.
    // For each perimeter tiles ('-', '|'):
    //
    //    [-]- -       [-] is associated with 'up'.
    //     ↑ ↑ ↑
    // | ← 0 1 2 → |
    //     ↓ ↓ ↓
    //     - - -
    //
    while (perimeter_tiles.pop()) |entry| {
        sides += 1;
        const posdir = entry.key;

        // Move to the right.
        //
        //     -[-]-        [-] is still associated with 'up'.
        //     ↑ ↑ ↑
        // | ← 0 1 2 → |
        //     ↓ ↓ ↓
        //     - - -
        const right = dirs[(posdir.dir_idx + 1) % 4];
        var next: PosDir(isize) = .{
            .pos = posdir.pos.add(right), // We move right.
            .dir_idx = posdir.dir_idx, // But this is still up.
        };
        while (perimeter_tiles.get(next) != null) { // Is that wall exists?
            _ = perimeter_tiles.swapRemove(next); // Remove the right side.
            next = .{
                .pos = next.pos.add(right), // We move right again.
                .dir_idx = posdir.dir_idx, // This is still up.
            };
        }

        // Move to the left.
        const left = dirs[(posdir.dir_idx + 3) % 4];
        var prev: PosDir(isize) = .{
            .pos = posdir.pos.add(left),
            .dir_idx = posdir.dir_idx,
        };
        while (perimeter_tiles.get(prev) != null) {
            _ = perimeter_tiles.swapRemove(prev);
            prev = .{
                .pos = prev.pos.add(left),
                .dir_idx = posdir.dir_idx,
            };
        }
    }

    return sides;
}

test "compute_sides" {
    const allocator = std.heap.page_allocator;
    var visited = AutoHashSet(Pos(usize)).init(allocator);
    defer visited.deinit();

    try visited.put(.{ .x = 0, .y = 0 }, {});
    try visited.put(.{ .x = 0, .y = 1 }, {});

    const sides = try compute_sides(allocator, visited);
    const expect = 4;
    std.testing.expect(sides == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ sides, expect });
        return err;
    };
}

fn day12p2(allocator: std.mem.Allocator, data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var buffer: [200 * 200 * @sizeOf(u8)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    var matrix = try Matrix.init(200, 200, fba_allocator);
    defer matrix.deinit();

    // Read everything
    while (lines.next()) |line| {
        matrix.appendRow(line);
    }

    var visited = AutoHashSet(Pos(usize)).init(allocator);
    defer visited.deinit();

    var region = AutoHashSet(Pos(usize)).init(allocator);
    defer region.deinit();

    var acc: usize = 0;
    for (0..matrix.total_rows) |i| {
        for (0..matrix.row_size) |j| {
            region.clearRetainingCapacity();

            if (visited.get(.{ .x = i, .y = j }) != null) {
                continue;
            }

            try flood_fill(
                allocator,
                matrix.get(i, j),
                .{ .x = i, .y = j },
                matrix,
                &region,
            );

            const area = region.count();
            const sides = try compute_sides(allocator, region);
            acc += area * sides;

            var it = region.keyIterator();
            while (it.next()) |pos| {
                try visited.put(pos.*, {});
            }
        }
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day12(std.heap.page_allocator, input);
    const p1_time = timer.lap();
    const result_p2 = try day12p2(std.heap.page_allocator, input);
    const p2_time = timer.read();
    std.debug.print("day12 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day12 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day12 p1", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day12(allocator, input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day12 p2", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day12p2(allocator, input) catch unreachable;
        }
    }.call, .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try bench.run(stdout);
    try stdout.flush();
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
    const result = try day12p2(std.heap.page_allocator, input_test);
    const expect = 80;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };

    const result2 = try day12p2(std.heap.page_allocator, input_test2);
    const expect2 = 436;
    std.testing.expect(result2 == expect2) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result2, expect2 });
        return err;
    };

    const result3 = try day12p2(std.heap.page_allocator,
        \\EEEEE
        \\EXXXX
        \\EEEEE
        \\EXXXX
        \\EEEEE
    );
    const expect3 = 236;
    std.testing.expect(result3 == expect3) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result3, expect3 });
        return err;
    };

    const result4 = try day12p2(std.heap.page_allocator,
        \\AAAAAA
        \\AAABBA
        \\AAABBA
        \\ABBAAA
        \\ABBAAA
        \\AAAAAA
    );
    const expect4 = 368;
    std.testing.expect(result4 == expect4) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result4, expect4 });
        return err;
    };
}
