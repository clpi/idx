const std = @import("std");
const zig = std.zig.Ast;
const mem = std.mem;
const meta = std.meta;
const Allocator = std.mem.Allocator;
const Token = @import("./Token.zig");
pub const Op = @import("./token/op.zig").Op;
pub const Kwd = @import("./token/kw.zig").Kwd;
pub const Symbol = @import("./token/sym.zig");
pub const Tag = Symbol.Tag;
pub const Val = Symbol.Val;
const Parser = @import("./Parser.zig");

pub const Ast = @This();

root: *Node = Node.init(Token.start(), 0),
input: []const u8 = "",
arena: std.heap.ArenaAllocator.State,
allocator: std.mem.Allocator,

pub fn print(self: *Ast, order: Node.Order) void {
    std.debug.print("\x1b[32;1mAST:\n\x1b[0m", .{});
    self.root.traverse(order, Token.print);
}

pub const Node = struct {
    token: Token = Token.start(),
    depth: usize = 0,
    lhs: ?*Node = null,
    rhs: ?*Node = null,

    pub const Leaf = enum { 
        lhs, rhs,
    };
    pub const Order = enum { pre, in, post };

    pub fn init(tok: Token, depth: usize) Node {
        return Node { .token = tok, .depth = depth };
    }
    pub fn initExpr(token: Token, lhs: Token, rhs: Token, depth: usize) Node {
        return Node { 
            .token = token, 
            .lhs = &Node.init(lhs, depth + 1), 
            .rhs = &Node.init(rhs, depth + 1), 
            .depth = depth
        };
    }

    pub fn add(self: *Node, leaf: Leaf, tk: Token) *Node {
        var node = Node.init(tk, self.depth + 1);
        switch (leaf) { 
            .lhs => self.*.lhs = &node,
            .rhs => self.*.rhs = &node,
        }
        return &node;
    }
    pub fn addExpr(self: *Node, leaf: Leaf, tk: Token, lhs: Token, rhs: Token) *Node {
        var op_node = Node.initExpr(tk, lhs, rhs, self.depth + 1);
        switch (leaf) {
            .lhs => self.*.lhs = &op_node,
            .rhs => self.*.rhs = &op_node,
        }
        return &op_node;
    }

    pub fn traverse(self: *Node, ord: Order, f: fn(Token) void) void {
        switch (ord) {
            Order.in => { 
                if(self.lhs) |l| l.traverse(ord, f); 
                f(self.token);
                if (self.rhs) |r| r.traverse(ord, f);
            },
            Order.post => { 
                f(self.token);
                if(self.lhs) |l| l.traverse(ord, f); 
                if (self.rhs) |r| r.traverse(ord, f);
            },
            Order.pre => { 
                if(self.lhs) |l| l.traverse(ord, f); 
                if (self.rhs) |r| r.traverse(ord, f);
                f(self.token);
            },
        }
    }

    pub fn print(self: *Node) void {
        std.debug.print("\x1b[35;1mNode: \x1b[0m", .{});
        self.token.print();
    }
};

pub const Queue = struct {
    start: *QNode,
    end: ?*QNode = null,

    pub fn init(node: *Node) Queue {
        return Queue{ .start = QNode.fromNode(node), .end = null};
    }

    pub const QNode = struct {
        curr: *Node,
        next: ?*Node = null,

        pub fn fromNode(node: *Node) QNode {
            return Queue.QNode { .curr = node, .next = null};
        }
    };
};

pub fn init(a: Allocator, arena: std.heap.ArenaAllocator.State, root: *Node, input: []const u8) Ast {
    return Ast{
        .root = root,
        .input = input,
        .arena = arena,
        .allocator = a,
    };
}


test "manual construction" {
    var al = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(al);
    var ast = Ast.init(al, arena.state, &Node.init(Token.start(), 0), "(T and T) or (T and F)");
    var orn = ast.root.add(.lhs, Token.op(8, Token.Op.@"or"));
    _ = orn.addExpr(.lhs, Token.op(4, Op.@"and"), Token.val(2,Val{.bool = true}), Token.val(6, Val{.bool = true}));
    _ = orn.addExpr(.rhs, Token.op(16, Op.@"and"), Token.val(12, Val{.bool = true}), Token.val(18, Val{.bool = false}));
    ast.print(Node.Order.in);
}
