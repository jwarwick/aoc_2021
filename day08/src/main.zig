const std = @import("std");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const Allocator = std.mem.Allocator;

const Display = struct {
    const Self = @This();
    allocator: Allocator,
    inputs: [][][]const u8,
    outputs: [][][]const u8,

    pub fn load(allocator: Allocator, str: []const u8) !Self {
        var allOuts = std.ArrayList([][]const u8).init(allocator);
        defer allOuts.deinit();
        var allIns = std.ArrayList([][]const u8).init(allocator);
        defer allIns.deinit();

        var iter = std.mem.split(u8, str, "\n");
        while (iter.next()) |line| {
            if (line.len != 0) {
                var outputStrs = std.ArrayList([]const u8).init(allocator);
                defer outputStrs.deinit();
                var inStrs = std.ArrayList([]const u8).init(allocator);
                defer inStrs.deinit();

                const trimmed = std.mem.trimRight(u8, line, "\n");
                var halfIter = std.mem.split(u8, trimmed, " | ");
                var inIter = std.mem.tokenize(u8, halfIter.next().?, " ");
                while (inIter.next()) |in| {
                    try inStrs.append(in);
                }
                try allIns.append(inStrs.toOwnedSlice());

                var outIter = std.mem.tokenize(u8, halfIter.next().?, " ");
                while (outIter.next()) |out| {
                    try outputStrs.append(out);
                }
                try allOuts.append(outputStrs.toOwnedSlice());
            }
        }

        return Self{ .allocator = allocator, .inputs = allIns.toOwnedSlice(), .outputs = allOuts.toOwnedSlice() };
    }

    pub fn deinit(self: *Self) void {
        for (self.outputs) |out| {
            self.allocator.free(out);
        }
        self.allocator.free(self.outputs);
        for (self.inputs) |in| {
            self.allocator.free(in);
        }
        self.allocator.free(self.inputs);
    }

    pub fn easyCount(self: Self) !i64 {
        var total: i64 = 0;
        for (self.outputs) |outputs| {
            for (outputs) |out| {
                switch (out.len) {
                    2, 4, 3, 7 => {
                        total += 1;
                    },
                    else => {},
                }
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
    var d = try Display.load(allocator, str);
    defer d.deinit();

    const stdout = std.io.getStdOut().writer();

    const part1 = try d.easyCount();
    try stdout.print("Part 1: {d}\n", .{part1});
}

test "part1 test" {
    const str = @embedFile("../test.txt");
    var d = try Display.load(test_allocator, str);
    defer d.deinit();

    const score = try d.easyCount();
    std.debug.print("\nScore={d}\n", .{score});
    try expect(26 == score);
}
