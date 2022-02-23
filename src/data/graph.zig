const std = @import("std");
const str = []const u8;
const event = std.event;
const Thread = std.Thread;
const Blake3 = std.crypto.hash.Blake3;
const atomic = std.atomic;
var Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;

/// A graph with directed edges and weighted vertices and edges
pub fn Graph(comptime N: Node, comptime E: Edge) type {

    const Node = struct {
        const Self = @This();
        weight: *N,
        src: ?*Node,
        dest: ?*Node,
        next: ?*Edge,
        prev: ?*Edge,

        pub const Dir = enum(u1) { in, out };

        pub fn init(weight: N) Self {
            return Node{
                .weight = weight,
                .incoming = null,
                .outgoing = null,
            };
        }

        pub fn add(weight: N, from: *Node, to: *Node) *Self{
            var n = Node.init(weight);
            n.src = from;
            n.to = to;
        }
    };

    const Edge = struct {
        const Self = @This();
        weight: *E,
        incoming: ?*Edge,
        outgoing: ?*Edge,
        
        pub const Dir = enum(u1) { left, right};

        pub fn init(weight: E, src: ?*Node, dest: ?*Node) Self {
            if (src) |s| if (s.outgoing) |*o| 
                o.*.next = &n;
            return Edge{
                .weight = weight,
                .src = src,
                .dest = dest,
                .next = null,
            };
        }

        pub fn pushLeft(self: *Edge, next: *Edge) void {
            if (!self.incoming) {

            }
            if ( self.incoming) |*in| {
                self.*.incoming = &next;
                next.*.outgoing = &self;

            }
            if (self.outgoing) |*out| {

                
            }

        }

        pub fn push(self: *Edge, edge: *Edge, dir: @This().Dir) void {]
            switch (Switch.dir) {
                .in => Edge.pushLeft
            }
        }
    };

    const Graph =  struct {
        nodes: [*]Node(N, E),
        node_co: usize,
        edge_co: usize,
    };

    return struct {
        const Self = @This();
        nodes: []Node(N, E),
        edges: [*]Edge(N, E),
    };
}

pub const Directed = enum(u1) {
    directed = 1,
    undirected = 0,
};

pub const Weighted = enum(u1) {
    weighted = 1,
    unweighted  = 0,
};

pub const GraphType = packed struct {
    const Self = @This();

    weighted: Weighted = Weighted.weighted,
    directed: Directed = Directed.directed,

    pub fn init(directed: bool, unweighted: bool) type {
        return GraphType{.directed = false, .weighted = false};
    }
    pub fn default() type {}

    pub fn dirWeight() type {
        return GraphType{};
    }

    pub fn dirUnweighted() GraphType {
        return GraphType{.weighted = Weighted.unweighted};
    }

    pub fn undirectedDirected() GraphType {
        return GraphType{.directed  = Directed.undirected};
    }

    pub fn undirectedUnweighted() GraphType {
        return GraphType{.directed = Directed.undirected, .weighted = Weighted.unweighted};
    }
};


test "GraphType works as intended" {

}

