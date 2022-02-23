const std = @import("std");

pub const Kwd = enum {
    @"let",
    @"def",
    @"if",
    @"else",

    pub fn has(st: []const u8) ?Kwd {
        if (@hasField(Kwd, st)) {
            return @field(Kwd, st);
        } else return null;
    }
};

