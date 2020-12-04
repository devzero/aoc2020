const std = @import("std");
const input = @embedFile("input");

const required_fields = .{ "byr:", "iyr:", "eyr:", "hgt:", "hcl:", "ecl:", "pid:" };

pub fn isValidField(field: []const u8, data: []u8) bool {
    if (std.mem.eql(u8, field, "byr:")) {
        var year: u16 = std.fmt.parseUnsigned(u16, data, 10) catch return false;
        if ((year >= 1920) and (year <= 2002)) return true;
    }

    if (std.mem.eql(u8, field, "iyr:")) {
        var year: u16 = std.fmt.parseUnsigned(u16, data, 10) catch return false;
        if ((year >= 2010) and (year <= 2020)) return true;
    }

    if (std.mem.eql(u8, field, "eyr:")) {
        var year: u16 = std.fmt.parseUnsigned(u16, data, 10) catch return false;
        if ((year >= 2020) and (year <= 2030)) return true;
    }

    if (std.mem.eql(u8, field, "hgt:")) {
        var hgt: u16 = std.fmt.parseUnsigned(u16, data[0 .. data.len - 2], 10) catch return false;
        if (std.mem.eql(u8, data[data.len - 2 .. data.len], "cm"))
            if ((hgt >= 150) and (hgt <= 193)) return true;
        if (std.mem.eql(u8, data[data.len - 2 .. data.len], "in"))
            if ((hgt >= 59) and (hgt <= 76)) return true;
    }

    if (std.mem.eql(u8, field, "hcl:")) {
        if (data.len != 7) return false;
        if (data[0] != '#') return false;
        for (data[1..7]) |ch| {
            if ((('0' > ch) or ('9' < ch)) and (('a' > ch) or ('f' < ch))) return false;
        }
        return true;
    }

    if (std.mem.eql(u8, field, "ecl:")) {
        inline for (.{ "amb", "blu", "brn", "gry", "grn", "hzl", "oth" }) |color| {
            if (std.mem.eql(u8, color, data)) return true;
        }
        return false;
    }

    if (std.mem.eql(u8, field, "pid:")) {
        if (data.len != 9) return false;
        for (data[0..9]) |ch| {
            if (('0' > ch) or ('9' < ch)) return false;
        }
        return true;
    }

    return false;
}

pub fn main() anyerror!void {
    var part1_valid_passports: u32 = 0;
    var part2_valid_passports: u32 = 0;
    var it = std.mem.split(input, "\n\n");
    while (it.next()) |raw_passport| {
        var passport_buf: [input.len]u8 = std.mem.zeroes([input.len]u8);
        var replacements = std.mem.replace(u8, raw_passport, "\n", " ", &passport_buf);
        var passport = passport_buf[0..raw_passport.len];

        var seen_fields: u8 = 0;
        var valid_fields: u8 = 0;
        inline for (required_fields) |field| {
            if (std.mem.indexOf(u8, passport, field)) |field_idx| {
                seen_fields += 1;
                var data_slice: []u8 = undefined;
                if (std.mem.indexOfPos(u8, passport, field_idx, " ")) |field_end| {
                    data_slice = passport[field_idx + 4 .. field_end];
                } else {
                    data_slice = passport[field_idx + 4 ..];
                }
                if (isValidField(field[0..4], data_slice))
                    valid_fields += 1;
            }
        }
        if (seen_fields == 7)
            part1_valid_passports += 1;
        if (valid_fields == 7)
            part2_valid_passports += 1;
    }
    std.log.info("part1: {}", .{part1_valid_passports});
    std.log.info("part2: {}", .{part2_valid_passports});
}
