const std = @import("std");
const hash_map = std.hash_map;
const math = std.math;
const testing = std.testing;
const Allocator = std.mem.Allocator;

pub const GraphError = error{
    VertexNotFoundError,
};

/// A directed graph that contains nodes of a given type.
///
/// The Context is the same as the Context for std.hash_map and must
/// provide for a hash function and equality function. This is used to
/// determine graph node equality.
pub fn DirectedGraph(
    comptime T: type,
    comptime Context: type,
) type {
    // This verifies the context has the correct functions (hash and eql)
    comptime hash_map.verifyContext(Context, T, T, u64);

    // The adjacency list type is used to map all edges in the graph.
    // The key is the source node. The value is a map where the key is
    // target node and the value is the edge weight.
    const AdjMapValue = hash_map.AutoHashMap(u64, u64);
    const AdjMap = hash_map.AutoHashMap(u64, AdjMapValue);

    // ValueMap maps hash codes to the actual value.
    const ValueMap = hash_map.AutoHashMap(u64, T);

    return struct {
        // allocator to use for all operations
        allocator: Allocator,

        // ctx is the context implementation
        ctx: Context,

        // adjacency lists for outbound and inbound edges and a map to
        // get the real value.
        adjOut: AdjMap,
        adjIn: AdjMap,
        values: ValueMap,

        const Self = @This();

        /// Size is the maximum size (as a type) that the graph can hold.
        /// This is currently dictated by our usage of HashMap underneath.
        const Size = AdjMap.Size;

        /// initialize a new directed graph. This is used if the Context type
        /// has no data (zero-sized).
        pub fn init(allocator: Allocator) Self {
            if (@sizeOf(Context) != 0) {
                @compileError("Context is non-zero sized. Use initContext instead.");
            }

            return initContext(allocator, undefined);
        }

        /// same as init but for non-zero-sized contexts.
        pub fn initContext(allocator: Allocator, ctx: Context) Self {
            return .{
                .allocator = allocator,
                .ctx = ctx,
                .adjOut = AdjMap.init(allocator),
                .adjIn = AdjMap.init(allocator),
                .values = ValueMap.init(allocator),
            };
        }
        /// deinitialize all the memory associated with the graph. If you
        /// deinitialize the allocator used with this graph you don't need to
        /// call this.
        pub fn deinit(self: *Self) void {
            // Free values for our adj maps
            var it = self.adjOut.iterator();
            while (it.next()) |kv| {
                kv.value_ptr.deinit();
            }
            it = self.adjIn.iterator();
            while (it.next()) |kv| {
                kv.value_ptr.deinit();
            }

            self.adjOut.deinit();
            self.adjIn.deinit();
            self.values.deinit();
            self.* = undefined;
        }

        /// Add a node to the graph.
        pub fn add(self: *Self, v: T) !void {
            const h = self.ctx.hash(v);
            // If we already have this node, then do nothing.
            if (self.adjOut.contains(h)) return;
            try self.adjOut.put(h, AdjMapValue.init(self.allocator));
            try self.adjIn.put(h, AdjMapValue.init(self.allocator));
            try self.values.put(h, v);
        }

        /// Remove a node and all edges to and from the node.
        pub fn remove(self: *Self, v: T) void {
            const h = self.ctx.hash(v);

            // Forget this value
            _ = self.values.remove(h);

            // Delete in-edges for this vertex.
            if (self.adjOut.getPtr(h)) |map| {
                var it = map.iterator();
                while (it.next()) |kv| {
                    if (self.adjIn.getPtr(kv.key_ptr.*)) |inMap| {
                        _ = inMap.remove(h);
                    }
                }

                map.deinit();
                _ = self.adjOut.remove(h);
            }

            // Delete out-edges for this vertex
            if (self.adjIn.getPtr(h)) |map| {
                var it = map.iterator();
                while (it.next()) |kv| {
                    if (self.adjOut.getPtr(kv.key_ptr.*)) |inMap| {
                        _ = inMap.remove(h);
                    }
                }

                map.deinit();
                _ = self.adjIn.remove(h);
            }
        }

        /// contains returns true if the graph has the given vertex.
        pub fn contains(self: *Self, v: T) bool {
            return self.values.contains(self.ctx.hash(v));
        }

        /// lookup looks up a vertex by hash. The hash is often used
        /// as a result of algorithms such as strongly connected components
        /// since it is easier to work with. This function can be called to
        /// get the real value.
        pub fn lookup(self: *Self, hash: u64) ?T {
            return self.values.get(hash);
        }

        /// add an edge from one node to another. This will return an
        /// error if either vertex does not exist.
        pub fn addEdge(self: *Self, from: T, to: T, weight: u64) !void {
            const h1 = self.ctx.hash(from);
            const h2 = self.ctx.hash(to);

            const mapOut = self.adjOut.getPtr(h1) orelse
                return GraphError.VertexNotFoundError;
            const mapIn = self.adjIn.getPtr(h2) orelse
                return GraphError.VertexNotFoundError;

            try mapOut.put(h2, weight);
            try mapIn.put(h1, weight);
        }

        /// remove an edge
        pub fn removeEdge(self: *Self, from: T, to: T) void {
            const h1 = self.ctx.hash(from);
            const h2 = self.ctx.hash(to);

            if (self.adjOut.getPtr(h1)) |map| {
                _ = map.remove(h2);
            } else unreachable;

            if (self.adjIn.getPtr(h2)) |map| {
                _ = map.remove(h1);
            } else unreachable;
        }

        /// getEdge gets the edge from one node to another and returns the
        /// weight, if it exists.
        pub fn getEdge(self: *const Self, from: T, to: T) ?u64 {
            const h1 = self.ctx.hash(from);
            const h2 = self.ctx.hash(to);

            if (self.adjOut.getPtr(h1)) |map| {
                return map.get(h2);
            } else unreachable;
        }

        // reverse reverses the graph. This does NOT make any copies, so
        // any changes to the original affect the reverse and vice versa.
        // Likewise, only one of these graphs should be deinitialized.
        pub fn reverse(self: *const Self) Self {
            return Self{
                .allocator = self.allocator,
                .ctx = self.ctx,
                .adjOut = self.adjIn,
                .adjIn = self.adjOut,
                .values = self.values,
            };
        }

        /// Create a copy of this graph using the same allocator.
        pub fn clone(self: *const Self) !Self {
            return Self{
                .allocator = self.allocator,
                .ctx = self.ctx,
                .adjOut = try cloneAdjMap(&self.adjOut),
                .adjIn = try cloneAdjMap(&self.adjIn),
                .values = try self.values.clone(),
            };
        }

        /// clone our AdjMap including inner values.
        fn cloneAdjMap(m: *const AdjMap) !AdjMap {
            // Clone the outer container
            var new = try m.clone();

            // Clone all objects
            var it = new.iterator();
            while (it.next()) |kv| {
                try new.put(kv.key_ptr.*, try kv.value_ptr.clone());
            }

            return new;
        }

        /// The number of vertices in the graph.
        pub fn countVertices(self: *const Self) Size {
            return self.values.count();
        }

        /// The number of edges in the graph.
        ///
        /// O(V) where V is the # of vertices. We could cache this if we
        /// wanted but its not a very common operation.
        pub fn countEdges(self: *const Self) Size {
            var count: Size = 0;
            var it = self.adjOut.iterator();
            while (it.next()) |kv| {
                count += kv.value_ptr.count();
            }

            return count;
        }

        /// Cycles returns the set of cycles (if any).
        pub fn cycles(
            self: *const Self,
        ) ?StronglyConnectedComponents {
            var sccs = self.connectedComponents();
            var i: usize = 0;
            while (i < sccs.list.items.len) {
                const current = sccs.list.items[i];
                if (current.items.len <= 1) {
                    const old = sccs.list.swapRemove(i);
                    old.deinit();
                    continue;
                }

                i += 1;
            }

            if (sccs.list.items.len == 0) {
                sccs.deinit();
                return null;
            }

            return sccs;
        }

        /// Returns the set of strongly connected components in this graph.
        /// This allocates memory.
        pub fn connectedComponents(
            self: *const Self,
        ) StronglyConnectedComponents {
            return stronglyConnectedComponents(self.allocator, self);
        }

        /// dfsIterator returns an iterator that iterates all reachable
        /// vertices from "start". Note that the DFSIterator must have
        /// deinit called. It is an error if start does not exist.
        pub fn dfsIterator(self: *const Self, start: T) !DFSIterator {
            const h = self.ctx.hash(start);

            // Start must exist
            if (!self.values.contains(h)) {
                return GraphError.VertexNotFoundError;
            }

            // We could pre-allocate some space here and assume we'll visit
            // the full graph or something. Keeping it simple for now.
            var stack = std.ArrayList(u64).init(self.allocator);
            var visited = std.AutoHashMap(u64, void).init(self.allocator);

            return DFSIterator{
                .g = self,
                .stack = stack,
                .visited = visited,
                .current = h,
            };
        }

        pub const DFSIterator = struct {
            // Not the most efficient data structures for this, I know,
            // but we can come back and optimize this later since its opaque.
            //
            // stack and visited must ensure capacity
            g: *const Self,
            stack: std.ArrayList(u64),
            visited: std.AutoHashMap(u64, void),
            current: ?u64,

            // DFSIterator must deinit
            pub fn deinit(it: *DFSIterator) void {
                it.stack.deinit();
                it.visited.deinit();
            }

            /// next returns the list of hash IDs for the vertex. This should be
            /// looked up again with the graph to get the actual vertex value.
            pub fn next(it: *DFSIterator) !?u64 {
                // If we're out of values, then we're done.
                if (it.current == null) return null;

                // Our result is our current value
                const result = it.current orelse unreachable;
                try it.visited.put(result, {});

                // Add all adjacent edges to the stack. We do a
                // visited check here to avoid revisiting vertices
                if (it.g.adjOut.getPtr(result)) |map| {
                    var iter = map.keyIterator();
                    while (iter.next()) |target| {
                        if (!it.visited.contains(target.*)) {
                            try it.stack.append(target.*);
                        }
                    }
                }

                // Advance to the next value
                it.current = null;
                while (it.stack.popOrNull()) |nextVal| {
                    if (!it.visited.contains(nextVal)) {
                        it.current = nextVal;
                        break;
                    }
                }

                return result;
            }
        };
    };
}

