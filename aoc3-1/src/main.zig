const std = @import("std");
const input = @embedFile("../input");
const ROWS = 323;
const COLS = 31;
const RIGHT = 3;
const DOWN = 1;

pub fn treesHit(trees: [ROWS][COLS]bool) u32 {
    var hit: u32 = 0;
    var i: u32 = 0;
    var j: u32 = 0;
    while (i < ROWS) : (i += DOWN) {
        if (trees[i][j])
            hit += 1;
        j = (j + RIGHT) % COLS;
    }
    return hit;
}

pub fn main() anyerror!void {
    var trees: [ROWS][COLS]bool = std.mem.zeroes([ROWS][COLS]bool);
    var it = std.mem.split(input, "\n");
    var lineno: u32 = 0;
    while (it.next()) |line| {
        for (line) |ch, i| {
            trees[lineno][i] = switch (ch) {
                '#' => true,
                '.' => false,
                else => unreachable,
            };
        }
        lineno += 1;
    }
    try std.io.getStdOut().writer().print("{}", .{treesHit(trees)});
}
