const std = @import("std");

pub const Token = @This();
pub const Op = @import("./token/op.zig").Op;
pub const Kwd = @import("./token/kw.zig").Kwd;
pub const Symbol = @import("./token/sym.zig");
pub const Tag = Symbol.Tag;
pub const Val = Symbol.Val;
const Ast = @import("./Ast.zig");
const Parser = @import("./Parser.zig");

pos: usize,
ty: Token.Type = .start,

pub fn start() Token {
    return Token{ .pos = 0, .ty = Token.Type.start};
}
pub fn end() Token {
    return Token{ .pos = 0, .ty = Token.Type.end};
}

pub fn symb(pos: usize, symbl: Symbol) Token {
    return Token { .pos = pos, .ty = Token.Type{.sym = symbl}};
}
// pub fn tag(pos: usize, comptime t: Tag) Token {
//     return Token { .pos = pos, .ty = Type{.sym = Symbol.fromTag(t)}};
// }
pub fn val(pos: usize, comptime valu: Val) Token {
    return Token { .pos = pos, .ty = Type{.sym = Symbol.fromVal(valu)}};
}
pub fn op(pos: usize, opr: Op) Token {
    return Token { .pos = pos, .ty = Token.Type{.op = opr}};
}

pub fn print(token: Token) void {
    var value: []const u8 = "";
    var val_tag: []const u8 = "";
    switch (token.ty) {
        .sym => |s| if (s.val) |vl| {
            value = vl.valStr(); 
            val_tag = vl.tagStr();
        },
        else => {}
    }
    const fstr = "\x1b[32;1mToken \x1b[0m[\x1b[32mpos:\x1b[0m {d}, \x1b[33mtype:\x1b[0m {s}, \x1b[34mval:\x1b[0m ({s} = {s})]";
    const args = .{ token.pos, @tagName(token.ty), val_tag, value};
    var bf: [4096]u8 = undefined;
    var res =  std.fmt.bufPrint(&bf, fstr, args) catch "";
        // std.fmt.allocPrint(std.testing.allocator, fstr, args) catch  
    std.debug.print(fstr, args);
    std.io.getStdOut().writer().writeAll(res) catch std.debug.print("{s}", .{res});
}
pub const Type = union(enum) {
    op: Op,
    kwd: Kwd,
    sym: Symbol,
    start,
    end,
    unknown,
};


pub const Lexer = struct {
    inp: []const u8 = "",
};

pub const Loc = struct {
    row: usize, 
    col: usize,
};

pub const Span = struct {
    start: usize,
    end: usize,
};
