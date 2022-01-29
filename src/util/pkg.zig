const str = []const u8;
const std = @import("std");

pub const Pkg = struct {
    name: []const u8,
    dir: []const u8,

    pub fn read_cwd() !Pkg {
        var b: [2048]u8 = undefined;
        const cd = std.fs.cwd();
        const cf = try cd.openFile("idle.json", .{});
        return try cf.reader().readAll(&b);
    }

    pub fn cwd(comptime payl: []const u8) Pkg {
        var st = std.json.TokenStream.init(payl);
        const res = std.json.parse(Pkg, &st, .{});
        return res catch unreachable;
    }
};

