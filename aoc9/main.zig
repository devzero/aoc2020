const std = @import("std");
const input = @embedFile("input");
const WIN = 25;
const SUMSSIZE = (WIN * WIN - WIN) / 2;
const Allocator = std.mem.Allocator;
const HashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;

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

pub fn main() anyerror!void {
    var allocator = std.heap.page_allocator;
    var lines = std.mem.split(input, "\n");
    var numsAL = ArrayList(u64).init(allocator);
    defer numsAL.deinit();
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        try numsAL.append(try std.fmt.parseUnsigned(u64, line, 10));
    }
    const nums = numsAL.toOwnedSlice();

    var cur: u16 = WIN;
    var part1: u64 = 0;
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
        part1 = nums[cur];
        break :outer;
    }

    var part2: u64 = 0;
    outer2: for (nums) |_, size| {
        if (size < 2) continue;
        cur = 0;
        while (cur < (nums.len - size)) : (cur += 1) {
            var sum: u64 = 0;
            var i: usize = 0;
            while (i < size) : (i += 1) {
                sum += nums[cur + i];
            }
            if (sum == part1) {
                part2 = minNum(nums[cur .. cur + size - 1]) + maxNum(nums[cur .. cur + size - 1]);
                break :outer2;
            }
        }
    }

    std.log.info("Part1: {}", .{part1});
    std.log.info("Part2: {}", .{part2});
}
