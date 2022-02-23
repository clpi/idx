const std = @import("std");
const str = []const u8;
const Allocator = std.mem.Allocator;
const Gpa = std.heap.GeneralPurposeAllocator(.{}){};
// pub const Tree = @This();

const Tr = @This();

pub fn strTree(s: str) *BTree(str) {
    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // const gpa = arena.allocator();
    return BTree(str).init(s);
}

pub fn BTree(comptime T: type) type {
    return struct {
        const Self = @This();
        root: *BNode(T),
        // nodes: std.ArrayList(*BNode(T)),

        pub fn init(data: T) *Self {
            // var nodes = std.ArrayList(*BNode(T)).init(a);
            var root = BNode(T).init(data);
            // _ = try nodes.append(&root);
            return &Self{ .root = &root };
        }
    };

}


pub fn BNode(comptime T: type) type {
    return struct {
        const Self = @This();
        data: T,
        lhs: ?*Self = null,
        rhs: ?*Self = null,

        pub fn init(data: T) Self {
            return Self{ .data = data, };
        }

    };
}

pub const Token = struct {
    start: usize,
    end: usize,
    tag: []const u8,
};


test "Tree" {
    const t = strTree("hi there");
    std.debug.print("{s}", .{ t.root.*.data });
}
