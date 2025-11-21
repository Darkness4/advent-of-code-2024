const std = @import("std");

const zbench = @import("zbench");

const input = std.mem.trimRight(u8, @embedFile("day17.txt"), "\n");
const input_test = std.mem.trimRight(u8, @embedFile("day17_test.txt"), "\n");
const input_test2 = std.mem.trimRight(u8, @embedFile("day17_test2.txt"), "\n");

const register_prefix_len = "Register A: ".len;
const program_prefix_len = "Program: ".len;

/// scanNumber scans a number in a string. Much more efficient than std.fmt.parseInt
/// since we ignore '-' and other characters that could define a number (like hex, etc...).
/// A very naive implementation, yet the fastest for Advent of Code.
fn scanNumber(comptime T: type, data: []const u8, idx: *usize) ?T {
    var number: ?T = null;
    if (idx.* >= data.len) return number;
    var char = data[idx.*];
    while (char >= '0' and char <= '9') {
        const v = char - '0';
        number = if (number) |n| n * 10 + (char - '0') else v;
        idx.* += 1;
        if (idx.* >= data.len) break;
        char = data[idx.*];
    }
    return number;
}

// op handle opcode.
fn op(opcode: u8, opcode_idx: *usize, operand: usize, a: *usize, b: *usize, c: *usize) ?usize {
    // std.debug.print("op: {c}, operand: {}, a: {}, b: {}, c: {}\n", .{ opcode, operand, a.*, b.*, c.* });
    switch (opcode) {
        '0' => { // adv
            const combo_operand = interpret_combo_operand(operand, a, b, c);
            a.* >>= @as(u6, @intCast(combo_operand));
            opcode_idx.* += 2;
        },
        '1' => { // bxl
            b.* ^= operand;
            opcode_idx.* += 2;
        },
        '2' => { //bst
            b.* = interpret_combo_operand(operand, a, b, c) & 7;
            opcode_idx.* += 2;
        },
        '3' => { // jnz
            if (a.* == 0) {
                opcode_idx.* += 2;
                return null;
            }
            opcode_idx.* = operand;
        },
        '4' => { // bxc
            b.* ^= c.*;
            opcode_idx.* += 2;
        },
        '5' => { // out
            opcode_idx.* += 2;
            return interpret_combo_operand(operand, a, b, c) & 7;
        },
        '6' => { // bdv
            b.* = a.* >> @as(u6, @intCast(interpret_combo_operand(operand, a, b, c)));
            opcode_idx.* += 2;
        },
        '7' => { // cdv
            c.* = a.* >> @as(u6, @intCast(interpret_combo_operand(operand, a, b, c)));
            opcode_idx.* += 2;
        },
        else => unreachable,
    }
    return null;
}

test "op" {
    {
        var a: usize = 0;
        var b: usize = 0;
        var c: usize = 9;
        var scan_idx: usize = 0;
        const res = op('2', &scan_idx, 6, &a, &b, &c);
        try std.testing.expect(b == 1);
        try std.testing.expect(res == null);
    }
    {
        var a: usize = 0;
        var b: usize = 29;
        var c: usize = 0;
        var scan_idx: usize = 0;
        const res = op('1', &scan_idx, 7, &a, &b, &c);
        try std.testing.expect(b == 26);
        try std.testing.expect(res == null);
    }
}

fn interpret_combo_operand(operand: usize, a: *usize, b: *usize, c: *usize) usize {
    if (operand <= 3) return operand; // Literal
    return switch (operand) {
        4 => a.*,
        5 => b.*,
        6 => c.*,
        else => unreachable,
    };
}

fn process(
    instructions: []const u8,
    a: *usize,
    b: *usize,
    c: *usize,
    result_buf: []u8,
    result_cap: *usize,
) void {
    var cursor: usize = 0;
    while (cursor < instructions.len) {
        const opcode = instructions[cursor];
        const operand = instructions[cursor + 1] - '0';
        const result = op(opcode, &cursor, operand, a, b, c);
        if (result != null) {
            result_buf[result_cap.*] = @as(u8, @intCast(result.? + '0'));
            result_cap.* += 1;
        }
    }
}

