const std = @import("std");
const input = @embedFile("input");

const Num = u128;
const Ops = enum { mult, add };
const ExprTypes = enum { num, eoe, sub };
const ExprOpExpr = struct { lhs: *Expr, op: Ops, rhs: ?*Expr };
const Expr = union(ExprTypes) { num: Num, eoe: ExprOpExpr, sub: *Expr };
const ParseRet = struct { e: *Expr, newPos: usize };

pub fn parseExpr(line: []const u8, startpos: usize, part1: bool, allocator: *std.mem.Allocator) anyerror!ParseRet {
    var i: usize = startpos;
    var root: ?*Expr = null;
    while (i < line.len) : (i += 1) {
        const ch = line[i];
        if (' ' == ch) continue;
        if (')' == ch) {
            break;
        }
        var empty: *Expr = undefined;
        if (root) |rt| {
            empty = rt;
            while ((@as(ExprTypes, empty.*) == .eoe) and (empty.eoe.rhs != null))
                empty = empty.eoe.rhs.?;
        }
        if (root == null) {
            if (('0' <= ch) and ('9' >= ch)) {
                root = try allocator.create(Expr);
                root.?.* = Expr{ .num = ch - '0' };
            } else if ('(' == ch) {
                var pr = try parseExpr(line, i + 1, part1, allocator);
                i = pr.newPos;
                root = try allocator.create(Expr);
                root.?.* = Expr{ .sub = pr.e };
            } else return error.ParseError;
        } else if ((@as(ExprTypes, root.?.*) != .eoe) or (@as(ExprTypes, empty.*) != .eoe)) {
            if (('*' == ch) or ('+' == ch)) {
                var op: Ops = switch (ch) {
                    '*' => .mult,
                    '+' => .add,
                    else => unreachable,
                };
                var newexp = try allocator.create(Expr);
                if (part1) {
                    newexp.* = Expr{ .eoe = ExprOpExpr{ .lhs = root.?, .op = op, .rhs = null } };
                    root.? = newexp;
                } else {
                    if ('*' == ch) {
                        newexp.* = Expr{ .eoe = ExprOpExpr{ .lhs = root.?, .op = op, .rhs = null } };
                        root.? = newexp;
                    } else {
                        var tail: *Expr = root.?;
                        var tailParent: **Expr = &root.?;
                        while (@as(ExprTypes, tail.*) == .eoe) {
                            tailParent = &(tailParent.*.eoe.rhs.?);
                            tail = tail.eoe.rhs.?;
                        }
                        newexp.* = Expr{ .eoe = ExprOpExpr{ .lhs = tail, .op = op, .rhs = null } };
                        tailParent.* = newexp;
                    }
                }
            } else return error.ParseError;
        } else {
            if (('0' <= ch) and ('9' >= ch)) {
                empty.eoe.rhs = try allocator.create(Expr);
                empty.eoe.rhs.?.* = Expr{ .num = ch - '0' };
            } else if ('(' == ch) {
                var pr = try parseExpr(line, i + 1, part1, allocator);
                empty.eoe.rhs = pr.e;
                i = pr.newPos;
                empty.eoe.rhs.? = try allocator.create(Expr);
                empty.eoe.rhs.?.* = Expr{ .sub = pr.e };
            } else return error.ParseError;
        }
    }
    if (i > line.len) i = line.len;
    if (root == null) return error.ParseError;
    if ((@as(ExprTypes, root.?.*) != .eoe) or (root.?.eoe.rhs == null)) return error.ParseError;
    return ParseRet{ .e = root.?, .newPos = i };
}

pub fn printExpr(expr: *Expr, d: u64) void {
    if (@as(ExprTypes, expr.*) == .num) {
        std.debug.print("{d}", .{expr.num});
    } else if (@as(ExprTypes, expr.*) == .sub) {
        std.debug.print("<", .{});
        printExpr(expr.sub, d + 1);
        std.debug.print(">", .{});
    } else {
        const opc: u8 = switch (expr.eoe.op) {
            .mult => '*',
            .add => '+',
        };
        std.debug.print("(", .{});
        printExpr(expr.eoe.lhs, d + 1);
        std.debug.print(" {c} ", .{opc});
        if (expr.eoe.rhs) |rhs| {
            printExpr(rhs, d + 1);
        } else {
            std.debug.print("N", .{});
        }
        std.debug.print(")", .{});
    }
    if (d == 0)
        std.debug.print("\n", .{});
}

pub fn evalExpr(expr: *Expr, depth: u64) Num {
    const e = expr.*;
    var val = switch (e) {
        .num => e.num,
        .sub => evalExpr(e.sub, depth + 1),
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
    return val;
}

pub fn evalLine(line: []const u8, part1: bool, allocator: *std.mem.Allocator) !Num {
    var parseRet = try parseExpr(line, 0, part1, allocator);
    std.debug.assert(parseRet.newPos == line.len);
    return evalExpr(parseRet.e, 0);
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;
    var lines = std.mem.split(input, "\n");
    var part1: Num = 0;
    var part2: Num = 0;
    while (lines.next()) |line| {
        if (0 == line.len) continue;
        part1 += try evalLine(line, true, allocator);
        part2 += try evalLine(line, false, allocator);
    }
    std.log.info("Part1: {}", .{part1});
    std.log.info("Part2: {}", .{part2});
}
