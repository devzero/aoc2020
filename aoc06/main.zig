const std = @import("std");
const input = @embedFile("input");

pub fn main() anyerror!void {
    var part1: u32 = 0;
    var part2: u32 = 0;

    var it_groups = std.mem.split(input, "\n\n");
    while (it_groups.next()) |group| {
        var anyqs: [26]bool = std.mem.zeroes([26]bool);
        var commonqs: [26]bool = undefined;
        for (commonqs) |*q| q.* = true;

        var it_forms = std.mem.split(group, "\n");
        while (it_forms.next()) |form| {
            if (form.len == 0) continue;

            for (form) |ch| {
                anyqs[ch - 'a'] = true;
            }

            var ch: u8 = 'a';
            while (ch <= 'z') : (ch += 1) {
                if (std.mem.indexOfScalar(u8, form, ch) == null)
                    commonqs[ch - 'a'] = false;
            }
        }

        var num_qs: u32 = 0;
        var num_commonqs: u32 = 0;
        for (anyqs) |q| {
            if (q) num_qs += 1;
        }
        for (commonqs) |q, i| {
            if (q) num_commonqs += 1;
        }
        part1 += num_qs;
        part2 += num_commonqs;
    }
    std.log.debug("Part1: {}", .{part1});
    std.log.debug("Part2: {}", .{part2});
}