test "add and remove vertex" {
    const gtype = DirectedGraph([]const u8, std.hash_map.StringContext);
    var g = gtype.init(testing.allocator);
    defer g.deinit();

    // No vertex
    try testing.expect(!g.contains("A"));

    // Add some nodes
    try g.add("A");
    try g.add("A");
    try g.add("B");
    try testing.expect(g.contains("A"));
    try testing.expect(g.countVertices() == 2);
    try testing.expect(g.countEdges() == 0);

    // add an edge
    try g.addEdge("A", "B", 1);
    try testing.expect(g.countEdges() == 1);

    // Remove a node
    g.remove("A");
    try testing.expect(g.countVertices() == 1);

    // important: removing a node should remove the edge
    try testing.expect(g.countEdges() == 0);
}

test "add and remove edge" {
    const gtype = DirectedGraph([]const u8, std.hash_map.StringContext);
    var g = gtype.init(testing.allocator);
    defer g.deinit();

    // Add some nodes
    try g.add("A");
    try g.add("A");
    try g.add("B");

    // add an edge
    try g.addEdge("A", "B", 1);
    try g.addEdge("A", "B", 4);
    try testing.expect(g.countEdges() == 1);
    try testing.expect(g.getEdge("A", "B").? == 4);

    // Remove the node
    g.removeEdge("A", "B");
    g.removeEdge("A", "B");
    try testing.expect(g.countEdges() == 0);
    try testing.expect(g.countVertices() == 2);
}

