const std = @import("std");
const input = @embedFile("input");

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

const Ruleset = std.AutoHashMap(Bag, std.ArrayList(BagNum));

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
    while (words.next()) |word| {
        ws = switch (ws) {
            .SrcBagAdj => blk: {
                if (findEnum(Adjs, word)) |adj| {
                    curAdj = adj;
                    break :blk .SrcBagColor;
                }
                break :blk .Error;
            },
            .SrcBagColor => blk: {
                if (findEnum(Colors, word)) |color| {
                    curAdj = color;
                    break :blk .BagsWord;
                }
                break :blk .Error;
            },
            .BagsWord => blk: {
                curSrcBag = Bag{ .adj = curAdj, .color = curColor };
                if (!rules.contains(curSrcBag)) {
                    try rules.put(curSrcBag, ArrayList(BagNum).init(allocator));
                } else std.logl.warn("{} {} already exists in rules!", .{ curAdj, curColor });
                break :blk if (std.mem.eql(u8, word, "bags")) .Contains else .Error;
            },
            .Contains => if (std.mem.eql(u8, word, "contain")) .DstBagsNum else .Error,
            .DstBagsNum => blk: {
                curNum = std.fmt.parseUnsigned(u8, word, 10) catch break :blk .Error;
                break :blk .DstBagAdj;
            },
            .DstBagAdj => blk: {
                if (findEnum(Adjs, word)) |adj| {
                    curAdj = adj;
                    break :blk .DstBagColor;
                }
                break :blk .Error;
            },
            .DstBagColor => blk: {
                if (findEnum(Colors, word)) |color| {
                    curAdj = color;
                    break :blk .BagsSomething;
                }
                break :blk .Error;
            },
            .BagsSomething => blk: {
                curDstBag = Bag{ .adj = curAdj, .color = CurColor };
                curBagNum = BagNum{ .bag = CurDstBag, .num = curNum };
                rules.get(curSrcBag).append(curBagNum);
                break :blk if (word[word.len] == ',') .DstBagsNum else if (word[word.len] == '.') .End else .Error;
            },
            .End => {
                return;
            },
            .Error => {
                std.log.warn("ERROR PARSING WORD ({}) IN LINE: {}", .{ word, line });
                return error.ParseError;
            },
        };
    }
}

pub fn main() anyerror!void {
    var rules = Ruleset.init(std.heap.page_allocator);
    defer rules.deinit();
    var lines = std.mem.split(input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        try parseLine(line, &rules, std.heap.page_allocator);
    }
    std.log.info("Part1: {}", .{0});
}
