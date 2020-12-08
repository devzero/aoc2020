const std = @import("std");
const input = @embedFile("input");
const ArrayList = std.ArrayList;
const HashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const iMem = i32;

const Mnemonic = enum {
    nop,
    acc,
    jmp,
};

const Instruction = struct {
    mnem: Mnemonic,
    param: iMem,
};

const CPUState = struct {
    ip: usize,
    acc: iMem,
    halted: bool,
};

pub fn findEnum(comptime T: type, word: []const u8) ?T {
    inline for (@typeInfo(T).Enum.fields) |xEnumInfo| {
        if (std.mem.eql(u8, word, xEnumInfo.name)) {
            return @intToEnum(T, xEnumInfo.value);
        }
    }
    return null;
}

pub fn step(ip: usize, mem: []Instruction, acc: *iMem) usize {
    const instr = mem[ip];
    return switch (instr.mnem) {
        .nop => ip + 1,
        .acc => blk: {
            acc.* += instr.param;
            break :blk ip + 1;
        },
        .jmp => @intCast(usize, @intCast(i32, ip) + instr.param),
    };
}

pub fn run(mem: []Instruction, allocator: *Allocator) !CPUState {
    var acc: iMem = 0;
    var ip: usize = 0;
    var seen_ips = HashMap(usize, void).init(allocator);
    defer seen_ips.deinit();
    while (!seen_ips.contains(ip)) {
        try seen_ips.put(ip, {});
        ip = step(ip, mem, &acc);
        if (ip == mem.len)
            return CPUState{ .ip = ip, .acc = acc, .halted = true };
    }
    return CPUState{ .ip = ip, .acc = acc, .halted = false };
}

pub fn flipInstr(instr: Instruction) Instruction {
    return Instruction{
        .mnem = switch (instr.mnem) {
            .nop => .jmp,
            .jmp => .nop,
            .acc => .acc,
        },
        .param = instr.param,
    };
}

pub fn findFlipped(mem: []Instruction, allocator: *Allocator) !iMem {
    var newmem = try allocator.alloc(Instruction, mem.len);
    defer allocator.free(newmem);

    for (mem) |orig_instr, i| {
        std.mem.copy(Instruction, newmem, mem);
        newmem[i] = flipInstr(orig_instr);
        const state = try run(newmem, allocator);
        if (state.halted)
            return state.acc;
    }
    return error.NeverHalted;
}
pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;
    var memArray = ArrayList(Instruction).init(allocator);
    defer memArray.deinit();

    var lines = std.mem.split(input, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        std.debug.assert(line[3] == ' ');
        var instr = Instruction{ .mnem = findEnum(Mnemonic, line[0..3]).?, .param = try std.fmt.parseInt(iMem, line[4..line.len], 10) };
        try memArray.append(instr);
    }
    const mem = memArray.toOwnedSlice();

    var part1 = (try run(mem, allocator)).acc;
    var part2 = try findFlipped(mem, allocator);
    std.log.info("Part1: {}", .{part1});
    std.log.info("Part2: {}", .{part2});
}
