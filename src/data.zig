const std = @import("std");
// const Graph = @import("./data/graph.zig").Graph;
// const Tree = @import("./data/tree.zig").Tree;
// const Table = @import("./data/table.zig");
const os = std.os;
const Allocator = std.mem.Allocator;

pub const Db = struct {
    arena: std.heap.ArenaAllocator,
    fd: os.fd_t,

    pub const PG_LEN: u64 = 4096;
};

