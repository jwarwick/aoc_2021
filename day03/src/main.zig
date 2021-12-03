const std = @import("std");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const Allocator = std.mem.Allocator;

const Count = struct {
    ones: i64 = 0,
    zeros: i64 = 0,

    pub fn max(self: *const Count) u64 {
        if (self.ones >= self.zeros) {
            return 1;
        } else {
            return 0;
        }
    }

    pub fn min(self: *const Count) u64 {
        if (self.zeros <= self.ones) {
            return 0;
        } else {
            return 1;
        }
    }

    pub fn add(self: *Count, c: u8) void {
        switch (c) {
            '0' => self.zeros += 1,
            '1' => self.ones += 1,
            else => unreachable,
        }
    }
};

const RowSet = struct {
    const Self = @This();
    counts: []Count,
    rows: [][]const u8,
    allocator: Allocator,

    pub fn load(allocator: Allocator, rowSlice: [][]const u8) !Self {
        var list = std.ArrayList(Count).init(allocator);
        defer list.deinit();
        var rows = std.ArrayList([]const u8).init(allocator);
        defer rows.deinit();

        for (rowSlice) |line| {
            if (line.len != 0) {
                if (list.items.len == 0) {
                    try list.appendNTimes(Count{}, line.len);
                }
                for (line) |c, idx| {
                    list.items[idx].add(c);
                }
                try rows.append(line);
            }
        }

        return Self{ .allocator = allocator, .counts = list.toOwnedSlice(), .rows = rows.toOwnedSlice() };
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.counts);
        self.allocator.free(self.rows);
    }

    pub fn gamma(self: *const Self) u64 {
        var g: u64 = 0;
        for (self.counts) |c| {
            var m = c.max();
            g = (g << 1) | m;
        }

        return g;
    }

    pub fn epsilon(self: *const Self) u64 {
        var g: u64 = 0;
        for (self.counts) |c| {
            var m = c.min();
            g = (g << 1) | m;
        }

        return g;
    }

    const GeneratorError = error{GenError};

    fn bitToChar(m: u64) u8 {
        if (m == 1) {
            return '1';
        } else {
            return '0';
        }
    }

    pub fn generator(self: *const Self, bit_idx: usize) !u64 {
        var valid = std.ArrayList([]const u8).init(self.allocator);
        defer valid.deinit();

        const c = self.counts[bit_idx];

        const m = c.max();
        const mStr = bitToChar(m);
        for (self.rows) |r| {
            if (r[bit_idx] == mStr) {
                try valid.append(r);
            }
        }

        if (valid.items.len == 1) {
            var val = try std.fmt.parseInt(u64, valid.items[0], 2);
            return val;
        }
        var rs = try RowSet.load(self.allocator, valid.items);
        defer rs.deinit();
        return rs.generator(bit_idx + 1);
    }

    pub fn scrubber(self: *const Self, bit_idx: usize) !u64 {
        var valid = std.ArrayList([]const u8).init(self.allocator);
        defer valid.deinit();

        const c = self.counts[bit_idx];

        const m = c.min();
        const mStr = bitToChar(m);
        for (self.rows) |r| {
            if (r[bit_idx] == mStr) {
                try valid.append(r);
            }
        }

        if (valid.items.len == 1) {
            var val = try std.fmt.parseInt(u64, valid.items[0], 2);
            return val;
        }
        var rs = try RowSet.load(self.allocator, valid.items);
        defer rs.deinit();
        return rs.scrubber(bit_idx + 1);
    }
};

const DiagnosticReport = struct {
    const Self = @This();
    rows: RowSet,
    allocator: Allocator,

    pub fn load(allocator: Allocator, str: []const u8) !Self {
        var rows = std.ArrayList([]const u8).init(allocator);
        defer rows.deinit();

        var iter = std.mem.split(u8, str, "\n");
        while (iter.next()) |line| {
            if (line.len != 0) {
                try rows.append(line);
            }
        }

        var rowSet = try RowSet.load(allocator, rows.items);
        return Self{ .allocator = allocator, .rows = rowSet };
    }

    pub fn deinit(self: Self) void {
        self.rows.deinit();
    }

    pub fn powerConsumption(self: *const Self) u64 {
        return self.rows.gamma() * self.rows.epsilon();
    }

    pub fn lifeSupport(self: *const Self) !u64 {
        var gen = try self.rows.generator(0);
        var scrub = try self.rows.scrubber(0);
        return gen * scrub;
    }
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const str = @embedFile("../input.txt");
    var d = try DiagnosticReport.load(allocator, str);
    defer d.deinit();

    const stdout = std.io.getStdOut().writer();

    const part1 = d.powerConsumption();
    try stdout.print("Part 1: {d}\n", .{part1});

    const part2 = try d.lifeSupport();
    try stdout.print("Part 2: {d}\n", .{part2});
}

test "part1 test" {
    const str = @embedFile("../test.txt");
    var d = try DiagnosticReport.load(test_allocator, str);
    defer d.deinit();

    try expect(198 == d.powerConsumption());
}

test "part2 test" {
    const str = @embedFile("../test.txt");
    var d = try DiagnosticReport.load(test_allocator, str);
    defer d.deinit();

    var l = try d.lifeSupport();
    try expect(230 == l);
}
