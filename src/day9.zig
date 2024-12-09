const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day9.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day9_test.txt"), "\n");

const Bucket = struct {
    id: ?usize,
    capacity: usize,
};

// Making buckets. Everything is given in the intro.
fn day9(data: []const u8) !usize {
    var buffer: [100000 * @sizeOf(Bucket)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var buckets = try std.ArrayList(Bucket).initCapacity(allocator, 100000);
    defer buckets.deinit();

    // Step 1: Parse input
    for (0.., data) |idx, c| {
        if (idx % 2 == 0) {
            buckets.appendAssumeCapacity(.{ .id = idx / 2, .capacity = @as(usize, @intCast(c - '0')) });
        } else {
            buckets.appendAssumeCapacity(.{ .id = null, .capacity = @as(usize, @intCast(c - '0')) });
        }
    }

    // Step 2: Execute litterally the algorithm.
    var filled_bucket_idx: usize = buckets.items.len;
    while (filled_bucket_idx > 0) {
        filled_bucket_idx -= 1;
        var empty_bucket_idx: usize = 1;
        while (empty_bucket_idx < filled_bucket_idx) : (empty_bucket_idx += 1) {
            const empty_bucket = &buckets.items[empty_bucket_idx];
            const filled_bucket = &buckets.items[filled_bucket_idx];

            if (empty_bucket.id == null and filled_bucket.id != null) {
                if (filled_bucket.capacity <= empty_bucket.capacity) {
                    const id = filled_bucket.id;
                    filled_bucket.*.id = null;
                    empty_bucket.*.capacity -= filled_bucket.capacity; // Reduce capacity of empty bucket.
                    buckets.insertAssumeCapacity(empty_bucket_idx, .{ .id = id, .capacity = filled_bucket.capacity });
                } else {
                    empty_bucket.*.id = filled_bucket.id;
                    filled_bucket.*.capacity -= empty_bucket.capacity; // Reduce capacity of filled bucket.
                }
            }
        }
    }

    var acc: usize = 0;
    var idx: usize = 0;
    for (buckets.items) |item| {
        if (item.id == null) {
            // idx += item.capacity; // No need, everything is compressed.
            break;
        }
        for (0..item.capacity) |block_idx| {
            acc += (block_idx + idx) * item.id.?;
        }
        idx += item.capacity;
    }

    return acc;
}

// Making buckets. Everything is given in the intro.
fn day9p2(data: []const u8) !usize {
    var buffer: [100000 * @sizeOf(Bucket)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var buckets = try std.ArrayList(Bucket).initCapacity(allocator, 100000);
    defer buckets.deinit();

    // Step 1: Parse input
    for (0.., data) |idx, c| {
        if (idx % 2 == 0) {
            buckets.appendAssumeCapacity(.{ .id = idx / 2, .capacity = @as(usize, @intCast(c - '0')) });
        } else {
            buckets.appendAssumeCapacity(.{ .id = null, .capacity = @as(usize, @intCast(c - '0')) });
        }
    }

    // Step 2: Execute litterally the algorithm.
    var filled_bucket_idx: usize = buckets.items.len;
    while (filled_bucket_idx > 0) {
        filled_bucket_idx -= 1;
        var empty_bucket_idx: usize = 1;
        while (empty_bucket_idx < filled_bucket_idx) : (empty_bucket_idx += 1) {
            const empty_bucket = &buckets.items[empty_bucket_idx];
            const filled_bucket = &buckets.items[filled_bucket_idx];

            if (empty_bucket.id == null and filled_bucket.id != null and filled_bucket.capacity <= empty_bucket.capacity) {
                const id = filled_bucket.id;
                filled_bucket.*.id = null;
                empty_bucket.*.capacity -= filled_bucket.capacity; // Reduce capacity of empty bucket.
                buckets.insertAssumeCapacity(empty_bucket_idx, .{ .id = id, .capacity = filled_bucket.capacity });
            }
        }
    }

    var acc: usize = 0;
    var idx: usize = 0;
    for (buckets.items) |item| {
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

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
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
