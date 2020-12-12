const std = @import("std");
const input = @embedFile("input");

const InstrType = enum {
    turn,
    go,
    shift,
};

const Direction = enum(u2) {
    L,
    R,
};

const Bearing = enum(u2) {
    N,
    S,
    E,
    W,
};

const Command = enum(u1) {
    F,
};

const Vector = struct {
    x: i32 = 0,
    y: i32 = 0,
};

pub fn goDir(v: Vector, b: Bearing, m: i32) Vector {
    const BearingVector = [4][2]i32{
        [2]i32{ 0, 1 }, //N
        [2]i32{ 0, -1 }, //S
        [2]i32{ 1, 0 }, //E
        [2]i32{ -1, 0 }, //W
    };

    const bv = BearingVector[@enumToInt(b)];
    return Vector{ .x = v.x + m * bv[0], .y = v.y + m * bv[1] };
}

const Opcode = union(InstrType) { turn: Direction, shift: Bearing, go: Command };

const Instruction = struct {
    opcode: Opcode,
    distance: i32,
};

const State = struct {
    loc: Vector = Vector{},
    bearing: Bearing = .E,
    waypoint: Vector = Vector{ .x = 10, .y = 1 },
};

pub fn cw(b: Bearing) Bearing {
    return switch (b) {
        .N => .E,
        .E => .S,
        .S => .W,
        .W => .N,
    };
}
pub fn ccw(b: Bearing) Bearing {
    return switch (b) {
        .N => .W,
        .E => .N,
        .S => .E,
        .W => .S,
    };
}

pub fn parseInput(inp: []const u8, allocator: *std.mem.Allocator) ![]Instruction {
    var lines = std.mem.split(inp, "\n");
    var instructions = std.ArrayList(Instruction).init(allocator);
    defer instructions.deinit();
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var inst: Instruction = undefined;
        inst.opcode = switch (line[0]) {
            'N' => Opcode{ .shift = .N },
            'S' => Opcode{ .shift = .S },
            'E' => Opcode{ .shift = .E },
            'W' => Opcode{ .shift = .W },
            'R' => Opcode{ .turn = .R },
            'L' => Opcode{ .turn = .L },
            'F' => Opcode{ .go = .F },
            else => unreachable,
        };
        inst.distance = try std.fmt.parseUnsigned(i32, line[1..], 10);
        try instructions.append(inst);
    }
    return instructions.toOwnedSlice();
}

pub fn processInstructionPart1(curState: State, instr: Instruction) State {
    var nextState: State = undefined;
    nextState.bearing = switch (instr.opcode) {
        Opcode.turn => |dir| switch (dir) {
            .L => switch (instr.distance) {
                90 => ccw(curState.bearing),
                180 => ccw(ccw(curState.bearing)),
                270 => ccw(ccw(ccw(curState.bearing))),
                else => undefined,
            },
            .R => switch (instr.distance) {
                90 => cw(curState.bearing),
                180 => cw(cw(curState.bearing)),
                270 => cw(cw(cw(curState.bearing))),
                else => undefined,
            },
        },
        else => curState.bearing,
    };
    nextState.loc = switch (instr.opcode) {
        Opcode.go => goDir(curState.loc, curState.bearing, instr.distance),
        Opcode.shift => |b| goDir(curState.loc, b, instr.distance),
        Opcode.turn => curState.loc,
    };
    return nextState;
}

pub fn processInstructionPart2(curState: State, instr: Instruction) State {
    var nextState: State = undefined;
    const wx = curState.waypoint.x;
    const wy = curState.waypoint.y;
    const lx = curState.loc.x;
    const ly = curState.loc.y;

    nextState.waypoint = switch (instr.opcode) {
        Opcode.shift => |bear| goDir(curState.waypoint, bear, instr.distance),
        Opcode.turn => |dir| switch (dir) {
            .L => switch (instr.distance) {
                90 => Vector{ .x = -wy, .y = wx },
                180 => Vector{ .x = -wx, .y = -wy },
                270 => Vector{ .x = wy, .y = -wx },
                else => undefined,
            },
            .R => switch (instr.distance) {
                90 => Vector{ .x = wy, .y = -wx },
                180 => Vector{ .x = -wx, .y = -wy },
                270 => Vector{ .x = -wy, .y = wx },
                else => undefined,
            },
        },
        Opcode.go => curState.waypoint,
    };
    nextState.loc = switch (instr.opcode) {
        Opcode.turn => curState.loc,
        Opcode.shift => curState.loc,
        Opcode.go => Vector{ .x = lx + instr.distance * wx, .y = ly + instr.distance * wy },
    };
    return nextState;
}

pub fn main() anyerror!void {
    const instrs = try parseInput(input, std.heap.page_allocator);
    var state1 = State{};
    var state2 = State{};
    for (instrs) |inst| {
        state1 = processInstructionPart1(state1, inst);
        state2 = processInstructionPart2(state2, inst);
    }
    var part1: u32 = std.math.absCast(state1.loc.x) + std.math.absCast(state1.loc.y);
    var part2: u32 = std.math.absCast(state2.loc.x) + std.math.absCast(state2.loc.y);
    std.log.info("Part1:{}", .{part1});
    std.log.info("Part2:{}", .{part2});
}
