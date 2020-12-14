const std = @import("std");
const input = @embedFile("input");

const InData = struct {
    ts: u64,
    buses: []u64,
    busstarts: []u64,
};
pub fn parseInput(inp: []const u8, allocator: *std.mem.Allocator) !InData {
    var retval: InData = undefined;
    var lines = std.mem.split(inp, "\n");
    retval.ts = try std.fmt.parseUnsigned(u64, lines.next().?, 10);
    var busesAL = std.ArrayList(u64).init(allocator);
    defer busesAL.deinit();
    var busStartsAL = std.ArrayList(u64).init(allocator);
    defer busStartsAL.deinit();
    var numEntries = std.mem.split(lines.next().?, ",");
    var index: u64 = 0;
    while (numEntries.next()) |num| : (index += 1) {
        if ((num.len == 0) or (num[0] == 'x')) continue;
        const busnum = try std.fmt.parseUnsigned(u64, num, 10);
        try busesAL.append(busnum);
        try busStartsAL.append(busnum - (index % busnum));
    }
    retval.buses = busesAL.toOwnedSlice();
    retval.busstarts = busStartsAL.toOwnedSlice();
    return retval;
}

pub fn findFirstBus(in: InData) u64 {
    var minBusTsDelta: u64 = std.math.maxInt(u64);
    var minBusNum: u64 = 0;
    for (in.buses) |bus| {
        const nextBusTsDelta = bus - in.ts % bus;
        if (nextBusTsDelta <= minBusTsDelta) {
            minBusTsDelta = nextBusTsDelta;
            minBusNum = bus;
        }
    }
    return minBusNum * minBusTsDelta;
}

pub fn invmod(rawN: u128, n: u128) ?u128 {
    const N: u128 = rawN % n;
    var i: u128 = 0;
    while (i < n) : (i += 1) {
        if ((N * i) % n == 1)
            return i;
    }
    return null;
}

pub fn chinese(n: []const u64, b: []const u64) ?u128 {
    var retval: u128 = 0;
    var N: u128 = 1;
    for (n) |ni|
        N *= @intCast(u128, ni);
    for (n) |_, i| {
        const ni: u128 = N / @intCast(u128, n[i]);
        const xi: u128 = invmod(ni, @intCast(u128, n[i])) orelse return null;
        const xnb = xi * ni * @intCast(u128, b[i]);
        retval += xnb;
    }
    return retval % N;
}

pub fn main() anyerror!void {
    var alloc = std.heap.page_allocator;
    const inps = try parseInput(input, alloc);
    const part1 = findFirstBus(inps);
    const part2: u128 = chinese(inps.buses, inps.busstarts).?;
    std.log.info("Part1: {}", .{part1});
    std.log.info("Part2: {}", .{part2});
}
