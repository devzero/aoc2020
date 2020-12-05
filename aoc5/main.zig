const std = @import("std");
const input = @embedFile("input");

pub fn seatID(pass: []const u8) !u16 {
    var buf: [10]u8 = undefined;
    _ = std.mem.replace(u8, pass[0..10], "F", "0", &buf);
    _ = std.mem.replace(u8, buf[0..], "B", "1", &buf);
    _ = std.mem.replace(u8, buf[0..], "L", "0", &buf);
    _ = std.mem.replace(u8, buf[0..], "R", "1", &buf);
    return std.fmt.parseUnsigned(u16, buf[0..], 2);
}

pub fn main() anyerror!void {
    var maxID: u16 = 0;
    var minID: u16 = 1024;
    var seats: [1024]bool = std.mem.zeroes([1024]bool);
    var it = std.mem.split(input, "\n");
    while (it.next()) |line| {
        if (line.len != 10) continue;
        const seat = try seatID(line);
        seats[seat] = true;
        minID = std.math.min(minID, seat);
        maxID = std.math.max(maxID, seat);
    }
    var missingSeat: u16 = 1025;
    var i = minID;
    while (i < maxID) : (i += 1) {
        if (!seats[i]) missingSeat = i;
    }
    std.log.info("part1: {}", .{maxID});
    std.log.info("part2: {}", .{missingSeat});
}
