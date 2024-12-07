const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day6.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day6_test.txt"), "\n");

var buffer: [201 * 201 * @sizeOf(u8) * @sizeOf([]u8)]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const fba_allocator = fba.allocator();

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const gpa_allocator = gpa.allocator();

const MapError = error{
    InvalidFormat,
    BoundaryReached,
    LoopDetected,
};

const Pos = struct {
    x: usize,
    y: usize,

    pub fn eql(self: Pos, other: Pos) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const Map = struct {
    data: [][]u8,
    size: usize,
    starting_point: Pos,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, size: usize) !Map {
        // Allocate 2D array for square map
        var data = try allocator.alloc([]u8, size);
        errdefer allocator.free(data);

        for (0..size) |i| {
            data[i] = try allocator.alloc(u8, size);
            errdefer for (0..i) |j| {
                allocator.free(data[j]);
            };
        }

        return Map{
            .data = data,
            .size = size,
            .starting_point = .{ .x = 0, .y = 0 },
            .allocator = allocator,
        };
    }

    pub fn scan(self: Map, idx: usize, line: []const u8) void {
        @memcpy(self.data[idx], line[0..self.size]);
    }

    // Only used in p2.
    pub fn putObstacle(self: Map, pos: Pos) void {
        self.data[pos.x][pos.y] = '#';
    }

    // Only used in p2.
    pub fn removeObstacle(self: Map, pos: Pos) void {
        self.data[pos.x][pos.y] = '.';
    }

    pub fn deinit(self: Map) void {
        // Deallocate in the same order as allocation to avoid fragmentation,
        // which helps the fixed buffer allocator.
        var idx = self.data.len;
        while (idx > 0) {
            idx -= 1;
            self.allocator.free(self.data[idx]);
        }
        self.allocator.free(self.data);
    }

    pub fn print(self: Map) void {
        for (self.data) |line| {
            std.debug.print("{s}\n", .{line});
        }
    }
};

