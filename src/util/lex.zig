const std = @import("std");
const str = []const u8;
const mem = std.mem;
const meta = std.meta;
const Thread = std.Thread;
const Array = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const event = std.event;
const Atomic = std.atomic.Atomic;

pub fn main() anyerror!void {
    var gpall = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpall.allocator();

    var tkl = try Token.List.init(gpa);
    std.debug.print("Got token list {}", .{tkl});
}

pub const Token = union(enum) {
    eof,
    unknown,
    colon,
    ident: str,
    val: Token.Value,

    pub const Value = union(enum) {
        str: str, 
    };

    pub const List = struct {
        allocator: Allocator,
        tokens: std.ArrayList(Token),

        pub fn init(a: Allocator) !Token.List {
            var ls = std.ArrayList(Token).init(a);
            const inp = @embedFile("../test.idla");
            var ln = std.mem.tokenize(u8, inp, "\n");
            comptime var lncount = 0;
            while (ln.next()) |lnn| : (lncount += 1) line:{
                var tk = std.mem.tokenize(u8, lnn, " ");
                comptime var wcount = 0;
                while (tk.next()) |token| : (wcount += 1) {
                    if (wcount == 0) try ls.append(Token{.ident = token});
                    if (endEq(token, ":")) try ls.append(.colon);
                    if (eq("--", token)) break:line;
                    std.debug.print("Token: {s}\n", .{ token });
                }
            }
            return Token.List{ .allocator = a, .tokens = ls};
        }

    };
};

pub fn eq(patt: str, to: str) bool {
    return std.mem.eql(u8, patt, to);
}
pub fn endEq(haystack: str, needle: str) bool {
    return std.mem.endsWith(u8, haystack, needle);
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
