const std = @import("std");

const Ast = @import("./Ast.zig");
const Order = Ast.Node.Order;
const Parser = @import("./Parser.zig");
const Token = @import("./Token.zig");

const meta = std.meta;
const atomic = std.atomic;
const testing = std.testing;

test "basic bool ast" {
    // var st = "(F or T) and (T and F)"; // should -> false
    // Token.Lexer.tokenize(st);
    // var parser = Parser.init(std.testing.allocator, st);
    // var ast = try Parser.parse(&parser);
    // ast.print(.in);
}
