const std = @import("std");
pub const Op = enum {
    @"and",
    @"or",
    @"not",
    @"xor",
    @"add",
    @"sub",
    @"mul",
    @"div",
    @"pow",

    pub fn has(st: []const u8) ?Op {
        if (@hasField(Op, st)) {
            return @field(Op, st);
        } else return null;
    }
};

pub const opsy = std.ComptimeStringMap(Op, .{
    .{ "&&", Op.@"and" },
    .{ "||", Op.@"or"  },
    .{ "^^", Op.@"xor" },
    .{ "!!", Op.@"not" },
    .{ "**", Op.@"pow" },
    .{ "+",  Op.@"add" },
    .{ "-",  Op.@"sub" },
    .{ "*",  Op.@"mul" },
    .{ "/",  Op.@"div" },
});
