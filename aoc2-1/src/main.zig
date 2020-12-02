const std = @import("std");

pub fn isValid(passline: []const u8) bool {
    if (passline.len == 0)
        return false;
    const dash = std.mem.indexOf(u8, passline, "-") orelse return false;
    const firstspace = std.mem.indexOf(u8, passline, " ") orelse return false;
    const colon = std.mem.indexOf(u8, passline, ":") orelse return false;
    const low = std.fmt.parseUnsigned(u32, passline[0..dash], 10) catch return false;
    const high = std.fmt.parseUnsigned(u32, passline[dash + 1 .. firstspace], 10) catch return false;
    const c = passline[firstspace + 1];
    const pass = passline[colon + 2 ..];
    var numcs: u32 = 0;
    for (pass) |ch| {
        if (ch == c)
            numcs += 1;
    }
    if ((numcs >= low) and (high >= numcs))
        return true;
    return false;
}

pub fn main() anyerror!void {
    const fst = (try std.fs.cwd().openFile("input", .{})).reader();
    const passwdfile = try fst.readAllAlloc(std.heap.page_allocator, std.math.maxInt(u64));
    var it = std.mem.split(passwdfile, "\n");
    var numlines: u32 = 0;
    while (it.next()) |line| {
        if (isValid(line))
            numlines += 1;
    }
    try std.io.getStdOut().writer().print("{}", .{numlines});
}
