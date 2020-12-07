const std = @import("std");
const input = @embedFile("input");
const ArrayList = std.ArrayList;

const Adjs = enum {
    bright,
    clear,
    dark,
    dim,
    dotted,
    drab,
    dull,
    faded,
    light,
    mirrored,
    muted,
    pale,
    plaid,
    posh,
    shiny,
    striped,
    vibrant,
    wavy,
};

const Colors = enum {
    aqua,
    beige,
    black,
    blue,
    bronze,
    brown,
    chartreuse,
    coral,
    crimson,
    cyan,
    fuchsia,
    gold,
    gray,
    green,
    indigo,
    lavender,
    lime,
    magenta,
    maroon,
    olive,
    orange,
    plum,
    purple,
    red,
    salmon,
    silver,
    tan,
    teal,
    tomato,
    turquoise,
    violet,
    white,
    yellow,
};

const WordState = enum {
    SrcBagAdj,
    SrcBagColor,
    BagsWord,
    Contains,
    DstBagsNum,
    DstBagAdj,
    DstBagColor,
    BagsSomething,
    End,
    Error,
};

const Bag = struct { adj: Adjs, color: Colors };

const BagNum = struct { bag: Bag, num: u8 };

const Ruleset = std.AutoHashMap(Bag, []BagNum);

pub fn findEnum(comptime T: type, word: []const u8) ?T {
    inline for (@typeInfo(T).Enum.fields) |xEnumInfo| {
        if (std.mem.eql(u8, word, xEnumInfo.name)) {
            return @intToEnum(T, xEnumInfo.value);
        }
    }
    return null;
}

pub fn parseLine(line: []const u8, rules: *Ruleset, allocator: *std.mem.Allocator) !void {
    var words = std.mem.split(line, " ");
    var ws: WordState = .SrcBagAdj;
    var curAdj: Adjs = undefined;
    var curColor: Colors = undefined;
    var curSrcBag: Bag = undefined;
    var curNum: u8 = undefined;
    var curDstBag: Bag = undefined;
    var curBagNum: BagNum = undefined;
    var curList = ArrayList(BagNum).init(allocator);
    while (words.next()) |word| {
        ws = switch (ws) {
            .SrcBagAdj => blk: {
                if (findEnum(Adjs, word)) |adj| {
                    curAdj = adj;
                    break :blk .SrcBagColor;
                }
                break :blk WordState.Error;
            },
            .SrcBagColor => blk: {
                if (findEnum(Colors, word)) |color| {
                    curColor = color;
                    break :blk .BagsWord;
                }
                break :blk WordState.Error;
            },
            .BagsWord => blk: {
                curSrcBag = Bag{ .adj = curAdj, .color = curColor };
                break :blk if (std.mem.eql(u8, word, "bags")) .Contains else WordState.Error;
            },
            .Contains => if (std.mem.eql(u8, word, "contain")) .DstBagsNum else WordState.Error,
            .DstBagsNum => blk: {
                if (std.mem.eql(u8, word, "no")) {
                    try rules.put(curSrcBag, curList.toOwnedSlice());
                    break :blk .End;
                }
                curNum = std.fmt.parseUnsigned(u8, word, 10) catch break :blk WordState.Error;
                break :blk .DstBagAdj;
            },
            .DstBagAdj => blk: {
                if (findEnum(Adjs, word)) |adj| {
                    curAdj = adj;
                    break :blk .DstBagColor;
                }
                break :blk WordState.Error;
            },
            .DstBagColor => blk: {
                if (findEnum(Colors, word)) |color| {
                    curColor = color;
                    break :blk .BagsSomething;
                }
                break :blk WordState.Error;
            },
            .BagsSomething => blk: {
                curDstBag = Bag{ .adj = curAdj, .color = curColor };
                curBagNum = BagNum{ .bag = curDstBag, .num = curNum };
                try curList.append(curBagNum);
                if (word[word.len - 1] == ',')
                    break :blk .DstBagsNum;
                if (word[word.len - 1] == '.') {
                    try rules.put(curSrcBag, curList.toOwnedSlice());
                    break :blk .End;
                }
                break :blk WordState.Error;
            },
            .End => {
                return;
            },
            WordState.Error => {
                std.log.warn("ERROR PARSING WORD ({}) IN LINE: {}", .{ word, line });
                return error.ParsError;
            },
        };
    }
}

pub fn findBag(needle: Bag, rules: Ruleset, allocator: *std.mem.Allocator) ![]Bag {
    var bagList = ArrayList(Bag).init(allocator);
    var rule_it = rules.iterator();
    while (rule_it.next()) |rule_bag| {
        var candidate_bag = rule_bag.key;
        for (rule_bag.value) |bagNum| {
            if ((bagNum.bag.adj == needle.adj) and (bagNum.bag.color == needle.color)) {
                try bagList.append(candidate_bag);
            }
        }
    }
    return bagList.toOwnedSlice();
}

pub fn subBags(parent: Bag, rules: Ruleset) u64 {
    var retval: u64 = 1;
    var subBagNums = rules.get(parent);
    if (subBagNums) |subs| {
        for (subs) |subBagNum| {
            retval += subBagNum.num * (subBags(subBagNum.bag, rules));
        }
    }
    return retval;
}

pub fn main() anyerror!void {
    var rules = Ruleset.init(std.heap.page_allocator);
    defer rules.deinit();
    var lines = std.mem.split(input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        try parseLine(line, &rules, std.heap.page_allocator);
    }

    var soln_set = std.AutoHashMap(Bag, void).init(std.heap.page_allocator);
    var last_size: u32 = 0;
    for (try findBag(Bag{ .adj = .shiny, .color = .gold }, rules, std.heap.page_allocator)) |bag| {
        try soln_set.put(bag, {});
    }
    while (soln_set.count() != last_size) {
        last_size = soln_set.count();
        var it = soln_set.iterator();
        while (it.next()) |entry| {
            for (try findBag(entry.key, rules, std.heap.page_allocator)) |bag| {
                try soln_set.put(bag, {});
            }
        }
    }
    std.log.info("Part1: {}", .{soln_set.count()});
    std.log.info("Part2: {}", .{subBags(Bag{ .adj = .shiny, .color = .gold }, rules) - 1});
}