test "reverse" {
    const gtype = DirectedGraph([]const u8, std.hash_map.StringContext);
    var g = gtype.init(testing.allocator);
    defer g.deinit();

    // Add some nodes
    try g.add("A");
    try g.add("B");
    try g.addEdge("A", "B", 1);

    // Reverse
    const rev = g.reverse();

    // Should have the same number
    try testing.expect(rev.countEdges() == 1);
    try testing.expect(rev.countVertices() == 2);
    try testing.expect(rev.getEdge("A", "B") == null);
    try testing.expect(rev.getEdge("B", "A").? == 1);
}

test "clone" {
    const gtype = DirectedGraph([]const u8, std.hash_map.StringContext);
    var g = gtype.init(testing.allocator);
    defer g.deinit();

    // Add some nodes
    try g.add("A");

    // Clone
    var g2 = try g.clone();
    defer g2.deinit();

    try g.add("B");
    try testing.expect(g.contains("B"));
    try testing.expect(!g2.contains("B"));
}

test "cycles and strongly connected components" {
    const gtype = DirectedGraph([]const u8, std.hash_map.StringContext);
    var g = gtype.init(testing.allocator);
    defer g.deinit();

    // Add some nodes
    try g.add("A");
    var alone = g.connectedComponents();
    defer alone.deinit();
    const value = g.lookup(alone.list.items[0].items[0]);
    try testing.expectEqual(value.?, "A");

    // Add more
    try g.add("B");
    try g.addEdge("A", "B", 1);
    var sccs = g.connectedComponents();
    defer sccs.deinit();
    try testing.expect(sccs.count() == 2);
    try testing.expect(g.cycles() == null);

    // Add a cycle
    try g.addEdge("B", "A", 1);
    var sccs2 = g.connectedComponents();
    defer sccs2.deinit();
    try testing.expect(sccs2.count() == 1);

    // Should have a cycle
    var cycles = g.cycles() orelse unreachable;
    defer cycles.deinit();
    try testing.expect(cycles.count() == 1);
}

