const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day8.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day8_test.txt"), "\n");

const Pos = struct {
    x: usize,
    y: usize,

    fn compute_antinode_pos_by_symmetry(self: Pos, other: Pos, max: usize) !Pos {
        const x, var overflow = @subWithOverflow(2 * self.x, other.x);
        if (overflow == 1 or x >= max) {
            return error.OutOfBounds;
        }
        const y, overflow = @subWithOverflow(2 * self.y, other.y);
        if (overflow == 1 or y >= max) {
            return error.OutOfBounds;
        }
        return .{ .x = x, .y = y };
    }

    /// This returns an owned slice, no need to deinit it.
    fn compute_antinode_pos_by_repeat(self: Pos, other: Pos, max: usize, allocator: std.mem.Allocator) ![]Pos {
        var list = try std.ArrayList(Pos).initCapacity(allocator, max);
        defer list.deinit();

        for (0..max) |n| {
            const x, var overflow = @subWithOverflow((n + 1) * self.x, n * other.x);
            if (overflow == 1 or x >= max) {
                return list.toOwnedSlice();
            }
            const y, overflow = @subWithOverflow((n + 1) * self.y, n * other.y);
            if (overflow == 1 or y >= max) {
                return list.toOwnedSlice();
            }
            list.appendAssumeCapacity(.{ .x = x, .y = y });
        }

        return list.toOwnedSlice();
    }
};

fn AutoHashSet(comptime T: type) type {
    return std.AutoHashMap(T, void);
}

// It's math. Save HashMap by type, queue the nodes, loop over it, compute coords, exclude out of bounds, and count.
// Can easily be done using functional programming.
fn day8(allocator: std.mem.Allocator, data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var map = std.AutoHashMap(u8, std.ArrayList(Pos)).init(allocator);
    defer {
        // Properly deinit all the ArrayLists before deiniting the map
        var iter = map.valueIterator();
        while (iter.next()) |list| {
            list.deinit();
        }
        map.deinit();
    }

    var buffer: [50 * 50 * @sizeOf(Pos)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    // Read the whole map
    var x: usize = 0;
    while (lines.next()) |line| : (x += 1) {
        for (0.., line) |y, c| {
            if (c != '.') {
                const v = try map.getOrPut(c);
                if (!v.found_existing) {
                    v.value_ptr.* = std.ArrayList(Pos).init(fba_allocator);
                }
                try v.value_ptr.append(.{ .x = x, .y = y });
            }
        }
    }
    const size = x;

    // Compute every antinode positions
    var antinodes = AutoHashSet(Pos).init(allocator);
    var it = map.valueIterator();
    while (it.next()) |list| {
        for (0.., list.items) |i, a| {
            for (i + 1..list.items.len) |j| {
                const b = list.items[j];
                if (a.compute_antinode_pos_by_symmetry(b, size)) |pos| {
                    try antinodes.put(pos, {});
                } else |_| {}

                if (b.compute_antinode_pos_by_symmetry(a, size)) |pos| {
                    try antinodes.put(pos, {});
                } else |_| {}
            }
        }
    }

    return antinodes.count();
}

fn day8p2(allocator: std.mem.Allocator, data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var map = std.AutoHashMap(u8, std.ArrayList(Pos)).init(allocator);
    defer {
        // Properly deinit all the ArrayLists before deiniting the map
        var iter = map.valueIterator();
        while (iter.next()) |list| {
            list.deinit();
        }
        map.deinit();
    }

    var buffer: [50 * 50 * @sizeOf(Pos)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fba_allocator = fba.allocator();

    // Read the whole map
    var x: usize = 0;
    while (lines.next()) |line| : (x += 1) {
        for (0.., line) |y, c| {
            if (c != '.') {
                const v = try map.getOrPut(c);
                if (!v.found_existing) {
                    v.value_ptr.* = std.ArrayList(Pos).init(fba_allocator);
                }
                try v.value_ptr.append(.{ .x = x, .y = y });
            }
        }
    }
    const size = x;

    // Compute every antinode positions
    var antinodes = AutoHashSet(Pos).init(allocator);
    var it = map.valueIterator();
    while (it.next()) |list| {
        for (0.., list.items) |i, a| {
            for (i + 1..list.items.len) |j| {
                const b = list.items[j];
                {
                    const poss = try a.compute_antinode_pos_by_repeat(b, size, allocator);
                    for (poss) |pos| {
                        try antinodes.put(pos, {});
                    }
                }

                {
                    const poss = try b.compute_antinode_pos_by_repeat(a, size, allocator);
                    for (poss) |pos| {
                        try antinodes.put(pos, {});
                    }
                }
            }
        }
    }

    return antinodes.count();
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day8(std.heap.page_allocator, input);
    const p1_time = timer.lap();
    const result_p2 = try day8p2(std.heap.page_allocator, input);
    const p2_time = timer.read();
    std.debug.print("day8 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day8 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{
        .track_allocations = true,
    });
    defer bench.deinit();
    try bench.add("day8 p1", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day8(allocator, input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day8 p2", struct {
        pub fn call(allocator: std.mem.Allocator) void {
            _ = day8p2(allocator, input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day8" {
    const result = try day8(std.heap.page_allocator, input_test);
    const expect = 14;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day8p2" {
    const result = try day8p2(std.heap.page_allocator, input_test);
    const expect = 34;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
