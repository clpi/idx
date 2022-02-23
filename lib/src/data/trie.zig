const std = @import("std");
const Allocator = std.mem.Allocator;
const Gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const Trie = @This();

root: *Node,

pub fn init(char: u8) Trie {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const gpa = arena.allocator();
    var n = &Node.init(gpa, char);
    return Trie{ .root = n };
}

pub const Node = struct {
    data: u8,
    children: std.ArrayList(*Node),

    pub fn init(a: Allocator, token: u8) Node {
        const ch = std.ArrayList(*Node).init(a);
        return Node{ .data = token, .children = ch };
    }
};

test "trie" {
    const t = Trie.init('a');
    std.debug.print("{s}", .{ t });
}