const Vec2 = struct {
    x: isize,
    y: isize,

    pub fn eql(self: Vec2, other: Vec2) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const dirs = [_]Vec2{
    .{ .x = -1, .y = 0 }, // Up
    .{ .x = 0, .y = 1 }, // Right
    .{ .x = 1, .y = 0 }, // Down
    .{ .x = 0, .y = -1 }, // Left
};

fn moveAndAccumulate(map: Map, pos: Pos, dir: Vec2, acc: *usize) !Pos {
    var last_pos = pos;
    var new_pos = pos;
    while (new_pos.x > 0 and new_pos.x < map.size - 1 and new_pos.y > 0 and new_pos.y < map.size - 1) {
        // Add trails
        if (map.data[new_pos.x][new_pos.y] != 'X') {
            map.data[new_pos.x][new_pos.y] = 'X';
            acc.* += 1;
        }

        // Update new_pod
        last_pos = new_pos;
        new_pos = .{
            .x = @as(usize, @intCast(@as(isize, @intCast(new_pos.x)) + dir.x)),
            .y = @as(usize, @intCast(@as(isize, @intCast(new_pos.y)) + dir.y)),
        };
        if (map.data[new_pos.x][new_pos.y] == '#') {
            return last_pos;
        }
    }
    map.data[new_pos.x][new_pos.y] = 'X';
    acc.* += 1;
    if (new_pos.x == 0 or new_pos.x == map.size - 1 or new_pos.y == 0 or new_pos.y == map.size - 1) {
        return MapError.BoundaryReached;
    }
    return new_pos;
}

fn day6(data: []const u8) !u64 {
    var lines = std.mem.splitScalar(u8, data, '\n');

    const size = std.mem.indexOfScalar(u8, data, '\n') orelse return MapError.InvalidFormat;
    var map = try Map.init(fba_allocator, size);
    defer map.deinit();

    // Read the map
    var x: usize = 0;
    while (lines.next()) |line| : (x += 1) {
        map.scan(x, line);

        // Look for starting point
        const y = std.mem.indexOfScalar(u8, line, '^');
        if (y != null) {
            map.starting_point = .{ .x = x, .y = y.? };
        }
    }

    // Play the game.
    var pos = map.starting_point;
    var acc: usize = 0;
    var dir_idx: usize = 0;
    while (true) : (dir_idx = (dir_idx + 1) % 4) {
        const dir = dirs[dir_idx];
        pos = moveAndAccumulate(map, pos, dir, &acc) catch |err| {
            if (err == MapError.BoundaryReached) {
                break;
            }
            return err;
        };
        // std.debug.print("pos: {}, acc: {}\n", .{ pos, acc });
    }

    return acc;
}

fn AutoHashSet(comptime T: type) type {
    return std.AutoHashMap(T, void);
}

const PosVec2 = struct {
    pos: Pos,
    dir: Vec2,

    pub fn eql(self: PosVec2, other: PosVec2) bool {
        return self.pos.eql(other.pos) and self.dir.eql(other.dir);
    }
};

fn moveAndRegisterTrails(map: Map, pos: Pos, dir: Vec2, trails: *std.ArrayList(Pos)) !Pos {
    var last_pos = pos;
    var new_pos = pos;
    while (new_pos.x > 0 and new_pos.x < map.size - 1 and new_pos.y > 0 and new_pos.y < map.size - 1) {
        // Add trails
        if (map.data[new_pos.x][new_pos.y] != 'X') {
            map.data[new_pos.x][new_pos.y] = 'X';
            // Register to history
            try trails.append(new_pos);
        }

        // Update new_pod
        last_pos = new_pos;
        new_pos = .{
            .x = @as(usize, @intCast(@as(isize, @intCast(new_pos.x)) + dir.x)),
            .y = @as(usize, @intCast(@as(isize, @intCast(new_pos.y)) + dir.y)),
        };
        if (map.data[new_pos.x][new_pos.y] == '#') {
            return last_pos;
        }
    }
    try trails.append(new_pos);
    if (new_pos.x == 0 or new_pos.x == map.size - 1 or new_pos.y == 0 or new_pos.y == map.size - 1) {
        return MapError.BoundaryReached;
    }
    return new_pos;
}

fn moveAndDetectLoop(map: Map, pos: Pos, dir: Vec2, visited: *AutoHashSet(PosVec2)) !Pos {
    var last_pos = pos;
    var new_pos = pos;
    while (new_pos.x > 0 and new_pos.x < map.size - 1 and new_pos.y > 0 and new_pos.y < map.size - 1) {
        // Detect loop (during the move)
        if (visited.get(.{ .pos = new_pos, .dir = dir }) != null) {
            return MapError.LoopDetected;
        }

        // Register to history
        try visited.put(.{ .pos = new_pos, .dir = dir }, {});

        // Update new_pod
        last_pos = new_pos;
        new_pos = .{
            .x = @as(usize, @intCast(@as(isize, @intCast(new_pos.x)) + dir.x)),
            .y = @as(usize, @intCast(@as(isize, @intCast(new_pos.y)) + dir.y)),
        };
        if (map.data[new_pos.x][new_pos.y] == '#') {
            return last_pos;
        }
    }
    // Register last position to history
    try visited.put(.{ .pos = new_pos, .dir = dir }, {});
    if (new_pos.x == 0 or new_pos.x == map.size - 1 or new_pos.y == 0 or new_pos.y == map.size - 1) {
        return MapError.BoundaryReached;
    }
    return new_pos;
}

// Pseudo-brute force is probably the way to go. Two issues we need to solve:
//
// 1. Strategically place the obstacle: use day1 solution (it's fast, so, no issue here), and place an obstacle all over the path.
// 2. Detect loops: A loop is detected by building an history of pos+dir and check if the new pos+dir appears in the history.
fn day6p2(allocator: std.mem.Allocator, data: []const u8) !u64 {
    var lines = std.mem.splitScalar(u8, data, '\n');

    const size = std.mem.indexOfScalar(u8, data, '\n') orelse return MapError.InvalidFormat;
    var map = try Map.init(fba_allocator, size);
    defer map.deinit();

    // Read the map
    var x: usize = 0;
    while (lines.next()) |line| : (x += 1) {
        map.scan(x, line);

        // Look for starting point
        const y = std.mem.indexOfScalar(u8, line, '^');
        if (y != null) {
            map.starting_point = .{ .x = x, .y = y.? };
        }
    }

    // Play the game.
    var obstacles = try std.ArrayList(Pos).initCapacity(allocator, 201 * 201 * 4);
    defer obstacles.deinit();

    var pos = map.starting_point;
    var dir_idx: usize = 0;
    while (true) : (dir_idx = (dir_idx + 1) % 4) {
        const dir = dirs[dir_idx];
        pos = moveAndRegisterTrails(map, pos, dir, &obstacles) catch |err| {
            if (err == MapError.BoundaryReached) {
                break;
            }
            return err;
        };
    }
    // std.debug.print("obstacles.len: {}\n", .{obstacles.items.len}); // Should match the solution of part 1.

    var acc: u64 = 0;
    var visited = AutoHashSet(PosVec2).init(allocator);
    defer visited.deinit();
    for (obstacles.items[1..]) |obs_pos| { // Ignore the starting point.
        visited.clearRetainingCapacity();

        map.putObstacle(obs_pos);
        defer map.removeObstacle(obs_pos);

        // Play the game.
        pos = map.starting_point;
        dir_idx = 0;
        loop: while (true) : (dir_idx = (dir_idx + 1) % 4) {
            const dir = dirs[dir_idx];
            pos = moveAndDetectLoop(map, pos, dir, &visited) catch |err| switch (err) {
                MapError.LoopDetected => {
                    acc += 1;
                    break :loop;
                },
                MapError.BoundaryReached => {
                    break :loop;
                },
                else => return err,
            };
        }
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day6(input);
    const p1_time = timer.lap();
    const result_p2 = try day6p2(gpa_allocator, input);
    const p2_time = timer.read();
    std.debug.print("day6 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day6 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(gpa_allocator, .{
        .track_allocations = true,
        .iterations = 5,
    });
    defer bench.deinit();
    try bench.add("day6 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day6(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day6 p2", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day6p2(allocator, input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day6" {
    const result = try day6(input_test);
    const expect = 41;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day6p2" {
    const result = try day6p2(gpa_allocator, input_test);
    const expect = 6;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
