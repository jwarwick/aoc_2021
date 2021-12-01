const std = @import("std");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = &gpa.allocator;

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    const contents = try file.reader().readAllAlloc(allocator, 409600);
    defer allocator.free(contents);

    var values = try parseInput(allocator, contents);
    defer allocator.free(values);

    const stdout = std.io.getStdOut().writer();

    const part1 = depthIncrease(&values);
    try stdout.print("Part 1: {d}\n", .{part1});
}

fn parseInput(allocator: *std.mem.Allocator, str: []const u8) ![]const u64 {
    var nums = std.ArrayList(u64).init(allocator);
    defer nums.deinit();

    var iter = std.mem.split(u8, str, "\n");
    while (iter.next()) |str_value| {
        // std.log.debug("line: {s}", .{str_value});
        if (str_value.len != 0) {
            const value = std.fmt.parseInt(u64, str_value, 10) catch |err|
                {
                std.log.debug("error: {}", .{err});
                continue;
            };
            try nums.append(value);
        }
    }

    return nums.toOwnedSlice();
}

fn depthIncrease(depths: *[]const u64) !i64 {
    var count: i64 = 0;
    var last = depths.*[0];
    for (depths.*) |curr| {
        if (curr > last) {
            count = count + 1;
        }
        last = curr;
    }
    return count;
}

test "part1 test" {
    const test_input =
        \\199
        \\200
        \\208
        \\210
        \\200
        \\207
        \\240
        \\269
        \\260
        \\263
    ;
    const test_values = [_]u64{
        199,
        200,
        208,
        210,
        200,
        207,
        240,
        269,
        260,
        263,
    };
    var values = try parseInput(test_allocator, test_input);
    defer test_allocator.free(values);

    try expect(std.mem.eql(u64, &test_values, values));

    const result = try depthIncrease(&values);
    try std.testing.expect(7 == result);
}
