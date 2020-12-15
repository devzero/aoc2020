const std = @import("std");
const input = @embedFile("input");
const parseUnsigned = std.fmt.parseUnsigned;

pub fn main() anyerror!void {
    var memoryp1 = std.AutoHashMap(u64, u36).init(std.heap.page_allocator);
    defer memoryp1.deinit();
    var memoryp2 = std.AutoHashMap(u64, u36).init(std.heap.page_allocator);
    defer memoryp2.deinit();
    var maskx: u36 = 0;
    var maskv: u36 = 0;
    var numxs: usize = 0;
    var part1: u64 = 0;
    var part2: u64 = 0;

    var lines = std.mem.split(input, "\n");
    while (lines.next()) |line| {
        var strbufx: [36]u8 = std.mem.zeroes([36]u8);
        var strbufv: [36]u8 = std.mem.zeroes([36]u8);
        if (line.len == 0) continue;
        if (std.mem.eql(u8, line[0..4], "mask")) {
            _ = std.mem.replace(u8, line[7..43], "1", "0", strbufx[0..]);
            numxs = std.mem.replace(u8, strbufx[0..], "X", "1", strbufx[0..]);
            _ = std.mem.replace(u8, line[7..43], "X", "0", strbufv[0..]);
            maskx = try parseUnsigned(u36, &strbufx, 2);
            maskv = try parseUnsigned(u36, &strbufv, 2);
        } else if (std.mem.eql(u8, line[0..4], "mem[")) {
            const closebracket = std.mem.indexOf(u8, line, "]").?;
            const memidx: u36 = try parseUnsigned(u36, line[4..closebracket], 10);
            const memval: u36 = try parseUnsigned(u36, line[closebracket + 4 ..], 10);
            const part1val: u36 = (memval & maskx) | maskv;
            try memoryp1.put(@intCast(u64, memidx), part1val);
            const p2addrBase = ((memidx & ~maskx) | maskv);
            var xcounter: u36 = 0;
            if (numxs == 0) unreachable;
            const numaddrs: u36 = try std.math.powi(u36, 2, @intCast(u36, numxs));
            while (xcounter < numaddrs) : (xcounter += 1) {
                var newaddr: u36 = p2addrBase;
                var maskbit: u36 = 1;
                var xbit: u8 = 0;
                while (xbit < 36) : (xbit += 1) {
                    const xbitval = (maskx & (try std.math.powi(u36, 2, xbit)));
                    if (xbitval == 0) continue;
                    if ((xcounter & maskbit) == 0) {
                        newaddr |= xbitval;
                    }
                    maskbit *= 2;
                }
                try memoryp2.put(@intCast(u64, newaddr), memval);
            }
        } else unreachable;
    }
    var memiter1 = memoryp1.iterator();
    while (memiter1.next()) |entry| {
        part1 += @intCast(u64, entry.value);
    }
    var memiter2 = memoryp2.iterator();
    while (memiter2.next()) |entry| {
        part2 += @intCast(u64, entry.value);
    }
    std.log.info("Part1: {}", .{part1});
    std.log.info("Part2: {}", .{part2});
}
