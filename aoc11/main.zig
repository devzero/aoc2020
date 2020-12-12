const std = @import("std");
const input = @embedFile("input");
const ROWS = 95;
const COLS = 92;

const Spot = enum {
    floor,
    empty,
    occupied,
};

const Board = [ROWS][COLS]Spot;

pub fn char2Spot(c: u8) Spot {
    return switch (c) {
        '.' => .floor,
        'L' => .empty,
        '#' => .occupied,
        else => unreachable,
    };
}

pub fn parseInput(inp: []const u8, allocator: *std.mem.Allocator) Board {
    var board: Board = std.mem.zeroes(Board);
    var lines = std.mem.split(inp, "\n");
    var row: u32 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        for (line) |c, col| {
            board[row][col] = char2Spot(c);
        }
        row += 1;
    }
    return board;
}

pub fn adjOccupied(row: usize, col: usize, board: Board) u8 {
    var result: u8 = 0;
    result += if ((row > 0) and (col > 0) and (board[row - 1][col - 1] == .occupied)) @intCast(u8, 1) else @intCast(u8, 0);
    result += if ((row > 0) and (board[row - 1][col] == .occupied)) @intCast(u8, 1) else @intCast(u8, 0);
    result += if ((row > 0) and (col < COLS - 1) and (board[row - 1][col + 1] == .occupied)) @intCast(u8, 1) else @intCast(u8, 0);
    result += if ((col > 0) and (board[row][col - 1] == .occupied)) @intCast(u8, 1) else @intCast(u8, 0);
    result += if ((col < COLS - 1) and (board[row][col + 1] == .occupied)) @intCast(u8, 1) else @intCast(u8, 0);
    result += if ((row < ROWS - 1) and (col > 0) and (board[row + 1][col - 1] == .occupied)) @intCast(u8, 1) else @intCast(u8, 0);
    result += if ((row < ROWS - 1) and (board[row + 1][col] == .occupied)) @intCast(u8, 1) else @intCast(u8, 0);
    result += if ((row < ROWS - 1) and (col < COLS - 1) and (board[row + 1][col + 1] == .occupied)) @intCast(u8, 1) else @intCast(u8, 0);
    return result;
}

pub fn visibleOccupied(row: usize, col: usize, board: Board) u8 {
    var result: u8 = 0;
    const vecs = [8][2]i8{ [_]i8{ -1, -1 }, [_]i8{ -1, 0 }, [_]i8{ -1, 1 }, [_]i8{ 0, -1 }, [_]i8{ 0, 1 }, [_]i8{ 1, -1 }, [_]i8{ 1, 0 }, [_]i8{ 1, 1 } };
    for (vecs) |direction| {
        var x: i32 = @intCast(i32, col) + @intCast(i32, direction[0]);
        var y: i32 = @intCast(i32, row) + @intCast(i32, direction[1]);
        while ((x >= 0) and (x < COLS) and (y >= 0) and (y < ROWS)) {
            if (board[@intCast(usize, y)][@intCast(usize, x)] == .occupied) {
                result += 1;
                break;
            } else {
                if (board[@intCast(usize, y)][@intCast(usize, x)] == .empty) {
                    break;
                }
            }
            x = @intCast(i32, x) + @intCast(i32, direction[0]);
            y = @intCast(i32, y) + @intCast(i32, direction[1]);
        }
    }
    return result;
}

pub fn nextStep1(last: Board) Board {
    var next: Board = undefined;
    for (last) |row, i| {
        for (row) |lastItem, j| {
            next[i][j] = lastItem;
            if ((lastItem == .empty) and (adjOccupied(i, j, last) == 0))
                next[i][j] = .occupied;
            if ((lastItem == .occupied) and (adjOccupied(i, j, last) >= 4))
                next[i][j] = .empty;
        }
    }
    return next;
}

pub fn nextStep2(last: Board) Board {
    var next: Board = undefined;
    for (last) |row, i| {
        for (row) |lastItem, j| {
            next[i][j] = lastItem;
            if ((lastItem == .empty) and (visibleOccupied(i, j, last) == 0))
                next[i][j] = .occupied;
            if ((lastItem == .occupied) and (visibleOccupied(i, j, last) >= 5))
                next[i][j] = .empty;
        }
    }
    return next;
}
pub fn printBoard(board: Board) void {
    for (board) |row, i| {
        std.debug.print("|", .{});
        for (row) |_, j| {
            std.debug.print("{c} ", .{spot2char(board[i][j])});
        }
        std.debug.print("|\n", .{});
    }
}

pub fn numOccupied(board: Board) u32 {
    var result: u32 = 0;
    for (board) |row, i| {
        for (row) |s, j| {
            if (s == .occupied) {
                result += 1;
            }
        }
    }
    return result;
}

pub fn boardEql(a: Board, b: Board) bool {
    for (a) |row, i| {
        for (row) |lastItem, j| {
            if (b[i][j] != lastItem) return false;
        }
    }
    return true;
}

pub fn iterate(original: Board, nextfn: fn (b: Board) Board) Board {
    var lastBoard: Board = std.mem.zeroes(Board);
    var curBoard: Board = original;
    while (!boardEql(curBoard, lastBoard)) {
        lastBoard = curBoard;
        curBoard = nextfn(curBoard);
    }
    return curBoard;
}

pub fn main() anyerror!void {
    const original: Board = parseInput(input, std.heap.page_allocator);

    var part1: u32 = numOccupied(iterate(original, nextStep1));
    var part2: u32 = numOccupied(iterate(original, nextStep2));

    std.log.info("Part1: {}", .{part1});
    std.log.info("Part2: {}", .{part2});
}
