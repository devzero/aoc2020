const std = @import("std");
const input = @embedFile("input");
const BITS = 10;
const uBITS = u10;
const maxsize = std.math.maxInt(uBITS);

pub fn seatID(pass: []const u8) !uBITS {
    var buf: [BITS]u8 = undefined;
    _ = std.mem.replace(u8, pass[0..10], "F", "0", &buf);
    _ = std.mem.replace(u8, buf[0..], "B", "1", &buf);
    _ = std.mem.replace(u8, buf[0..], "L", "0", &buf);
    _ = std.mem.replace(u8, buf[0..], "R", "1", &buf);
    return std.fmt.parseUnsigned(uBITS, buf[0..], 2);
}

pub fn main() anyerror!void {
    var maxID: uBITS = 0;
    var minID: uBITS = maxsize;
    var seats: [maxsize]bool = std.mem.zeroes([maxsize]bool);
    var it = std.mem.split(input, "\n");
    while (it.next()) |line| {
        if (line.len != BITS) continue;
        const seat = try seatID(line);
        seats[seat] = true;
        minID = std.math.min(minID, seat);
        maxID = std.math.max(maxID, seat);
    }
    var missingSeat: uBITS = maxsize;
    var i = minID;
    while (i < maxID) : (i += 1) {
        if (!seats[i]) missingSeat = i;
    }
    std.log.info("Part1: {}", .{maxID});
    std.log.info("Part2: {}", .{missingSeat});
}
