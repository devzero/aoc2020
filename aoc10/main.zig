const std = @import("std");
const input = @embedFile("input");

pub fn parseInput(inp: []const u8, allocator: *std.mem.Allocator) ![]u32 {
    var lines = std.mem.split(inp, "\n");
    var items = std.ArrayList(u32).init(allocator);
    defer items.deinit();
    try items.append(0);
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        try items.append(try std.fmt.parseUnsigned(u32, line, 10));
    }
    return items.toOwnedSlice();
}

pub fn solvePart1(nums) u32 {
    var joltCount = [3]u32{ 0, 0, 0 };
    for (nums) |n, i| {
        if (i >= nums.len - 1) {
            joltCount[2] += 1;
        } else {
            var nextDiff = nums[i + 1] - n;
            joltCount[nextDiff - 1] += 1;
        }
    }
    return joltCount[0] * joltCount[2];
}

pub fn pathCount(nums: []u32, i: usize, memo: *std.AutoHashMap(usize, u64)) anyerror!u64 {
    if (memo.get(i)) |result|
        return result;
    var pathCounts: u64 = 0;
    if (i == nums.len - 1)
        return 1;
    if ((i < nums.len - 1) and ((nums[i + 1] - nums[i]) < 4))
        pathCounts += try pathCount(nums, i + 1, memo);
    if ((i < nums.len - 2) and ((nums[i + 2] - nums[i]) < 4))
        pathCounts += try pathCount(nums, i + 2, memo);
    if ((i < nums.len - 3) and ((nums[i + 3] - nums[i]) < 4))
        pathCounts += try pathCount(nums, i + 3, memo);
    try memo.put(i, pathCounts);
    return pathCounts;
}

pub fn main() anyerror!void {
    var nums = try parseInput(input, std.heap.page_allocator);
    std.sort.sort(u32, nums[0..], {}, comptime std.sort.asc(u32));

    var memo = std.AutoHashMap(usize, u64).init(std.heap.page_allocator);
    defer memo.deinit();

    const part1: u32 = solvePart1(nums);
    const part2: u64 = try pathCount(nums, 0, &memo);

    std.log.info("Part1: {}", .{part1});
    std.log.info("Part2: {}", .{part2});
}
