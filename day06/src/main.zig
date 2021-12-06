const std = @import("std");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const Allocator = std.mem.Allocator;

const School = struct {
    const Self = @This();
    allocator: Allocator,
    fish: [9]u64,

    pub fn load(allocator: Allocator, str: []const u8) !Self {
        var fish = [_]u64{0} ** 9;
        var iter = std.mem.tokenize(u8, str, ",");

        while (iter.next()) |num| {
            if (num.len != 0) {
                const trimmed = std.mem.trimRight(u8, num, "\n");
                const value = try std.fmt.parseInt(u64, trimmed, 10);
                fish[value] += 1;
            }
        }

        return Self{ .allocator = allocator, .fish = fish };
    }

    pub fn deinit(_: *Self) void {}

    pub fn population(self: *Self, age: u64) !u64 {
        var curr: u64 = 0;
        var pop: [9]u64 = undefined;

        for (self.fish) |f, idx| {
            pop[idx] = f;
        }

        while (curr < age) : (curr += 1) {
            var spawnCount = pop[0];
            var idx: u64 = 0;
            while (idx < 8) : (idx += 1) {
                pop[idx] = pop[idx + 1];
            }
            pop[8] = spawnCount;
            pop[6] += spawnCount;
        }

        var total: u64 = 0;
        for (pop) |v| {
            total += v;
        }

        return total;
    }
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const str = @embedFile("../input.txt");
    var s = try School.load(allocator, str);
    defer s.deinit();

    const stdout = std.io.getStdOut().writer();

    const part1 = try s.population(80);
    try stdout.print("Part 1: {d}\n", .{part1});

    const part2 = try s.population(256);
    try stdout.print("Part 2: {d}\n", .{part2});
}

test "part1 test" {
    const str = @embedFile("../test.txt");
    var s = try School.load(test_allocator, str);
    defer s.deinit();

    const score = try s.population(80);
    std.debug.print("\nScore={d}\n", .{score});
    try expect(5934 == score);
}

test "part2 test" {
    const str = @embedFile("../test.txt");
    var s = try School.load(test_allocator, str);
    defer s.deinit();

    const score = try s.population(256);
    std.debug.print("\nScore={d}\n", .{score});
    try expect(26984457539 == score);
}
