const std = @import("std");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const Allocator = std.mem.Allocator;

const Count = struct {
    ones: i64 = 0,
    zeros: i64 = 0,

    pub fn max(self: *const Count) u64 {
        if (self.ones > self.zeros) {
            return 1;
        } else {
            return 0;
        }
    }

    pub fn min(self: *const Count) u64 {
        if (self.ones > self.zeros) {
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

const DiagnosticReport = struct {
    counts: []Count,
    allocator: Allocator,

    pub fn load(allocator: Allocator, str: []const u8) !DiagnosticReport {
        var list = std.ArrayList(Count).init(allocator);
        defer list.deinit();

        var iter = std.mem.split(u8, str, "\n");
        while (iter.next()) |line| {
            if (line.len != 0) {
                if (list.items.len == 0) {
                    try list.ensureTotalCapacity(line.len);
                    for (line) |_| {
                        try list.append(Count{});
                    }
                }
                for (line) |c, idx| {
                    list.items[idx].add(c);
                }
            }
        }

        return DiagnosticReport{ .allocator = allocator, .counts = list.toOwnedSlice() };
    }

    pub fn deinit(self: *const DiagnosticReport) void {
        self.allocator.free(self.counts);
    }

    pub fn powerConsumption(self: *const DiagnosticReport) u64 {
        return self.gamma() * self.epsilon();
    }

    fn gamma(self: *const DiagnosticReport) u64 {
        var g: u64 = 0;
        for (self.counts) |c| {
            var m = c.max();
            g = (g << 1) | m;
        }

        return g;
    }

    fn epsilon(self: *const DiagnosticReport) u64 {
        var g: u64 = 0;
        for (self.counts) |c| {
            var m = c.min();
            g = (g << 1) | m;
        }

        return g;
    }
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const str = @embedFile("../input.txt");
    var d = try DiagnosticReport.load(allocator, str);
    // defer allocator.free(d);

    const stdout = std.io.getStdOut().writer();

    const part1 = d.powerConsumption();
    try stdout.print("Part 1: {d}\n", .{part1});

    // const part2 = c.followAim();
    // try stdout.print("Part 2: {d}\n", .{part2});
}

test "basic test" {
    const str = @embedFile("../test.txt");
    var d = try DiagnosticReport.load(test_allocator, str);
    // defer test_allocator.free(d);

    try expect(198 == d.powerConsumption());
}
