const std = @import("std");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const Allocator = std.mem.Allocator;

const Crabs = struct {
    const Self = @This();
    allocator: Allocator,
    robots: []i64,

    pub fn load(allocator: Allocator, str: []const u8) !Self {
        var robots = std.ArrayList(i64).init(allocator);
        defer robots.deinit();

        var iter = std.mem.tokenize(u8, str, ",");
        while (iter.next()) |num| {
            if (num.len != 0) {
                const trimmed = std.mem.trimRight(u8, num, "\n");
                const value = try std.fmt.parseInt(i64, trimmed, 10);
                try robots.append(value);
            }
        }

        return Self{ .allocator = allocator, .robots = robots.toOwnedSlice() };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.robots);
    }

    pub fn cheapestAlignment(self: *Self) !i64 {
        std.sort.sort(i64, self.robots, {}, comptime std.sort.asc(i64));
        const medianIdx = @divFloor(self.robots.len, 2);
        const median: i64 = self.robots[medianIdx];
        var total: i64 = 0;
        for (self.robots) |r| {
            total += try std.math.absInt(r - median);
        }
        return total;
    }

    fn moveCost(dist: i64) i64 {
        return @divFloor((dist + 1) * dist, 2);
    }

    fn costAtPoint(locs: []i64, point: i64) !i64 {
        var total: i64 = 0;
        for (locs) |l| {
            total += moveCost(try std.math.absInt(l - point));
        }
        return total;
    }

    pub fn followGradient(locs: []i64, currLoc: i64, cost: i64) !i64 {
        var costLeft: i64 = 0;
        if (currLoc <= 0) {
            costLeft = std.math.maxInt(i64);
        } else {
            costLeft = try costAtPoint(locs, currLoc - 1);
        }
        const costRight = try costAtPoint(locs, currLoc + 1);
        if (cost <= costLeft and cost <= costRight) {
            return cost;
        }

        if (costLeft < cost) {
            return followGradient(locs, currLoc - 1, costLeft);
        } else {
            return followGradient(locs, currLoc + 1, costRight);
        }
    }

    pub fn cheapestAlignmentWithCost(self: *Self) !i64 {
        std.sort.sort(i64, self.robots, {}, comptime std.sort.asc(i64));
        const medianIdx = self.robots.len / 2;
        const median: i64 = self.robots[medianIdx];
        const cost = try costAtPoint(self.robots, median);
        return followGradient(self.robots, median, cost);
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

    const part2 = try c.cheapestAlignmentWithCost();
    try stdout.print("Part 2: {d}\n", .{part2});
}

test "part1 test" {
    const str = @embedFile("../test.txt");
    var c = try Crabs.load(test_allocator, str);
    defer c.deinit();

    const score = try c.cheapestAlignment();
    std.debug.print("\nScore={d}\n", .{score});
    try expect(37 == score);
}

test "part2 test" {
    const str = @embedFile("../test.txt");
    var c = try Crabs.load(test_allocator, str);
    defer c.deinit();

    const score = try c.cheapestAlignmentWithCost();
    std.debug.print("\nScore={d}\n", .{score});
    try expect(168 == score);
}
