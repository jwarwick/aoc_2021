const std = @import("std");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const Allocator = std.mem.Allocator;

const Cell = struct {
    rowIdx: u64 = 0,
    colIdx: u64 = 0,
    value: u64,
    seen: bool = false,
};

const Board = struct {
    const Self = @This();
    allocator: Allocator,
    cells: []Cell,
    map: std.AutoHashMap(u64, *Cell),
    hasWon: bool = false,

    pub fn load(allocator: Allocator, rows: [][]const u8) !Self {
        var cells = std.ArrayList(Cell).init(allocator);
        defer cells.deinit();

        for (rows) |r, rowIdx| {
            var numIter = std.mem.tokenize(u8, r, " ");
            var colIdx: u64 = 0;
            while (numIter.next()) |n| {
                if (n.len != 0) {
                    const val = try std.fmt.parseInt(u64, n, 10);
                    colIdx += 1;
                    try cells.append(Cell{ .value = val, .rowIdx = rowIdx, .colIdx = colIdx });
                }
            }
        }
        var map = std.AutoHashMap(u64, *Cell).init(allocator);
        var ownedCells = cells.toOwnedSlice();
        for (ownedCells) |*c| {
            try map.put(c.value, c);
        }
        return Self{ .allocator = allocator, .cells = ownedCells, .map = map };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.cells);
        self.map.deinit();
    }

    fn offset(colIdx: u64, rowIdx: u64) u64 {
        return ((rowIdx * 5) + colIdx);
    }

    pub fn addNumber(self: *Self, num: u64) bool {
        var c = self.map.get(num);
        if (c != null) {
            var cPtr = c.?;
            cPtr.seen = true;
            return self.checkWin();
        }
        return false;
    }

    fn checkWin(self: *Self) bool {
        var row: u64 = 0;
        var col: u64 = 0;
        var seenCount: u64 = 0;

        while (row < 5) : (row += 1) {
            col = 0;
            seenCount = 0;
            while (col < 5) : (col += 1) {
                var off = offset(col, row);
                if (self.cells[off].seen) {
                    seenCount += 1;
                }
            }
            if (seenCount == 5) {
                return true;
            }
        }

        col = 0;
        while (col < 5) : (col += 1) {
            row = 0;
            seenCount = 0;
            while (row < 5) : (row += 1) {
                var off = offset(col, row);
                if (self.cells[off].seen) {
                    seenCount += 1;
                }
            }
            if (seenCount == 5) {
                return true;
            }
        }

        return false;
    }

    pub fn unseenSum(self: *Self) u64 {
        var sum: u64 = 0;
        for (self.cells) |c| {
            if (!c.seen) {
                sum += c.value;
            }
        }
        return sum;
    }
};

const Game = struct {
    const Self = @This();
    numbers: []const u64,
    boards: []Board,
    allocator: Allocator,

    pub fn load(allocator: Allocator, str: []const u8) !Self {
        var nums = std.ArrayList(u64).init(allocator);
        defer nums.deinit();

        var iter = std.mem.split(u8, str, "\n");

        var numStr = iter.next().?;
        var numIter = std.mem.tokenize(u8, numStr, ",");
        while (numIter.next()) |n| {
            const val = try std.fmt.parseInt(u64, n, 10);
            try nums.append(val);
        }

        // skip empty line
        _ = iter.next().?;

        var boards = std.ArrayList(Board).init(allocator);
        defer boards.deinit();

        var currRows = std.ArrayList([]const u8).init(allocator);
        defer currRows.deinit();
        while (iter.next()) |line| {
            if (line.len == 0) {
                if (currRows.items.len == 0) {
                    continue;
                }
                var b = try Board.load(allocator, currRows.items);
                try boards.append(b);

                currRows.resize(0) catch unreachable;
                continue;
            }
            try currRows.append(line);
        }

        return Self{ .allocator = allocator, .numbers = nums.toOwnedSlice(), .boards = boards.toOwnedSlice() };
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.numbers);
        for (self.boards) |*b| {
            b.deinit();
        }
        self.allocator.free(self.boards);
    }

    pub fn winningScore(self: *Self) !u64 {
        for (self.numbers) |n| {
            for (self.boards) |*b| {
                if (b.addNumber(n)) {
                    const sum = b.unseenSum();
                    return (n * sum);
                }
            }
        }
        std.debug.print("\nNo board won!\n", .{});
        return 0;
    }

    pub fn worstBoard(self: *Self) !u64 {
        const boardCount = self.boards.len;
        var winCount: u64 = 0;

        for (self.numbers) |n| {
            for (self.boards) |*b| {
                if (!b.hasWon) {
                    if (b.addNumber(n)) {
                        if (winCount == (boardCount - 1)) {
                            const sum = b.unseenSum();
                            return (n * sum);
                        } else {
                            b.hasWon = true;
                            winCount += 1;
                        }
                    }
                }
            }
        }
        std.debug.print("\nNo board won!\n", .{});
        return 0;
    }
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const str = @embedFile("../input.txt");
    var g = try Game.load(allocator, str);
    defer g.deinit();

    const stdout = std.io.getStdOut().writer();

    const part1 = try g.winningScore();
    try stdout.print("Part 1: {d}\n", .{part1});

    const part2 = try g.worstBoard();
    try stdout.print("Part 2: {d}\n", .{part2});
}

test "part1 test" {
    const str = @embedFile("../test.txt");
    var g = try Game.load(test_allocator, str);
    defer g.deinit();

    const score = try g.winningScore();
    try expect(4512 == score);
}

test "part2 test" {
    const str = @embedFile("../test.txt");
    var g = try Game.load(test_allocator, str);
    defer g.deinit();

    const score = try g.worstBoard();
    try expect(1924 == score);
}
