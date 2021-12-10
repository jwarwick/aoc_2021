const std = @import("std");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const Allocator = std.mem.Allocator;

const Syntax = struct {
    const Self = @This();
    allocator: Allocator,
    lines: [][]const u8,

    pub fn load(allocator: Allocator, str: []const u8) !Self {
        var lines = std.ArrayList([]const u8).init(allocator);
        defer lines.deinit();

        var iter = std.mem.split(u8, str, "\n");
        while (iter.next()) |line| {
            if (line.len != 0) {
                const trimmed = std.mem.trimRight(u8, line, "\n");
                try lines.append(trimmed);
            }
        }

        return Self{ .allocator = allocator, .lines = lines.toOwnedSlice() };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.lines);
    }

    fn lineScore(self: Self, str: []const u8) !i64 {
        var stack = std.ArrayList(u8).init(self.allocator);
        defer stack.deinit();

        for (str) |c| {
            switch (c) {
                '(' => {
                    try stack.append(')');
                },
                '[' => {
                    try stack.append(']');
                },
                '{' => {
                    try stack.append('}');
                },
                '<' => {
                    try stack.append('>');
                },
                ')' => {
                    const v = stack.pop();
                    if (v != ')') return 3;
                },
                ']' => {
                    const v = stack.pop();
                    if (v != ']') return 57;
                },
                '}' => {
                    const v = stack.pop();
                    if (v != '}') return 1197;
                },
                '>' => {
                    const v = stack.pop();
                    if (v != '>') return 25137;
                },
                else => unreachable,
            }
        }
        return 0;
    }

    pub fn syntaxErrorScore(self: Self) !i64 {
        var total: i64 = 0;
        for (self.lines) |line| {
            total += try self.lineScore(line);
        }
        return total;
    }

    fn completionScore(self: Self, str: []const u8) !?i64 {
        var stack = std.ArrayList(u8).init(self.allocator);
        defer stack.deinit();

        for (str) |c| {
            switch (c) {
                '(' => {
                    try stack.append(')');
                },
                '[' => {
                    try stack.append(']');
                },
                '{' => {
                    try stack.append('}');
                },
                '<' => {
                    try stack.append('>');
                },
                ')' => {
                    const v = stack.pop();
                    if (v != ')') return null;
                },
                ']' => {
                    const v = stack.pop();
                    if (v != ']') return null;
                },
                '}' => {
                    const v = stack.pop();
                    if (v != '}') return null;
                },
                '>' => {
                    const v = stack.pop();
                    if (v != '>') return null;
                },
                else => unreachable,
            }
        }
        var total: i64 = 0;
        while (stack.items.len != 0) {
            const v = stack.pop();
            var s: i64 = 0;
            s = switch (v) {
                ')' => 1,
                ']' => 2,
                '}' => 3,
                '>' => 4,
                else => unreachable,
            };
            total = (total * 5) + s;
        }

        return total;
    }

    pub fn middleCompletionScore(self: Self) !i64 {
        var scores = std.ArrayList(i64).init(self.allocator);
        defer scores.deinit();

        for (self.lines) |line| {
            var s = try self.completionScore(line);
            if (s != null) {
                try scores.append(s.?);
            }
        }
        std.sort.sort(i64, scores.items, {}, comptime std.sort.asc(i64));
        const idx = (scores.items.len / 2);
        return scores.items[idx];
    }
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const str = @embedFile("../input.txt");
    var s = try Syntax.load(allocator, str);
    defer s.deinit();

    const stdout = std.io.getStdOut().writer();

    const part1 = try s.syntaxErrorScore();
    try stdout.print("Part 1: {d}\n", .{part1});

    const part2 = try s.middleCompletionScore();
    try stdout.print("Part 2: {d}\n", .{part2});
}

test "part1 test" {
    const str = @embedFile("../test.txt");
    var s = try Syntax.load(test_allocator, str);
    defer s.deinit();

    const score = try s.syntaxErrorScore();
    std.debug.print("\nScore={d}\n", .{score});
    try expect(26397 == score);
}

test "part2 test" {
    const str = @embedFile("../test.txt");
    var s = try Syntax.load(test_allocator, str);
    defer s.deinit();

    const score = try s.middleCompletionScore();
    std.debug.print("\nScore={d}\n", .{score});
    try expect(288957 == score);
}
