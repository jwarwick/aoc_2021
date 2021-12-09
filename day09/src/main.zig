const std = @import("std");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const Allocator = std.mem.Allocator;

const Point = struct {
    x: i64,
    y: i64,
};

const HeightMap = struct {
    const Self = @This();
    allocator: Allocator,
    heights: []u8,
    width: i64,
    height: i64,

    pub fn load(allocator: Allocator, str: []const u8) !Self {
        var heights = std.ArrayList(u8).init(allocator);
        var iter = std.mem.split(u8, str, "\n");

        var rowCount: i64 = 0;
        var colCount: i64 = 0;

        while (iter.next()) |row| {
            if (row.len != 0) {
                if (colCount == 0) {
                    colCount = @intCast(i64, row.len);
                }
                const trimmed = std.mem.trimRight(u8, row, "\n");
                for (trimmed) |c| {
                    const value = c - '0';
                    try heights.append(value);
                }
                rowCount += 1;
            }
        }

        return Self{ .allocator = allocator, .heights = heights.toOwnedSlice(), .width = colCount, .height = rowCount };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.heights);
    }

    fn offset(self: Self, x: i64, y: i64) ?i64 {
        if (x < 0 or y < 0) return null;
        if (x >= self.width) return null;
        if (y >= self.height) return null;

        return (y * self.width) + x;
    }

    fn pointHeight(self: Self, p: Point) i64 {
        const idx = self.offset(p.x, p.y) orelse return 9;
        return self.heights[@intCast(usize, idx)];
    }

    fn neighbors(self: Self, x: i64, y: i64) ![]Point {
        var pts = std.ArrayList(Point).init(self.allocator);
        try pts.append(Point{ .x = x, .y = y - 1 });
        try pts.append(Point{ .x = x, .y = y + 1 });
        try pts.append(Point{ .x = x - 1, .y = y });
        try pts.append(Point{ .x = x + 1, .y = y });
        return pts.toOwnedSlice();
    }

    fn isLowPoint(self: Self, x: i64, y: i64) !bool {
        const h = self.pointHeight(Point{ .x = x, .y = y });
        var neighCount: u8 = 0;
        var neighs = try self.neighbors(x, y);
        defer self.allocator.free(neighs);
        for (neighs) |n| {
            if (h < self.pointHeight(n)) neighCount += 1;
        }
        return neighCount == 4;
    }

    fn lowPoints(self: Self) ![]Point {
        var pts = std.ArrayList(Point).init(self.allocator);
        var row: i64 = 0;
        while (row < self.height) : (row += 1) {
            var col: i64 = 0;
            while (col < self.width) : (col += 1) {
                if (try self.isLowPoint(col, row)) {
                    try pts.append(Point{ .x = col, .y = row });
                }
            }
        }
        return pts.toOwnedSlice();
    }

    pub fn riskLevelSum(self: Self) !i64 {
        var total: i64 = 0;
        var lows = try self.lowPoints();
        defer self.allocator.free(lows);
        for (lows) |l| {
            total += self.pointHeight(l) + 1;
        }
        return total;
    }

    fn basinSize(self: Self, p: Point) !i64 {
        var seen = std.AutoHashMap(Point, bool).init(self.allocator);
        defer seen.deinit();
        var todo = std.ArrayList(Point).init(self.allocator);
        defer todo.deinit();

        try todo.append(p);

        while (todo.items.len != 0) {
            var curr = todo.pop();
            try seen.put(curr, true);

            var neighs = try self.neighbors(curr.x, curr.y);
            defer self.allocator.free(neighs);

            for (neighs) |n| {
                if (!seen.contains(n) and self.pointHeight(n) != 9) {
                    try todo.append(n);
                }
            }
        }

        return seen.count();
    }

    pub fn largestBasins(self: Self) !i64 {
        var lows = try self.lowPoints();
        defer self.allocator.free(lows);

        var sizes = std.ArrayList(i64).init(self.allocator);
        defer sizes.deinit();

        for (lows) |l| {
            try sizes.append(try self.basinSize(l));
        }
        std.sort.sort(i64, sizes.items, {}, comptime std.sort.desc(i64));
        return sizes.items[0] * sizes.items[1] * sizes.items[2];
    }
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const str = @embedFile("../input.txt");
    var h = try HeightMap.load(allocator, str);
    defer h.deinit();

    const stdout = std.io.getStdOut().writer();

    const part1 = try h.riskLevelSum();
    try stdout.print("Part 1: {d}\n", .{part1});

    const part2 = try h.largestBasins();
    try stdout.print("Part 2: {d}\n", .{part2});
}

test "part1 test" {
    const str = @embedFile("../test.txt");
    var h = try HeightMap.load(test_allocator, str);
    defer h.deinit();

    const score = try h.riskLevelSum();
    std.debug.print("\nScore={d}\n", .{score});
    try expect(15 == score);
}

test "part2 test" {
    const str = @embedFile("../test.txt");
    var h = try HeightMap.load(test_allocator, str);
    defer h.deinit();

    const score = try h.largestBasins();
    std.debug.print("\nScore={d}\n", .{score});
    try expect(1134 == score);
}
