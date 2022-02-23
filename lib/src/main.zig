const std = @import("std");
pub const dirs = @import("./dirs.zig");
pub const graph = @import("./data/graph.zig");
pub const DGraph = graph.DirectedGraph;
pub const Dirs = dirs.Dirs;
pub const Spec = dirs.Os.Spec;
const testing = std.testing;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
