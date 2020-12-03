const std = @import("std");
const input = @embedFile("input");

pub fn isValid(passline: []const u8, part1: bool) bool {
    const dash = std.mem.indexOf(u8, passline, "-") orelse return false;
    const firstspace = std.mem.indexOf(u8, passline, " ") orelse return false;
    const colon = std.mem.indexOf(u8, passline, ":") orelse return false;
    const low = std.fmt.parseUnsigned(u32, passline[0..dash], 10) catch return false;
    const high = std.fmt.parseUnsigned(u32, passline[dash + 1 .. firstspace], 10) catch return false;
    const c = passline[firstspace + 1];
    const pass = passline[colon + 2 ..];

    if (part1) {
        return (((pass[low - 1] == c) and (pass[high - 1] != c)) or ((pass[low - 1] != c) and (pass[high - 1] == c)));
    } else {
        var numcs: u32 = 0;
        for (pass) |ch| {
            if (ch == c)
                numcs += 1;
        }
        if ((numcs >= low) and (high >= numcs))
            return true;
    }
    return false;
}

pub fn main() anyerror!void {
    var it = std.mem.split(input, "\n");
    var part1: u32 = 0;
    var part2: u32 = 0;
    while (it.next()) |line| {
        if (isValid(line, true))
            part1 += 1;
        if (isValid(line, false))
            part2 += 1;
    }
    try std.io.getStdOut().writer().print("Part1: {}\nPart2: {}\n", .{ part1, part2 });
}
