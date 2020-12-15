const std = @import("std");
const starting = [_]u64{ 16, 12, 1, 0, 15, 7, 11 };

const State = struct {
    turn: u64,
    lastNum: u64,
    lastSeen: ?u64,
    history: *std.AutoHashMap(u64, u64),
    allocator: *std.mem.Allocator,

    pub fn init(starters: []const u64, allocator: *std.mem.Allocator) !State {
        var history: *std.AutoHashMap(u64, u64) = try allocator.create(std.AutoHashMap(u64, u64));
        var lastNum: u64 = 0;
        var lastSeen: ?u64 = null;
        history.* = std.AutoHashMap(u64, u64).init(allocator);
        for (starters) |val, i| {
            lastNum = val;
            lastSeen = history.get(val);
            try history.put(val, i + 1);
        }
        return State{ .turn = starters.len, .lastNum = lastNum, .lastSeen = lastSeen, .history = history, .allocator = allocator };
    }

    pub fn step(self: *State) !void {
        var num: u64 = 0;
        if (self.lastSeen) |lastSeenT| {
            num = self.turn - lastSeenT;
        } else {
            num = 0;
        }
        self.lastNum = num;
        self.lastSeen = self.history.get(num);
        self.turn += 1;
        try self.history.put(num, self.turn);
    }

    pub fn deinit(self: *State) void {
        var all = self.allocator;
        self.history.deinit();
        all.destroy(self.history);
    }
};

pub fn main() anyerror!void {
    var alc = std.heap.page_allocator;
    var state: State = try State.init(starting[0..], alc);
    defer state.deinit();

    while (state.turn < 2020) try state.step();
    var part1 = state.lastNum;
    while (state.turn < 30000000) try state.step();
    var part2 = state.lastNum;
    std.log.info("Part 1: {}", .{part1});
    std.log.info("Part 2: {}", .{part2});
}
