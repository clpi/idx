const std = @import("std");

pub const Symbol = @This();
ident: ?[]const u8 = null,
tag: ?Tag = null,
val: ?Val = null,

// pub fn fromTag(comptime t: Tag) Symbol {
//     return Symbol{.ident = null, .tag = t, .val = null};
// }

pub fn fromVal(comptime v: Val) Symbol {
    return Symbol{.ident = null, .tag = @field(Tag, @tagName(v)), .val = v};
}

pub const Tag = enum {
    char, str, bool, int, float, uint,

    // pub fn has(comptime st:[]const u8) ?Tag {
    //     inline for (std.meta.fieldNames(Tag)) |field| {
    //         if (std.mem.eql(u8, field, st)) {
    //             return @field(Tag, st);
    //         }
    //     }
    //     return null;
    // }
};

pub const Val = union(Tag) {
    char: u8,
    str: []const u8,
    bool: bool,
    int: i64,
    uint: u64,
    float: f64,

    pub fn fromLit(st:[]const u8) ?Tag {
        return switch (st) {
            "T","true","True" => Val{.bool = true},
            "F","false","False" => Val{.bool = false},
            _ => null
        };
    }

    pub fn tagStr(self: Val) []const u8 {
        return @tagName(self);
    }

    pub fn valStr(self: Val) []const u8 {
        return switch (self) {
            // .char =>  |ch| &[]u8{ ch },
            .str =>   |st| st,
            .bool =>  |bl| if (bl) "true" else "false",
            else => "",
        };
    }
};


