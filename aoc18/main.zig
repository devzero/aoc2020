const std = @import("std");
const input = @embedFile("input");

const Num = u128;
const Ops = enum { mult, add };
const ExprTypes = enum { num, eoe };
const ExprOpExpr = struct { lhs: *Expr, op: Ops, rhs: ?*Expr };
const Expr = union(ExprTypes) { num: Num, eoe: ExprOpExpr };
const ParseRet = struct { e: *Expr, newPos: usize };

pub fn parseExpr(line: []const u8, startpos: usize, allocator: *std.mem.Allocator) anyerror!ParseRet {
    //std.log.debug("------ start parse: '{}'", .{line[startpos..]});
    var i: usize = startpos;
    var root: ?*Expr = null;
    while (i < line.len) : (i += 1) {
        const ch = line[i];
        //std.log.debug("== i={} ch='{c}'", .{ i, ch });
        if (' ' == ch) continue;
        if (')' == ch) {
            //i += 1;
            break;
        }
        if (root == null) {
            if (('0' <= ch) and ('9' >= ch)) {
                root = try allocator.create(Expr);
                root.?.* = Expr{ .num = ch - '0' };
            } else if ('(' == ch) {
                var pr = try parseExpr(line, i + 1, allocator);
                root = pr.e;
                i = pr.newPos;
            } else return error.ParseError;
        } else if ((@as(ExprTypes, root.?.*) != .eoe) or (root.?.eoe.rhs != null)) {
            if (('*' == ch) or ('+' == ch)) {
                var op: Ops = switch (ch) {
                    '*' => .mult,
                    '+' => .add,
                    else => unreachable,
                };
                var newexp = try allocator.create(Expr);
                newexp.* = Expr{ .eoe = ExprOpExpr{ .lhs = root.?, .op = op, .rhs = null } };
                root.? = newexp;
            } else return error.ParseError;
        } else {
            if (('0' <= ch) and ('9' >= ch)) {
                root.?.eoe.rhs = try allocator.create(Expr);
                root.?.eoe.rhs.?.* = Expr{ .num = ch - '0' };
            } else if ('(' == ch) {
                var pr = try parseExpr(line, i + 1, allocator);
                root.?.eoe.rhs = pr.e;
                i = pr.newPos;
            } else return error.ParseError;
        }
    }
    if (i > line.len) i = line.len;
    if (root == null) return error.ParseError;
    if ((@as(ExprTypes, root.?.*) != .eoe) or (root.?.eoe.rhs == null)) return error.ParseError;
    //std.log.debug("return ({}): {}", .{ i, root.?.* });
    return ParseRet{ .e = root.?, .newPos = i };
}

pub fn printExpr(expr: *Expr, d: u64) void {
    if (@as(ExprTypes, expr.*) == .num) {
        std.debug.print("{d}", .{expr.num});
    } else {
        const opc: u8 = switch (expr.eoe.op) {
            .mult => '*',
            .add => '+',
        };
        std.debug.print("(", .{});
        printExpr(expr.eoe.lhs, d + 1);
        std.debug.print(" {c} ", .{opc});
        printExpr(expr.eoe.rhs.?, d + 1);
        std.debug.print(")", .{});
    }
    if (d == 0)
        std.debug.print("\n", .{});
}

pub fn evalExpr(expr: *Expr, depth: u64) Num {
    const e = expr.*;
    var val = switch (e) {
        .num => e.num,
        .eoe => switch (e.eoe.op) {
            .mult => blk: {
                const l = evalExpr(e.eoe.lhs, depth + 1);
                const r = evalExpr(e.eoe.rhs.?, depth + 1);
                break :blk l * r;
            },
            .add => blk: {
                const l = evalExpr(e.eoe.lhs, depth + 1);
                const r = evalExpr(e.eoe.rhs.?, depth + 1);
                break :blk l + r;
            },
        },
    };
    if (depth == 0) {
        std.debug.print("{} = ", .{val});
        printExpr(expr, 0);
    }
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
        //std.log.debug("|{}| = {}", .{ line, val });
        part1 += val;
    }
    std.log.info("Part1: {}", .{part1});
}
