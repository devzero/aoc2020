const std = @import("std");
const input = @embedFile("input");

pub const log_level = std.log.Level.info;

pub fn numberList(allocator: *std.mem.Allocator) ![]const u32 {
    var list = std.ArrayList(u32).init(allocator);
    defer list.deinit();
    var it = std.mem.split(input, "\n");
    while (it.next()) |num| {
        try list.append(std.fmt.parseUnsigned(u32, num, 10) catch continue);
    }
    return list.toOwnedSlice();
}

pub fn solve(nums: []const u32, part1: bool) !void {
    for (nums) |x, idx0| {
        for (nums[idx0 + 1 ..]) |y, idx1| {
            if (part1) {
                std.log.debug("X: {} Y: {} ({}.{})", .{ x, y, idx0, idx1 });
                if ((x + y) == 2020) {
                    std.log.info("Part1: {}", .{x * y});
                    return;
                }
            } else {
                for (nums[std.math.max(idx0, idx1) + 1 ..]) |z, idx2| {
                    std.log.debug("X: {} Y: {} Z:{} ({},{},{})", .{ x, y, z, idx0, idx1, idx2 });
                    if ((x + y + z) == 2020) {
                        std.log.info("Part2: {}", .{x * y * z});
                        return;
                    }
                }
            }
        }
    }
}

pub fn main() anyerror!void {
    var nums = try numberList(std.heap.page_allocator);
    try solve(nums, true);
    try solve(nums, false);
}
