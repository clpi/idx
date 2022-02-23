const std = @import("std");
const ArenaAllocator = std.heap.ArenaAllocator;
const mem = std.mem;
const str = []const u8;

pub const Edged = union(enum) {};

pub fn HGraph(comptime N: Node, comptime E: Edge) type {
    const HEdge = struct {};
    const HNode = struct {
        id: usize,
        incoming: ?*HEdge,
        outgoing: ?*HEdge,
    };
    const HGraph = struct {
        nodes: std.ArrayList(?*HNode),
    };
    return HGraph;
}

pub fn main() void {
    std.debug.print("Inside", .{});
}
