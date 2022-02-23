const std = @import("std");
const str = []const u8;
const event = std.event;
const Thread = std.Thread;
const atomic = std.atomic;
var Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;

pub fn BTree(comptime N: type) type {
    return struct {
        const Self = @This();
        data: N,
        lhs: ?*BTree(N) = null,    
        rhs: ?*BTree(N) = null,

        pub fn init(a: Allocator, data: N) Self {
            return BTree { .data = data };
        }
    };
}

pub fn Stack(comptime N: type) type {

    return struct {
        const Self = @This();
        first: *Stack.Node(N) = null, 
        last:  ?*Stack.Node(N) = null,

        pub fn init(a: Allocator, data: N) Self {
            return Stack { .data = data };
        }
        pub fn push(self: *Self, data: N) void {
            var node = Node.init(data);
            node.prev = null;
            node.next = self.first;
            if (self.first) |f| f.prev = node 
            else self.last = node;
            self.first = node;
        }

        pub const Dir = enu prev, next };
        pub const Attach

        pub const Node = struct {
            const Self = @This();
            data: N,
            prev: ?*Node(N),    
            next: ?*Node(N),
            pub fn init(data: N) Self {
                return Self{ .data = data };
            }
        };
    };
}
