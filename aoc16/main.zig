const std = @import("std");
const input = @embedFile("input");

const RuleRange = [1024]bool;
const NumFields = 20;
const Ticket = [NumFields]u10;
const Rule = struct {
    isDeparture: bool = false,
    bounds: [2]RuleRange = [2][_]bool{ [_]bool{false} ** 1024, [_]bool{false} ** 1024 },
};

const AllInput = struct {
    valid: RuleRange,
    rules: [NumFields]Rule,
    yours: Ticket,
    theirs: []Ticket,
};

pub fn parseInput(inp: []const u8, allocator: *std.mem.Allocator) !AllInput {
    var sections = std.mem.split(inp, "\n\n");
    var valid = std.mem.zeroes(RuleRange);
    var yours = std.mem.zeroes(Ticket);
    var lines = std.mem.split(sections.next().?, "\n");
    var rules: [NumFields]Rule = undefined;
    var ruleNum: u8 = 0;

    while (lines.next()) |line| : (ruleNum += 1) {
        const colon = std.mem.indexOf(u8, line, ":").?;
        rules[ruleNum].isDeparture = std.mem.startsWith(u8, line, "departure");
        var tokens = std.mem.split(line[colon + 2 ..], " ");
        const firstrange = tokens.next().?;
        _ = tokens.next();
        const secondrange = tokens.next().?;
        var range = firstrange;
        inline for (.{ 0, 1 }) |times| {
            const dash = std.mem.indexOf(u8, range, "-").?;
            var low = try std.fmt.parseUnsigned(u10, range[0..dash], 10);
            var high = try std.fmt.parseUnsigned(u10, range[dash + 1 ..], 10);
            var i: u10 = low;
            while (i <= high) : (i += 1) {
                valid[i] = true;
                rules[ruleNum].bounds[times][i] = true;
            }
            range = secondrange;
        }
    }

    lines = std.mem.split(sections.next().?, "\n");
    std.debug.assert(std.mem.eql(u8, lines.next().?, "your ticket:"));
    var fieldVals = std.mem.split(lines.next().?, ",");
    var i: u8 = 0;
    while (fieldVals.next()) |fieldVal| : (i += 1) {
        yours[i] = try std.fmt.parseUnsigned(u10, fieldVal, 10);
    }

    lines = std.mem.split(sections.next().?, "\n");
    std.debug.assert(std.mem.eql(u8, lines.next().?, "nearby tickets:"));
    var tickets = std.ArrayList(Ticket).init(allocator);
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var thisTicket = std.mem.zeroes(Ticket);
        i = 0;
        fieldVals = std.mem.split(line, ",");
        while (fieldVals.next()) |fieldVal| : (i += 1) {
            thisTicket[i] = try std.fmt.parseUnsigned(u10, fieldVal, 10);
        }
        try tickets.append(thisTicket);
    }
    return AllInput{ .valid = valid, .rules = rules, .yours = yours, .theirs = tickets.toOwnedSlice() };
}

pub fn badFields(valid: RuleRange, t: Ticket, allocator: *std.mem.Allocator) !?[]u10 {
    var results = std.ArrayList(u10).init(allocator);
    defer results.deinit();
    for (t) |field| {
        if (!valid[field]) {
            try results.append(field);
        }
    }
    if (results.items.len > 0) {
        return results.toOwnedSlice();
    } else {
        return null;
    }
}

pub fn possibleRC(in: AllInput, allocator: *std.mem.Allocator) ![NumFields][NumFields]bool {
    var possibleColRules: [NumFields][NumFields]bool = undefined;
    var colNum: u8 = 0;
    while (colNum < NumFields) : (colNum += 1) {
        for (in.rules) |rule, ruleNum| {
            possibleColRules[colNum][ruleNum] = true;
            for (in.theirs) |ticket| {
                if (try badFields(in.valid, ticket, allocator)) |_| continue;
                const colVal = ticket[colNum];
                if (!(rule.bounds[0][colVal] or rule.bounds[1][colVal])) {
                    possibleColRules[colNum][ruleNum] = false;
                }
            }
        }
    }
    return possibleColRules;
}

pub fn assignCol2Rule(in: AllInput, possibleColRules: *[NumFields][NumFields]bool) [NumFields]u8 {
    var colNum: u8 = 0;
    var solvedCols: u8 = 0;
    var col2rule: [NumFields]u8 = [_]u8{0} ** NumFields;
    while (solvedCols < NumFields) {
        while (colNum < NumFields) : (colNum += 1) {
            var posTally: u8 = 0;
            var lastRuleMatch: u8 = 0;
            for (in.rules) |rule, ruleNum| {
                if (possibleColRules[colNum][ruleNum]) {
                    posTally += 1;
                    lastRuleMatch = @intCast(u8, ruleNum);
                }
            }
            if (posTally == 1) {
                col2rule[colNum] = lastRuleMatch;
                solvedCols += 1;
                var col2: u8 = 0;
                while (col2 < NumFields) : (col2 += 1) {
                    possibleColRules[col2][lastRuleMatch] = false;
                }
                colNum = 0;
                break;
            }
        }
    }
    return col2rule;
}

pub fn main() anyerror!void {
    const in = try parseInput(input, std.heap.page_allocator);

    var part1: usize = 0;
    std.debug.assert((try badFields(in.valid, in.yours, std.heap.page_allocator)) == null);
    for (in.theirs) |ticket| {
        for ((try badFields(in.valid, ticket, std.heap.page_allocator)) orelse &[0]u10{}) |badval| {
            part1 += badval;
        }
    }
    std.log.info("Part 1: {}", .{part1});

    var part2: usize = 1;
    var possibleColRules = try possibleRC(in, std.heap.page_allocator);
    var col2rule = assignCol2Rule(in, &possibleColRules);
    for (in.yours) |yourField, fieldNum| {
        part2 *= if (in.rules[col2rule[fieldNum]].isDeparture) yourField else 1;
    }
    std.log.info("Part 2: {}", .{part2});
}
