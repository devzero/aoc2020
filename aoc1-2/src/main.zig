const std = @import("std");

pub const log_level = std.log.Level.info;

pub fn readNumberList(allocator: *std.mem.Allocator, path: []const u8) ![]const u32 {
    const myfile = try std.fs.cwd().openFile(path, .{});
    const chars = try myfile.reader().readAllAlloc(allocator, std.math.maxInt(u64));
    var list = std.ArrayList(u32).init(allocator);
    defer list.deinit();
    var it = std.mem.split(chars, "\n");
    while (it.next()) |num| {
        try list.append(std.fmt.parseUnsigned(u32, num, 10) catch continue);
    }
    return list.toOwnedSlice();
}

pub fn main() anyerror!void {
    var nums = try readNumberList(std.heap.page_allocator, "input.txt");
    for (nums) |x, idx0| {
        for (nums[idx0 + 1 ..]) |y, idx1| {
            for (nums[std.math.max(idx0, idx1) + 1 ..]) |z, idx2| {
                std.log.debug("X: {} Y: {} Z:{} ({},{},{})", .{ x, y, z, idx0, idx1, idx2 });
                if ((x + y + z) == 2020) {
                    try std.io.getStdOut().writer().print("{}", .{x * y * z});
                    return;
                }
            }
        }
    }
}