test "dfs" {
    const gtype = DirectedGraph([]const u8, std.hash_map.StringContext);
    var g = gtype.init(testing.allocator);
    defer g.deinit();

    // Add some nodes
    try g.add("A");
    try g.add("B");
    try g.add("C");
    try g.addEdge("B", "C", 1);
    try g.addEdge("C", "A", 1);

    // DFS from A should only reach A
    {
        var list = std.ArrayList([]const u8).init(testing.allocator);
        defer list.deinit();
        var iter = try g.dfsIterator("A");
        defer iter.deinit();
        while (try iter.next()) |value| {
            try list.append(g.lookup(value).?);
        }

        const expect = [_][]const u8{"A"};
        try testing.expectEqualSlices([]const u8, list.items, &expect);
    }

    // DFS from B
    {
        var list = std.ArrayList([]const u8).init(testing.allocator);
        defer list.deinit();
        var iter = try g.dfsIterator("B");
        defer iter.deinit();
        while (try iter.next()) |value| {
            try list.append(g.lookup(value).?);
        }

        const expect = [_][]const u8{ "B", "C", "A" };
        try testing.expectEqualSlices([]const u8, &expect, list.items);
    }
}



/// A list of strongly connected components.
///
/// This is effectively [][]u64 for a DirectedGraph. The u64 value is the
/// hash code, NOT the type T. You should use the lookup function to get the
/// actual vertex.
pub const StronglyConnectedComponents = struct {
    const Self = @This();
    const Entry = std.ArrayList(u64);
    const List = std.ArrayList(Entry);

    /// The list of components. Do not access this directly. This type
    /// also owns all the items, so when deinit is called, all items in this
    /// list will also be deinit-ed.
    list: List,

    /// Iterator is used to iterate through the strongly connected components.
    pub const Iterator = struct {
        list: *const List,
        index: usize = 0,

        /// next returns the list of hash IDs for the vertex. This should be
        /// looked up again with the graph to get the actual vertex value.
        pub fn next(it: *Iterator) ?[]u64 {
            // If we're empty or at the end, we're done.
            if (it.list.items.len == 0 or it.list.items.len <= it.index) return null;

            // Bump the index, return our value
            defer it.index += 1;
            return it.list.items[it.index].items;
        }
    };

    pub fn init(allocator: Allocator) Self {
        return Self{
            .list = List.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.list.items) |v| {
            v.deinit();
        }
        self.list.deinit();
    }

    /// Iterate over all the strongly connected components
    pub fn iterator(self: *const Self) Iterator {
        return .{ .list = &self.list };
    }

    /// The number of distinct strongly connected components.
    pub fn count(self: *const Self) usize {
        return self.list.items.len;
    }
};

