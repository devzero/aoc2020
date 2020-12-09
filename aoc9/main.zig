const std = @import("std");
const input = @embedFile("input");
const WIN = 25;
const SUMSSIZE = (WIN * WIN - WIN) / 2;
const Allocator = std.mem.Allocator;

pub fn parseInput(inp: []const u8, allocator: *Allocator) ![]u64 {
    var lines = std.mem.split(inp, "\n");
    var numsAL = std.ArrayList(u64).init(std.heap.page_allocator);
    defer numsAL.deinit();
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        try numsAL.append(try std.fmt.parseUnsigned(u64, line, 10));
    }
    return numsAL.toOwnedSlice();
}

pub fn solvePart1(nums: []u64) !u64 {
    var cur: u16 = WIN;
    outer: while (cur < nums.len) : (cur += 1) {
        var i: u16 = 0;
        var j: u16 = 0;
        while (i < WIN) : (i += 1) {
            j = i + 1;
            while (j < WIN) : (j += 1) {
                const thissum = nums[cur + i - WIN] + nums[cur + j - WIN];
                if (nums[cur] == thissum) {
                    continue :outer;
                }
            }
        }
        return nums[cur];
    }
    return error.noAnswer;
}

pub fn minNum(s: []u64) u64 {
    var a: u64 = std.math.maxInt(u64);
    for (s) |i|
        a = std.math.min(i, a);
    return a;
}

pub fn maxNum(s: []u64) u64 {
    var a: u64 = std.math.minInt(u64);
    for (s) |i|
        a = std.math.max(i, a);
    return a;
}

pub fn solvePart2(nums: []u64, part1: u64) !u64 {
    for (nums) |_, size| {
        if (size < 2) continue;
        var cur: u16 = 0;
        while (cur < (nums.len - size)) : (cur += 1) {
            var sum: u64 = 0;
            var i: usize = 0;
            while (i < size) : (i += 1) {
                sum += nums[cur + i];
            }
            if (sum == part1)
                return minNum(nums[cur .. cur + size - 1]) + maxNum(nums[cur .. cur + size - 1]);
        }
    }
    return error.noAnswer;
}

pub fn main() anyerror!void {
    const nums = try parseInput(input, std.heap.page_allocator);
    defer std.heap.page_allocator.free(nums);

    const part1 = try solvePart1(nums);
    const part2 = try solvePart2(nums, part1);

    std.log.info("Part1: {}", .{part1});
    std.log.info("Part2: {}", .{part2});
}
