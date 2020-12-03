const std = @import("std");
const input = @embedFile("input");
const ROWS = 323;
const COLS = 31;

pub fn treesHit(trees: [ROWS][COLS]bool, right: u32, down: u32) u32 {
    var hit: u32 = 0;
    var i: u32 = 0;
    var j: u32 = 0;
    while (i < ROWS) : (i += down) {
        if (trees[i][j])
            hit += 1;
        j = (j + right) % COLS;
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
    try std.io.getStdOut().writer().print("Part1: {}\nPart2: {}\n", .{ treesHit(trees, 3, 1), treesHit(trees, 1, 1) * treesHit(trees, 3, 1) * treesHit(trees, 5, 1) * treesHit(trees, 7, 1) * treesHit(trees, 1, 2) });
}
