const std = @import("std");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const Allocator = std.mem.Allocator;

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

    fn pointHeight(self: Self, x: i64, y: i64) i64 {
        const idx = self.offset(x, y) orelse return std.math.maxInt(u8);
        return self.heights[@intCast(usize, idx)];
    }

    fn computeRisk(self: Self, x: i64, y: i64) !i64 {
        const h = self.pointHeight(x, y);
        var neighCount: u8 = 0;
        if (h < self.pointHeight(x, y - 1)) neighCount += 1;
        if (h < self.pointHeight(x, y + 1)) neighCount += 1;
        if (h < self.pointHeight(x - 1, y)) neighCount += 1;
        if (h < self.pointHeight(x + 1, y)) neighCount += 1;
        if (neighCount == 4) {
            return h + 1;
        } else {
            return 0;
        }
    }

    pub fn riskLevelSum(self: Self) !i64 {
        var total: i64 = 0;
        var row: i64 = 0;
        while (row < self.height) : (row += 1) {
            var col: i64 = 0;
            while (col < self.width) : (col += 1) {
                const risk = try self.computeRisk(col, row);
                total += risk;
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
    var h = try HeightMap.load(allocator, str);
    defer h.deinit();

    const stdout = std.io.getStdOut().writer();

    const part1 = try h.riskLevelSum();
    try stdout.print("Part 1: {d}\n", .{part1});
}

test "part1 test" {
    const str = @embedFile("../test.txt");
    var h = try HeightMap.load(test_allocator, str);
    defer h.deinit();

    const score = try h.riskLevelSum();
    std.debug.print("\nScore={d}\n", .{score});
    try expect(15 == score);
}
