const std = @import("std");
const input = @embedFile("input");

const required_fields = .{ "byr:", "iyr:", "eyr:", "hgt:", "hcl:", "ecl:", "pid:" };

pub fn isValidField(field: []const u8, data: []u8) bool {
    if (std.mem.eql(u8, field, "byr:")) {
        const year: u16 = std.fmt.parseUnsigned(u16, data, 10) catch return false;
        if ((year >= 1920) and (year <= 2002)) return true;
    } else if (std.mem.eql(u8, field, "iyr:")) {
        const year: u16 = std.fmt.parseUnsigned(u16, data, 10) catch return false;
        if ((year >= 2010) and (year <= 2020)) return true;
    } else if (std.mem.eql(u8, field, "eyr:")) {
        const year: u16 = std.fmt.parseUnsigned(u16, data, 10) catch return false;
        if ((year >= 2020) and (year <= 2030)) return true;
    } else if (std.mem.eql(u8, field, "hgt:")) {
        const hgt: u16 = std.fmt.parseUnsigned(u16, data[0 .. data.len - 2], 10) catch return false;
        if (std.mem.eql(u8, data[data.len - 2 .. data.len], "cm"))
            if ((hgt >= 150) and (hgt <= 193)) return true;
        if (std.mem.eql(u8, data[data.len - 2 .. data.len], "in"))
            if ((hgt >= 59) and (hgt <= 76)) return true;
    } else if (std.mem.eql(u8, field, "hcl:")) {
        if (data.len != 7) return false;
        if (data[0] != '#') return false;
        for (data[1..7]) |ch| {
            if ((('0' > ch) or ('9' < ch)) and (('a' > ch) or ('f' < ch))) return false;
        }
        return true;
    } else if (std.mem.eql(u8, field, "ecl:")) {
        inline for (.{ "amb", "blu", "brn", "gry", "grn", "hzl", "oth" }) |color| {
            if (std.mem.eql(u8, color, data)) return true;
        }
        return false;
    } else if (std.mem.eql(u8, field, "pid:")) {
        if (data.len != 9) return false;
        for (data[0..9]) |ch| {
            if (('0' > ch) or ('9' < ch)) return false;
        }
        return true;
    }
    return false;
}

pub fn main() anyerror!void {
    var part1: u32 = 0;
    var part2: u32 = 0;
    var it = std.mem.split(input, "\n\n");
    while (it.next()) |raw_passport| {
        var all_fields_there = true;
        var all_fields_valid = true;
        const passport = try std.mem.replaceOwned(u8, std.heap.page_allocator, raw_passport, "\n", " ");
        defer std.heap.page_allocator.free(passport);

        inline for (required_fields) |field| {
            if (std.mem.indexOf(u8, passport, field)) |field_idx| {
                const data_start = field_idx + 4;
                const data_end = std.mem.indexOfPos(u8, passport, data_start, " ") orelse passport.len;
                const data: []u8 = passport[data_start..data_end];
                if (!isValidField(field, data)) all_fields_valid = false;
            } else all_fields_there = false;
        }
        if (all_fields_there) part1 += 1;
        if (all_fields_valid) part2 += 1;
    }
    std.log.info("part1: {}", .{part1});
    std.log.info("part2: {}", .{part2});
}
