const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day3.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day3_test.txt"), "\n");

fn scanNumber(data: []const u8, idx: *usize) !u64 {
    var char = data[idx.*];
    var number: u64 = 0;
    while (char >= '0' and char <= '9') {
        number = number * 10 + (char - '0');
        try next(data, idx);
        char = data[idx.*];
    }
    return number;
}

fn next(data: []const u8, idx: *usize) !void {
    idx.* += 1;
    if (idx.* >= data.len) return error.EOF;
}

/// Good 'ol lexer. This is the method used to scan a file in programming languages.
/// I used the method used by Go to scan the source code in token.
/// We don't have to be clever about parenthesis, so the tokens are simply:
/// - 'mul(' with its ')'.
/// - Numbers.
/// Compared to real programming languages, the trash is ignored.
///
/// The implementation is the following:
///
/// 1. Check for the first char of the token. ('m')
/// 2. The first char is confirmed, so we read ahead to check the next char. ('ul(')
/// 3. We scan the integer. In a real world scenario, we would check the many format of a number.
///    Here's, we simply check for digits.
/// 4. Read the comma.
/// 5. Scan the second integer.
/// 6. Read the closing parenthesis.
/// 7. Statement is valid. Compute the multiplication and done.
fn day3(data: []const u8) !u64 {
    var acc: u64 = 0;
    var idx: usize = 0;
    scan: while (idx < data.len) : (idx += 1) {
        redo: switch (data[idx]) {
            'm' => { // is literal and is maybe 'mul'
                next(data, &idx) catch break :scan;
                inline for ("ul(") |expect| {
                    if (data[idx] != expect) break :redo;
                    next(data, &idx) catch break :scan;
                }

                // Found 'mul(', now scan for number
                const a = scanNumber(data, &idx) catch break :scan;
                if (data[idx] != ',') break :redo;
                next(data, &idx) catch break :scan;

                const b = scanNumber(data, &idx) catch break :scan;
                if (data[idx] != ')') break :redo;
                acc += a * b;
            },
            else => {},
        }
    }

    return acc;
}

/// Another lexer.
fn day3p2(data: []const u8) !usize {
    var acc: u64 = 0;
    var idx: usize = 0;
    var enabled: bool = true;
    scan: while (idx < data.len) : (idx += 1) {
        redo: switch (data[idx]) {
            'm' => { // is literal and is maybe 'mul'
                next(data, &idx) catch break :scan;
                inline for ("ul(") |expect| {
                    if (data[idx] != expect) break :redo;
                    next(data, &idx) catch break :scan;
                }
                // Found 'mul(', now scan for number
                const a = scanNumber(data, &idx) catch break :scan;
                if (data[idx] != ',') break :redo;
                next(data, &idx) catch break :scan;
                const b = scanNumber(data, &idx) catch break :scan;
                if (data[idx] != ')') break :redo;
                if (enabled) acc += a * b;
            },
            'd' => { // is literal and is maybe 'do()' or 'don't()'
                next(data, &idx) catch break :scan;
                if (data[idx] != 'o') break :redo;
                next(data, &idx) catch break :scan;
                switch (data[idx]) {
                    '(' => {
                        // Found 'do('
                        next(data, &idx) catch break :scan;
                        if (data[idx] != ')') break :redo;
                        enabled = true;
                    },
                    'n' => {
                        next(data, &idx) catch break :scan;
                        inline for ("'t(") |expect| {
                            if (data[idx] != expect) break :redo;
                            next(data, &idx) catch break :scan;
                        }
                        // Found 'don't('
                        if (data[idx] != ')') break :redo;
                        enabled = false;
                    },
                    else => {},
                }
            },
            else => {},
        }
    }

    return acc;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day3(input);
    const p1_time = timer.lap();
    const result_p2 = try day3p2(input);
    const p2_time = timer.read();
    std.debug.print("day3 p1: {} in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day3 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day3 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day3(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day3 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day3p2(input) catch unreachable;
        }
    }.call, .{});
    try bench.run(std.io.getStdOut().writer());
}

test "day3" {
    const result = try day3(input_test);
    const expect = 161;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day3p2" {
    const result = try day3p2(input_test);
    const expect = 48;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
