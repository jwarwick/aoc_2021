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

    fn moveCost(dist: u64) u64 {
        return ((dist + 1) * dist) / 2;
    }

    fn absDiff(a: u64, b: u64) u64 {
        if (a > b) {
            return a - b;
        } else {
            return b - a;
        }
    }

    fn costAtPoint(locs: []u64, point: u64) u64 {
        var total: u64 = 0;
        for (locs) |l| {
            total += moveCost(absDiff(l, point));
        }
        return total;
    }

    pub fn followGradient(locs: []u64, currLoc: u64, cost: u64) u64 {
        var costLeft: u64 = 0;
        if (currLoc == 0) {
            costLeft = 100000000;
        } else {
            costLeft = costAtPoint(locs, currLoc - 1);
        }
        const costRight = costAtPoint(locs, currLoc + 1);
        if (cost <= costLeft and cost <= costRight) {
            return cost;
        }

        if (costLeft < cost) {
            return followGradient(locs, currLoc - 1, costLeft);
        } else {
            return followGradient(locs, currLoc + 1, costRight);
        }
    }

    pub fn cheapestAlignmentWithCost(self: *Self) !u64 {
        std.sort.sort(u64, self.robots, {}, comptime std.sort.asc(u64));
        const medianIdx = self.robots.len / 2;
        const median: u64 = self.robots[medianIdx];
        const cost = costAtPoint(self.robots, median);
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
