const std = @import("std");
const input = @embedFile("input");

pub fn Point(comptime Dim: usize) type {
    return [Dim]i32;
}

pub fn Space(comptime Dim: usize) type {
    return struct {
        points: *std.AutoHashMap(Point(Dim), void) = undefined,
        minPoint: Point(Dim) = [_]i32{0} ** Dim,
        maxPoint: Point(Dim) = [_]i32{0} ** Dim,
        allocator: *std.mem.Allocator = undefined,

        const Self = @This();
        pub fn init(initial: ?[]const u8, allocator: *std.mem.Allocator) !*Self {
            var space: *Self = try allocator.create(Self);
            space.* = Self{};
            space.points = try allocator.create(std.AutoHashMap(Point(Dim), void));
            space.points.* = std.AutoHashMap(Point(Dim), void).init(allocator);
            space.allocator = allocator;
            if (initial) |inp| {
                var lines = std.mem.split(inp, "\n");
                var rowNum: u32 = 0;
                var maxCols: u32 = 0;
                while (lines.next()) |line| : (rowNum += 1) {
                    for (line) |ch, colNum| {
                        maxCols = std.math.max(maxCols, @intCast(u32, colNum));
                        if ('#' == ch) {
                            var p: Point(Dim) = [_]i32{0} ** Dim;
                            p[0] = @intCast(i32, colNum);
                            p[1] = @intCast(i32, rowNum);
                            try space.points.put(p, {});
                        }
                    }
                }
                space.maxPoint[0] = @intCast(i32, maxCols);
                space.maxPoint[1] = @intCast(i32, rowNum) - 2;
            }
            return space;
        }

        pub fn deinit(space: *Self) void {
            space.points.deinit();
        }

        pub fn neighbors(space: Self, p: Point(Dim)) u32 {
            var ns: u32 = 0;
            const of = [3]i32{ -1, 0, 1 };
            var dimOffs = [_]i32{0} ** Dim;
            var OffState = [_]usize{0} ** Dim;
            var i: usize = 0;
            while (OffState[0] < 3) {
                var allzeros = true;
                for (dimOffs) |*dimOff, x| {
                    if (of[OffState[x]] != 0)
                        allzeros = false;
                    dimOff.* = of[OffState[x]];
                }
                if (!allzeros) {
                    var newp: Point(Dim) = [_]i32{0} ** Dim;
                    //std.debug.print("neigh: (", .{});
                    for (newp) |*newpd, x| {
                        newpd.* = p[x] + dimOffs[x];
                        //std.debug.print("{}({}), ", .{ newpd.*, dimOffs[x] });
                    }
                    //std.debug.print(")", .{});
                    if (space.points.contains(newp)) {
                        //std.debug.print(" == !", .{});
                        ns += 1;
                    }
                    //std.debug.print("\n", .{});
                }
                OffState[Dim - 1] += 1;
                i = Dim - 2;
                while (i >= 0) {
                    if (OffState[i + 1] > 2) {
                        OffState[i + 1] = 0;
                        OffState[i] += 1;
                    }
                    if (i > 0) {
                        i -= 1;
                    } else {
                        break;
                    }
                }
            }
            return ns;
        }

        pub fn next(prev: Self) !*Self {
            var nextSpace: *Self = try Self.init(null, prev.allocator);
            for (prev.minPoint) |minI, i| {
                nextSpace.minPoint[i] = minI - 1;
            }
            for (prev.maxPoint) |maxI, i| {
                nextSpace.maxPoint[i] = maxI + 1;
            }
            var newp: Point(Dim) = undefined;
            std.mem.copy(i32, &newp, &nextSpace.minPoint);
            var bit: usize = 0;
            while (newp[newp.len - 1] <= nextSpace.maxPoint[newp.len - 1]) {
                const neigh = prev.neighbors(newp);
                const active = prev.points.contains(newp);
                //std.log.debug("max: [{}][{}][{}] {} = {}", .{ newp[0], newp[1], newp[2], neigh, active });
                if (((neigh == 2) and active) or (neigh == 3)) {
                    try nextSpace.points.put(newp, {});
                }
                newp[0] += 1;
                bit = 0;
                while (bit < Dim - 1) : (bit += 1) {
                    if (newp[bit] > nextSpace.maxPoint[bit]) {
                        newp[bit] = nextSpace.minPoint[bit];
                        newp[bit + 1] += 1;
                    }
                }
            }
            return nextSpace;
        }

        pub fn print(space: Self) void {
            var i: usize = 0;
            std.debug.print("=====", .{});
            while (i < Dim) : (i += 1) {
                std.debug.print("({}-{}), ", .{ space.minPoint[i], space.maxPoint[i] });
            }
            std.debug.print("\n", .{});
            var newp: Point(Dim) = undefined;
            std.mem.copy(i32, &newp, &space.minPoint);
            var bit: usize = 0;
            while (newp[newp.len - 1] <= space.maxPoint[newp.len - 1]) {
                if ((newp[0] == space.minPoint[0]) and (newp[1] == space.minPoint[1])) {
                    std.debug.print(" -- ", .{});
                    i = 2;
                    while (i < Dim) : (i += 1) {
                        std.debug.print("[{}], ", .{newp[i]});
                    }
                    std.debug.print("\n", .{});
                }
                if (newp[0] == space.minPoint[0]) {
                    std.debug.print("| ", .{});
                }
                if (space.points.contains(newp)) {
                    std.debug.print("# ", .{});
                } else {
                    std.debug.print(". ", .{});
                }
                if (newp[0] == space.maxPoint[0]) {
                    std.debug.print("|\n", .{});
                }

                newp[0] += 1;
                bit = 0;
                while (bit < Dim - 1) : (bit += 1) {
                    if (newp[bit] > space.maxPoint[bit]) {
                        newp[bit] = space.minPoint[bit];
                        newp[bit + 1] += 1;
                    }
                }
            }
        }
    };
}

pub fn runSixTimes(comptime S: type, allocator: *std.mem.Allocator) !usize {
    var space = try S.init(input, allocator);
    var i: u8 = 0;
    while (i < 6) : (i += 1) {
        space = try space.next();
    }
    return space.points.count();
}

pub fn main() anyerror!void {
    var allocator = std.heap.page_allocator;
    std.log.info("Part 1: {}", .{try runSixTimes(Space(3), allocator)});
    std.log.info("Part 2: {}", .{try runSixTimes(Space(4), allocator)});
}