/// Calculate the set of strongly connected components in the graph g.
/// The argument g must be a DirectedGraph type.
pub fn stronglyConnectedComponents(
    allocator: Allocator,
    g: anytype,
) StronglyConnectedComponents {
    var acc = sccAcc.init(allocator);
    defer acc.deinit();
    var result = StronglyConnectedComponents.init(allocator);

    var iter = g.values.keyIterator();
    while (iter.next()) |h| {
        if (!acc.map.contains(h.*)) {
            _ = stronglyConnectedStep(allocator, g, &acc, &result, h.*);
        }
    }

    return result;
}

fn stronglyConnectedStep(
    allocator: Allocator,
    g: anytype,
    acc: *sccAcc,
    result: *StronglyConnectedComponents,
    current: u64,
) u32 {
    // TODO(mitchellh): I don't like this unreachable here.
    const idx = acc.visit(current) catch unreachable;
    var minIdx = idx;

    var iter = g.adjOut.getPtr(current).?.keyIterator();
    while (iter.next()) |targetPtr| {
        const target = targetPtr.*;
        const targetIdx = acc.map.get(target) orelse 0;

        if (targetIdx == 0) {
            minIdx = math.min(
                minIdx,
                stronglyConnectedStep(allocator, g, acc, result, target),
            );
        } else if (acc.inStack(target)) {
            minIdx = math.min(minIdx, targetIdx);
        }
    }

    // If this is the vertex we started with then build our result.
    if (idx == minIdx) {
        var scc = std.ArrayList(u64).init(allocator);
        while (true) {
            const v = acc.pop();
            scc.append(v) catch unreachable;
            if (v == current) {
                break;
            }
        }

        result.list.append(scc) catch unreachable;
    }

    return minIdx;
}

/// Internal accumulator used to calculate the strongly connected
/// components. This should not be used publicly.
pub const sccAcc = struct {
    const MapType = std.hash_map.AutoHashMap(u64, Size);
    const StackType = std.ArrayList(u64);

    next: Size,
    map: MapType,
    stack: StackType,

    // Size is the maximum number of vertices that could exist. Our graph
    // is limited to 32 bit numbers due to the underlying usage of HashMap.
    const Size = u32;

    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return Self{
            .next = 1,
            .map = MapType.init(allocator),
            .stack = StackType.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.map.deinit();
        self.stack.deinit();
        self.* = undefined;
    }

    pub fn visit(self: *Self, v: u64) !Size {
        const idx = self.next;
        try self.map.put(v, idx);
        self.next += 1;
        try self.stack.append(v);
        return idx;
    }

    pub fn pop(self: *Self) u64 {
        return self.stack.pop();
    }

    pub fn inStack(self: *Self, v: u64) bool {
        for (self.stack.items) |i| {
            if (i == v) {
                return true;
            }
        }

        return false;
    }
};

test "sccAcc" {
    var acc = sccAcc.init(testing.allocator);
    defer acc.deinit();

    // should start at nothing
    try testing.expect(acc.next == 1);
    try testing.expect(!acc.inStack(42));

    // add vertex
    try testing.expect((try acc.visit(42)) == 1);
    try testing.expect(acc.next == 2);
    try testing.expect(acc.inStack(42));

    const v = acc.pop();
    try testing.expect(v == 42);
}

test "StronglyConnectedComponents" {
    var sccs = StronglyConnectedComponents.init(testing.allocator);
    defer sccs.deinit();

    // Initially empty
    try testing.expect(sccs.count() == 0);

    // Build our entries
    var entries = StronglyConnectedComponents.Entry.init(testing.allocator);
    try entries.append(1);
    try entries.append(2);
    try entries.append(3);
    try sccs.list.append(entries);

    // Should have one
    try testing.expect(sccs.count() == 1);

    // Test iteration
    var iter = sccs.iterator();
    var count: u8 = 0;
    while (iter.next()) |set| {
        const expect = [_]u64{ 1, 2, 3 };
        try testing.expectEqual(set.len, 3);
        try testing.expectEqualSlices(u64, set, &expect);
        count += 1;
    }
    try testing.expect(count == 1);
}

