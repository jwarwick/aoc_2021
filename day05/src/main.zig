const std = @import("std");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const Allocator = std.mem.Allocator;

const Point = struct {
    const Self = @This();
    x: u64,
    y: u64,

    pub fn parse(str: []const u8) !Self {
        var numIter = std.mem.tokenize(u8, str, ",");
        const x = try std.fmt.parseInt(u64, numIter.next().?, 10);
        const y = try std.fmt.parseInt(u64, numIter.next().?, 10);
        return Self{ .x = x, .y = y };
    }
};

const Map = struct {
    const Self = @This();
    allocator: Allocator,
    map: std.AutoHashMap(u64, u64),

    pub fn load(allocator: Allocator, str: []const u8, diagonals: bool) !Self {
        var map = std.AutoHashMap(u64, u64).init(allocator);
        var iter = std.mem.split(u8, str, "\n");

        while (iter.next()) |line| {
            if (line.len != 0) {
                var pointIter = std.mem.split(u8, line, " -> ");
                var p1 = try Point.parse(pointIter.next().?);
                var p2 = try Point.parse(pointIter.next().?);

                if (p1.x == p2.x) {
                    try insertVertical(&map, p1, p2);
                } else if (p1.y == p2.y) {
                    try insertHorizontal(&map, p1, p2);
                } else if (diagonals) {
                    var left = p1;
                    var right = p2;
                    if (p2.x < p1.x) {
                        left = p2;
                        right = p1;
                    }
                    if (left.y < right.y) {
                        try insertDownDiagonal(&map, left, right);
                    } else {
                        try insertUpDiagonal(&map, left, right);
                    }
                }
            }
        }

        return Self{ .allocator = allocator, .map = map };
    }

    pub fn deinit(self: *Self) void {
        self.map.deinit();
    }

    fn insertPoint(map: *std.AutoHashMap(u64, u64), p: u64) !void {
        var curr = map.get(p) orelse 0;
        try map.put(p, curr + 1);
    }

    fn insertUpDiagonal(map: *std.AutoHashMap(u64, u64), p1: Point, p2: Point) anyerror!void {
        var y = p1.y;
        var x = p1.x;
        while (x <= p2.x) {
            try insertPoint(map, offset(y, x));
            x += 1;
            if (y > 0) {
                y -= 1;
            }
        }
    }

    fn insertDownDiagonal(map: *std.AutoHashMap(u64, u64), p1: Point, p2: Point) anyerror!void {
        var y = p1.y;
        var x = p1.x;
        while (x <= p2.x) {
            try insertPoint(map, offset(y, x));
            x += 1;
            y += 1;
        }
    }

    fn insertHorizontal(map: *std.AutoHashMap(u64, u64), p1: Point, p2: Point) anyerror!void {
        if (p1.x > p2.x) {
            try insertHorizontal(map, p2, p1);
            return;
        }

        const y = p1.y;
        var x = p1.x;
        while (x <= p2.x) : (x += 1) {
            try insertPoint(map, offset(y, x));
        }
    }

    fn insertVertical(map: *std.AutoHashMap(u64, u64), p1: Point, p2: Point) anyerror!void {
        if (p1.y > p2.y) {
            try insertVertical(map, p2, p1);
            return;
        }

        const x = p1.x;
        var y = p1.y;
        while (y <= p2.y) : (y += 1) {
            try insertPoint(map, offset(y, x));
        }
    }

    pub fn twoOverlaps(self: *Self) !u64 {
        var total: u64 = 0;
        var iterator = self.map.iterator();

        while (iterator.next()) |entry| {
            if (entry.value_ptr.* >= 2) {
                total += 1;
            }
        }
        return total;
    }

    fn offset(colIdx: u64, rowIdx: u64) u64 {
        return ((rowIdx * 1000) + colIdx);
    }
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const str = @embedFile("../input.txt");
    var m = try Map.load(allocator, str, false);
    defer m.deinit();

    const stdout = std.io.getStdOut().writer();

    const part1 = try m.twoOverlaps();
    try stdout.print("Part 1: {d}\n", .{part1});

    var m2 = try Map.load(allocator, str, true);
    defer m2.deinit();

    const part2 = try m2.twoOverlaps();
    try stdout.print("Part 2: {d}\n", .{part2});
}

test "part1 test" {
    const str = @embedFile("../test.txt");
    var m = try Map.load(test_allocator, str, false);
    defer m.deinit();

    const score = try m.twoOverlaps();
    try expect(5 == score);
}

test "part2 test" {
    const str = @embedFile("../test.txt");
    var m = try Map.load(test_allocator, str, true);
    defer m.deinit();

    const score = try m.twoOverlaps();
    try expect(12 == score);
}
