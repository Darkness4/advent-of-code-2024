const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day9.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day9_test.txt"), "\n");

const Bucket = struct {
    id: ?usize,
    capacity: usize,
};

// Using big buffers as illustrated in the intro.
fn day9(data: []const u8) !usize {
    var buffer = [_]usize{0} ** 100000;

    // Step 1: Parse input
    var write_idx: usize = 0;
    for (0.., data) |idx, c| {
        if (idx % 2 == 0) {
            for (0..@intCast(c - '0')) |_| {
                buffer[write_idx] = (idx / 2) + 1;
                write_idx += 1;
            }
        } else {
            for (0..@intCast(c - '0')) |_| {
                buffer[write_idx] = 0;
                write_idx += 1;
            }
        }
    }
    const cap = write_idx;

    // Step 2: Execute litterally the algorithm.
    var filled_idx: usize = cap - 1;
    var empty_idx: usize = 0;
    while (empty_idx < filled_idx) : (empty_idx += 1) {
        const empty = buffer[empty_idx];
        const filled = buffer[filled_idx];

        if (empty == 0) {
            buffer[empty_idx] = filled;
            buffer[filled_idx] = 0;

            while (buffer[filled_idx] == 0) filled_idx -= 1;
        }
    }

    var acc: usize = 0;
    for (0..cap) |idx| {
        if (buffer[idx] == 0) {
            break;
        }
        acc += (buffer[idx] - 1) * idx;
    }
    return acc;
}

// Making buckets. Everything is given in the intro.
// Using this method is slower than the previous one but is easier to implement.
fn day9p2(data: []const u8) !usize {
    var buckets = std.BoundedArray(Bucket, 100000){};

    // Step 1: Parse input
    for (0.., data) |idx, c| {
        if (idx % 2 == 0) {
            buckets.appendAssumeCapacity(.{ .id = idx / 2, .capacity = @intCast(c - '0') });
        } else {
            buckets.appendAssumeCapacity(.{ .id = null, .capacity = @intCast(c - '0') });
        }
    }

    // Step 2: Execute litterally the algorithm.
    var filled_bucket_idx: usize = buckets.len;
    while (filled_bucket_idx > 0) {
        filled_bucket_idx -= 1;
        var empty_bucket_idx: usize = 1;
        while (empty_bucket_idx < filled_bucket_idx) : (empty_bucket_idx += 1) {
            const empty_bucket = &buckets.buffer[empty_bucket_idx];
            const filled_bucket = &buckets.buffer[filled_bucket_idx];

            if (empty_bucket.id == null and filled_bucket.id != null and filled_bucket.capacity <= empty_bucket.capacity) {
                const id = filled_bucket.id;
                filled_bucket.*.id = null;
                empty_bucket.*.capacity -= filled_bucket.capacity; // Reduce capacity of empty bucket.
                try buckets.insert(empty_bucket_idx, .{ .id = id, .capacity = filled_bucket.capacity });
            }
        }
    }

    var acc: usize = 0;
    var idx: usize = 0;
    for (buckets.slice()) |item| {
        if (item.id == null) {
            idx += item.capacity;
            continue;
        }
        for (0..item.capacity) |block_idx| {
            acc += (block_idx + idx) * item.id.?;
        }
        idx += item.capacity;
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day9(input);
    const p1_time = timer.lap();
    const result_p2 = try day9p2(input);
    const p2_time = timer.read();
    std.debug.print("day9 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day9 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{
        .time_budget_ns = 10e9,
    });
    defer bench.deinit();
    try bench.add("day9 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day9(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day9 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day9p2(input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day9" {
    const result = try day9(input_test);
    const expect = 1928;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day9p2" {
    const result = try day9p2(input_test);
    const expect = 2858;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
