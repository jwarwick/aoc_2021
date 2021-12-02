const std = @import("std");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const Allocator = std.mem.Allocator;

const Direction = enum { forward, up, down };

const Step = struct {
    dir: Direction,
    distance: u64,

    pub fn parse(str: []const u8) !Step {
        var iter = std.mem.split(u8, str, " ");
        const s = iter.next().?;
        const dir = if (std.mem.eql(u8, s, "forward"))
            Direction.forward
        else if (std.mem.eql(u8, s, "up"))
            Direction.up
        else if (std.mem.eql(u8, s, "down"))
            Direction.down
        else
            unreachable;
        const value = try std.fmt.parseInt(u64, iter.next().?, 10);
        return Step{ .dir = dir, .distance = value };
    }
};

const Course = struct {
    steps: []Step,
    allocator: Allocator,

    pub fn load(allocator: Allocator, str: []const u8) !Course {
        var list = std.ArrayList(Step).init(allocator);
        defer list.deinit();

        var iter = std.mem.split(u8, str, "\n");
        while (iter.next()) |line| {
            if (line.len != 0) {
                const s = try Step.parse(line);
                try list.append(s);
            }
        }

        return Course{ .allocator = allocator, .steps = list.toOwnedSlice() };
    }

    pub fn deinit(self: *const Course) void {
        self.allocator.free(self.steps);
    }

    pub fn follow(self: *const Course) u64 {
        var distance: u64 = 0;
        var depth: u64 = 0;
        for (self.steps) |step| {
            switch (step.dir) {
                Direction.up => depth = depth - step.distance,
                Direction.down => depth = depth + step.distance,
                Direction.forward => distance = distance + step.distance,
            }
        }
        return distance * depth;
    }
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const str = @embedFile("../input.txt");
    var c = try Course.load(allocator, str);
    // defer allocator.free(c);

    const stdout = std.io.getStdOut().writer();

    const part1 = c.follow();
    try stdout.print("Part 1: {d}\n", .{part1});

    // const part2 = slidingWindow(&values);
    // try stdout.print("Part 2: {d}\n", .{part2});
}

test "basic test" {
    const str = @embedFile("../test.txt");
    var c = try Course.load(test_allocator, str);
    defer test_allocator.free(c);

    const result = c.follow();
    try expect(150 == result);
}
