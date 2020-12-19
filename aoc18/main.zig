const std = @import("std");
const input = @embedFile("input");

const Num = u128;
const Ops = enum { mult, add };
const ExprTypes = enum { num, subexpr, eoe };
const ExprOpExpr = struct { lhs: *Expr, op: Ops, rhs: *Expr };
const Expr = union(ExprTypes) { num: Num, subexpr: *Expr, eoe: ExprOpExpr };
const ParseRet = struct { e: *Expr, newPos: usize };

pub fn parseExpr(line: []const u8, startpos: usize, allocator: *std.mem.Allocator) anyerror!ParseRet {
    //if (startpos == 0) std.log.debug("------ start parse: '{}'", .{line[startpos..]});
    var i: usize = startpos;
    var retExp: *Expr = undefined;
    var lhs: ?*Expr = null;
    var op: ?Ops = null;
    var rhs: ?*Expr = null;
    while (i < line.len) : (i += 1) {
        const ch = line[i];
        //std.log.debug("== i={} ch='{c}'", .{ i, ch });
        if (' ' == ch) continue;
        if (')' == ch) {
            i += 1;
            break;
        }
        if (lhs == null) {
            if (('0' <= ch) and ('9' >= ch)) {
                lhs = try allocator.create(Expr);
                lhs.?.* = Expr{ .num = ch - '0' };
                //std.log.debug("set lhs={}", .{lhs.?.*.num});
            } else if ('(' == ch) {
                var pr = try parseExpr(line, i + 1, allocator);
                lhs = pr.e;
                i = pr.newPos;
            } else return error.ParseError;
        } else if (op == null) {
            if ('*' == ch) {
                op = .mult;
                //std.log.debug("set op={}", .{op.?});
            } else if ('+' == ch) {
                op = .add;
                //std.log.debug("set op={}", .{op.?});
            } else return error.ParseError;
        } else if (rhs == null) {
            if (('0' <= ch) and ('9' >= ch)) {
                rhs = try allocator.create(Expr);
                rhs.?.* = Expr{ .num = ch - '0' };
                //std.log.debug("set rhs={}", .{rhs.?.*.num});
            } else if ('(' == ch) {
                var pr = try parseExpr(line, i + 1, allocator);
                rhs = pr.e;
                i = pr.newPos;
            } else return error.ParseError;
        } else {
            if (('*' == ch) or ('+' == ch)) {
                var newlhs = try allocator.create(Expr);
                newlhs.* = Expr{ .eoe = ExprOpExpr{ .lhs = lhs.?, .op = op.?, .rhs = rhs.? } };
                lhs = newlhs;
                rhs = null;
                op = switch (ch) {
                    '*' => .mult,
                    '+' => .add,
                    else => unreachable,
                };
            } else return error.ParseError;
        }
    }
    if (i > line.len) i = line.len;
    if ((!(lhs == null)) and (!(op == null)) and (!(rhs == null))) {
        retExp = try allocator.create(Expr);
        retExp.* = Expr{ .eoe = ExprOpExpr{ .lhs = lhs.?, .op = op.?, .rhs = rhs.? } };
    } else if ((!(lhs == null)) and (op == null) and (rhs == null)) {
        retExp = lhs.?;
    } else return error.ParseError;
    return ParseRet{ .e = retExp, .newPos = i };
}

pub fn evalExpr(expr: *Expr, depth: u64) Num {
    const e = expr.*;
    var i: u64 = 0;
    //while (i < depth) : (i += 1)
    //std.debug.print(" ", .{});
    //std.debug.print("{}\n", .{e});
    var val = switch (e) {
        .num => e.num,
        .subexpr => evalExpr(e.subexpr, depth + 1),
        .eoe => switch (e.eoe.op) {
            .mult => blk: {
                const l = evalExpr(e.eoe.lhs, depth + 1);
                //i = 0;
                //while (i < depth) : (i += 1)
                //    std.debug.print("-", .{});
                //std.debug.print("*\n", .{});
                const r = evalExpr(e.eoe.rhs, depth + 1);
                break :blk l * r;
            },
            .add => blk: {
                const l = evalExpr(e.eoe.lhs, depth + 1);
                //i = 0;
                //while (i < depth) : (i += 1)
                //    std.debug.print("-", .{});
                //std.debug.print("+\n", .{});
                const r = evalExpr(e.eoe.rhs, depth + 1);
                break :blk l + r;
            },
        },
    };
    //i = 0;
    //while (i < depth) : (i += 1)
    //    std.debug.print("-", .{});
    //std.debug.print("={}\n", .{val});
    return val;
}

pub fn evalLine(line: []const u8, allocator: *std.mem.Allocator) !Num {
    var parseRet = try parseExpr(line, 0, allocator);
    //std.log.debug("{} ?+ {}", .{ parseRet.newPos, line.len });
    std.debug.assert(parseRet.newPos == line.len);
    return evalExpr(parseRet.e, 0);
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;
    var lines = std.mem.split(input, "\n");
    var part1: Num = 0;
    while (lines.next()) |line| {
        if (0 == line.len) continue;
        var val = try evalLine(line, allocator);
        std.log.debug("|{}| = {}", .{ line, val });
        part1 += val;
    }
    std.log.info("Part1: {}", .{part1});
}