test "process" {
    {
        var a: usize = 0;
        var b: usize = 0;
        var c: usize = 9;
        const instructions = "26";
        var result_buf = [_]u8{0} ** 16;
        var result_cap: usize = 0;
        process(instructions, &a, &b, &c, &result_buf, &result_cap);
        try std.testing.expect(b == 1);
        try std.testing.expect(result_cap == 0);
    }
    {
        var a: usize = 10;
        var b: usize = 0;
        var c: usize = 0;
        const instructions = "505154";
        var result_buf = [_]u8{0} ** 16;
        var result_cap: usize = 0;
        process(instructions, &a, &b, &c, &result_buf, &result_cap);
        const result = result_buf[0..result_cap];
        try std.testing.expect(std.mem.eql(u8, result, "012"));
    }
    {
        var a: usize = 2024;
        var b: usize = 0;
        var c: usize = 0;
        const instructions = "015430";
        var result_buf = [_]u8{0} ** 16;
        var result_cap: usize = 0;
        process(instructions, &a, &b, &c, &result_buf, &result_cap);
        const result = result_buf[0..result_cap];
        try std.testing.expect(std.mem.eql(u8, result, "42567777310"));
        try std.testing.expect(a == 0);
    }
    {
        var a: usize = 0;
        var b: usize = 29;
        var c: usize = 0;
        const instructions = "17";
        var result_buf = [_]u8{0} ** 16;
        var result_cap: usize = 0;
        process(instructions, &a, &b, &c, &result_buf, &result_cap);
        try std.testing.expect(b == 26);
    }
    {
        var a: usize = 0;
        var b: usize = 2024;
        var c: usize = 43690;
        const instructions = "40";
        var result_buf = [_]u8{0} ** 16;
        var result_cap: usize = 0;
        _ = process(instructions, &a, &b, &c, &result_buf, &result_cap);
        try std.testing.expect(b == 44354);
    }
}

fn day17(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var instructions_buf = [_]u8{0} ** 16;
    var cap: usize = 0;

    var line = lines.next().?;
    var scan_idx = register_prefix_len;
    var a = scanNumber(usize, line, &scan_idx) orelse unreachable;
    line = lines.next().?;
    scan_idx = register_prefix_len;
    var b = scanNumber(usize, line, &scan_idx) orelse unreachable;
    line = lines.next().?;
    scan_idx = register_prefix_len;
    var c = scanNumber(usize, line, &scan_idx) orelse unreachable;
    _ = lines.next().?;
    line = lines.next().?;
    scan_idx = program_prefix_len;
    while (scan_idx < line.len) {
        instructions_buf[cap] = line[scan_idx];
        scan_idx += 2;
        cap += 1;
    }
    const instructions = instructions_buf[0..cap];

    scan_idx = 0;
    var result_buf = [_]u8{0} ** 100;
    var result_cap: usize = 0;
    process(instructions, &a, &b, &c, &result_buf, &result_cap);
    const res = result_buf[0..result_cap];
    return scanNumber(usize, res, &scan_idx) orelse unreachable;
}

// Build "a" based on the generated digits.
fn find_a(a: usize, depth: usize, instructions: []const u8) usize {
    // Our "a" register is creating an output that is the same as the instructions.
    if (depth == instructions.len) {
        return a;
    }

    // Brute force possible values for a.
    for (0..8) |i| {
        var output_buf = [_]u8{0} ** 100;
        var output_cap: usize = 0;
        var a_mut = a * 8 + i;
        var b: usize = 0;
        var c: usize = 0;
        process(instructions, &a_mut, &b, &c, &output_buf, &output_cap);
        const output = output_buf[0..output_cap];

        // We are trying to find a. Output is being built to match instructions.
        // output: 0
        // output: 30
        // output: 530
        // output: 5530
        // output: 45530
        // output: 445530
        // output: 3445530
        // output: ...
        if (output.len > 0 and output[0] == instructions[instructions.len - depth - 1]) {
            const res = find_a(a * 8 + i, depth + 1, instructions);
            if (res != 0) {
                return res;
            }
        }
    }

    return 0;
}

fn day17p2(data: []const u8) !usize {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var instructions_buf = [_]u8{0} ** 16;
    var cap: usize = 0;

    _ = lines.next().?;
    _ = lines.next().?;
    _ = lines.next().?;
    _ = lines.next().?;
    const line = lines.next().?;
    var scan_idx = program_prefix_len;
    while (scan_idx < line.len) {
        instructions_buf[cap] = line[scan_idx];
        scan_idx += 2;
        cap += 1;
    }
    const instructions = instructions_buf[0..cap];

    return find_a(0, 0, instructions);
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    const result_p1 = try day17(input);
    const p1_time = timer.lap();
    const result_p2 = try day17p2(input);
    const p2_time = timer.read();

    std.debug.print("day17 p1: {} (you have to put commas between digits) in {}ns\n", .{ result_p1, p1_time });
    std.debug.print("day17 p2: {} in {}ns\n", .{ result_p2, p2_time });

    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();
    try bench.add("day17 p1", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day17(input) catch unreachable;
        }
    }.call, .{});
    try bench.add("day17 p2", struct {
        pub fn call(_: std.mem.Allocator) void {
            _ = day17p2(input) catch unreachable;
        }
    }.call, .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try bench.run(stdout);
    try stdout.flush();
}

test "day17" {
    const result = try day17(input_test);
    const expect = 4635635210;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}

test "day17p2" {
    const result = try day17p2(input_test2);
    const expect = 117440;
    std.testing.expect(result == expect) catch |err| {
        std.debug.print("got: {}, expect: {}\n", .{ result, expect });
        return err;
    };
}
