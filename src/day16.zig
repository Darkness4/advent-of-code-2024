const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day16.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day16_test.txt"), "\n");
const input_test2 = std.mem.trimRight(u8, @embedFile("day16_test2.txt"), "\n");

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

const RotScore = struct {
    rot: usize,
    score: usize,
};

var rot_scores = [_]RotScore{
    .{ .rot = 0, .score = 1 }, // Forward
    .{ .rot = 1, .score = 1001 }, // Right
    .{ .rot = 3, .score = 1001 }, // Left (3 == -1 % 4)
};

const PosDir = struct {
    pos: Pos(usize),
    dir_idx: usize,
};

const PosDirScore = struct {
    pos: Pos(usize),
    dir_idx: usize,
    score: usize,
};

fn astar(
    matrix: *const Matrix,
    start: Pos(usize),
    end: Pos(usize),
    allocator: std.mem.Allocator,
) !usize {
    var open = std.PriorityQueue(PosDirScore, void, struct {
        fn func(_: void, a: PosDirScore, b: PosDirScore) std.math.Order {
            return std.math.order(a.score, b.score);
        }
    }.func).init(allocator, {});
    defer open.deinit();
    try open.add(.{ .pos = start, .dir_idx = 1, .score = 0 });

    var best: usize = 1e9;

    var distances = std.AutoHashMap(PosDir, usize).init(allocator);
    defer distances.deinit();
    try distances.put(.{ .dir_idx = 1, .pos = start }, 1e9);

    var count: usize = 0;

    while (open.count() > 0) {
        count += 1;
        const current = open.remove();

        // Skip if we have already visited this node with a better score.
        const existing_distance = distances.get(.{ .pos = current.pos, .dir_idx = current.dir_idx });
        if (existing_distance != null and current.score > existing_distance.?) {
            continue;
        } else {
            try distances.put(.{ .pos = current.pos, .dir_idx = current.dir_idx }, current.score);
        }

        // Found a path to the end.
        if (current.pos.eql(end) and current.score <= best) {
            best = current.score;
        }

        for (rot_scores) |rot_score| {
            const next_dir_idx = (current.dir_idx + rot_score.rot) % 4;
            const next_pos = current.pos.addWithOverflow(dirs[next_dir_idx]);
            if (next_pos.overflow == 1) continue;
            if (next_pos.pos.x >= matrix.total_rows or next_pos.pos.y >= matrix.row_size) continue;
            if (matrix.get(next_pos.pos) == '#') continue;

            const next_score = current.score + rot_score.score;
            try open.add(.{ .pos = next_pos.pos, .dir_idx = next_dir_idx, .score = next_score });
        }
    }

    return best;
}

fn day16(allocator: std.mem.Allocator, data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var buffer: [141 * 141 * @sizeOf(u8)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    var matrix = try Matrix.init(141, 141, fba_allocator);
    defer matrix.deinit();

    var start: ?Pos(usize) = null;
    var end: ?Pos(usize) = null;
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
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

    const score = try astar(&matrix, start.?, end.?, allocator);

    return score;
}

const PosDirScoreWithTrace = struct {
    pos: Pos(usize),
    dir_idx: usize,
    score: usize,
    trace: std.ArrayList(Pos(usize)),
};

fn astarWithTrace(
    matrix: *const Matrix,
    start: Pos(usize),
    end: Pos(usize),
    allocator: std.mem.Allocator,
) !usize {
    var open = std.PriorityQueue(PosDirScoreWithTrace, void, struct {
        fn func(_: void, a: PosDirScoreWithTrace, b: PosDirScoreWithTrace) std.math.Order {
            return std.math.order(a.score, b.score);
        }
    }.func).init(allocator, {});
    defer open.deinit();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var seen = AutoHashSet(Pos(usize)).init(allocator);
    defer seen.deinit();

    var start_trace = try std.ArrayList(Pos(usize)).initCapacity(arena_allocator, 1);
    start_trace.appendAssumeCapacity(start);

    try open.add(.{ .pos = start, .dir_idx = 1, .score = 0, .trace = start_trace });

    var best: usize = 1e9;

    var distances = std.AutoHashMap(PosDir, usize).init(allocator);
    defer distances.deinit();
    try distances.put(.{ .dir_idx = 1, .pos = start }, 1e9);

    var count: usize = 0;

    while (open.count() > 0) {
        count += 1;
        const current = open.remove();

        // Skip if we have already visited this node with a better score.
        const existing_distance = distances.get(.{ .pos = current.pos, .dir_idx = current.dir_idx });
        if (existing_distance != null and current.score > existing_distance.?) {
            continue;
        } else {
            try distances.put(.{ .pos = current.pos, .dir_idx = current.dir_idx }, current.score);
        }

        // Found a path to the end.
        if (current.pos.eql(end) and current.score <= best) {
            // Add the path to the seen set.
            for (current.trace.items) |pos| {
                try seen.put(pos, {});
            }

            best = current.score;
        }

        for (rot_scores) |rot_score| {
            const next_dir_idx = (current.dir_idx + rot_score.rot) % 4;
            const next_pos = current.pos.addWithOverflow(dirs[next_dir_idx]);
            if (next_pos.overflow == 1) continue;
            if (next_pos.pos.x >= matrix.total_rows or next_pos.pos.y >= matrix.row_size) continue;
            if (matrix.get(next_pos.pos) == '#') continue;

            var next_trace = try current.trace.clone();
            try next_trace.append(next_pos.pos);

            const next_score = current.score + rot_score.score;
            try open.add(.{
                .pos = next_pos.pos,
                .dir_idx = next_dir_idx,
                .score = next_score,
                .trace = next_trace,
            });
        }
    }

    return seen.count();
}

fn day16p2(allocator: std.mem.Allocator, data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var buffer: [141 * 141 * @sizeOf(u8)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    var matrix = try Matrix.init(141, 141, fba_allocator);
    defer matrix.deinit();

    var start: ?Pos(usize) = null;
    var end: ?Pos(usize) = null;
    while (lines.next()) |line| {
        if (line.len == 0) {
            break;
        }
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

    const tiles = try astarWithTrace(&matrix, start.?, end.?, allocator);

    return tiles;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day16(std.heap.page_allocator, input);
    const p1_time = timer.lap();
    const result_p2 = try day16p2(std.heap.page_allocator, input);
    const p2_time = timer.read();
    std.debug.print("day16 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day16 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{
        .track_allocations = true,
    });
    defer bench.deinit();
    try bench.add("day16 p1", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day16(allocator, input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day16 p2", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day16p2(allocator, input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day16" {
    {
        const result = try day16(std.heap.page_allocator, input_test);
        const expect = 7036;
        std.testing.expect(result == expect) catch |err| {
            std.debug.print("got: {}, expect: {}\n", .{ result, expect });
            return err;
        };
    }

    {
        const result = try day16(std.heap.page_allocator, input_test2);
        const expect = 11048;
        std.testing.expect(result == expect) catch |err| {
            std.debug.print("got: {}, expect: {}\n", .{ result, expect });
            return err;
        };
    }
}

test "day16p2" {
    {
        const result = try day16p2(std.heap.page_allocator, input_test);
        const expect = 45;
        std.testing.expect(result == expect) catch |err| {
            std.debug.print("got: {}, expect: {}\n", .{ result, expect });
            return err;
        };
    }

    {
        const result = try day16p2(std.heap.page_allocator, input_test2);
        const expect = 64;
        std.testing.expect(result == expect) catch |err| {
            std.debug.print("got: {}, expect: {}\n", .{ result, expect });
            return err;
        };
    }
}
