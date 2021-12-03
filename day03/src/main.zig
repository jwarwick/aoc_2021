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

    pub fn generator(self: *const Self) !u64 {
        var valid: []const usize = undefined;

        var validList = std.ArrayList(usize).init(self.allocator);
        defer validList.deinit();

        for (self.rows) |_, idx| {
            try validList.append(idx);
        }
        valid = validList.toOwnedSlice();

        for (self.counts) |c, idx| {
            std.debug.print("\nc={d}\n", .{c});
            std.debug.print("\nREMAINING STRINGS:\n", .{});

            for (valid) |v| {
                std.debug.print("\t{s}\n", .{self.rows[v]});
            }
            std.debug.print("\n\n", .{});
            if (valid.len == 1) {
                std.debug.print("\nFOUND MATCH: {s}\n", .{self.rows[valid[0]]});
                // return row to number
                return valid[0];
            }

            var nextValid = std.ArrayList(usize).init(self.allocator);
            defer nextValid.deinit();

            var m = c.max();
            var mStr: u8 = undefined;
            if (m == 1) {
                mStr = '1';
            } else {
                mStr = '0';
            }
            for (valid) |v| {
                if (self.rows[v][idx] == mStr) {
                    try nextValid.append(v);
                }
            }
            // Allocator.free(valid);
            valid = nextValid.toOwnedSlice();

            if (valid.len == 1) {
                // return row to number
                std.debug.print("\nFOUND MATCH: {s}\n", .{self.rows[valid[0]]});
                return valid[0];
            }
        }
        return error{Oops};
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
        var gen = try self.rows.generator();
        var scrub = try self.scrubber();
        return gen * scrub;
    }

    fn scrubber(self: *const Self) !u64 {
        return self.rows.gamma();
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
