const std = @import("std");
const Ast = @import("./Ast.zig");
const Node = Ast.Node;
const Token = @import("./Token.zig");
const Lexer = Token.Lexer;

pub const Parser = @This();

input: []const u8,
arena: std.heap.ArenaAllocator,
allocator: std.mem.Allocator,
// lexer: *Lexer,
context: Context,

pub fn init(a: std.mem.Allocator, input: []const u8) Parser {
    var arena = std.heap.ArenaAllocator.init(a);
    errdefer arena.deinit();
    return Parser{ 
        .input = input,
        .allocator = a,
        .arena = arena,
        // .lexer = Lexer{}, 
        .context = Context.init()
    };
}

pub fn parse(self: *Parser) anyerror!*Ast {
    const root = try self.toRoot();
    var ast = try self.arena.allocator().create(Ast);
    ast.* = Ast.init(self.allocator, self.arena.state, root, self.input);
    return ast;
}

pub fn toRoot(self: *Parser) anyerror!*Node {
    // for (self.input) |c| { std.debug.print("{d}", c);}
    std.debug.print("{s}", .{self.input});
    const tk = Token.start();
    var root = Ast.Node.init(tk, 0);
    return &root;
}

pub const Context = struct {
    current: Token = undefined,
    state: State,

    pub fn init() Context {
        return Context{ .state = State.begin };
    }
};

pub const State = enum {
    begin,
    end,
};

