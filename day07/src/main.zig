const std = @import("std");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const Allocator = std.mem.Allocator;

const Crabs = struct {
    const Self = @This();
    allocator: Allocator,
    robots: []u64,

    pub fn load(allocator: Allocator, str: []const u8) !Self {
        var robots = std.ArrayList(u64).init(allocator);
        defer robots.deinit();

        var iter = std.mem.tokenize(u8, str, ",");
        while (iter.next()) |num| {
            if (num.len != 0) {
                const trimmed = std.mem.trimRight(u8, num, "\n");
                const value = try std.fmt.parseInt(u64, trimmed, 10);
                try robots.append(value);
            }
        }

        return Self{ .allocator = allocator, .robots = robots.toOwnedSlice() };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.robots);
    }

    pub fn cheapestAlignment(self: *Self) !u64 {
        std.sort.sort(u64, self.robots, {}, comptime std.sort.asc(u64));
        const medianIdx = self.robots.len / 2;
        const median: u64 = self.robots[medianIdx];
        var total: u64 = 0;
        for (self.robots) |r| {
            if (r > median) {
                total += r - median;
            } else {
                total += median - r;
            }
        }
        return total;
    }
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const str = @embedFile("../input.txt");
    var c = try Crabs.load(allocator, str);
    defer c.deinit();

    const stdout = std.io.getStdOut().writer();

    const part1 = try c.cheapestAlignment();
    try stdout.print("Part 1: {d}\n", .{part1});
}

test "part1 test" {
    const str = @embedFile("../test.txt");
    var c = try Crabs.load(test_allocator, str);
    defer c.deinit();

    const score = try c.cheapestAlignment();
    std.debug.print("\nScore={d}\n", .{score});
    try expect(37 == score);
}
