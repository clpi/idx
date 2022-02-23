const std = @import("std");
const fs = std.fs;
const lang = @import("lang.zig");
const mdown = @import("mdown.zig");
const util = @import("util.zig");
const str = []const u8;
const testing = std.testing;
const process = std.process;
const Dir = std.fs.Dir;
const EntryKind = Dir.Entry.Kind;
const Thread = std.Thread;
const Walker = std.fs.Dir.Walker;
const event = std.event;
const mt = std.meta;

const asset_exts = [_]u8{ ".html", ".mdx", ".svx", ".xml", ".jpeg", ".png", ".jpg" };

pub fn main() !void {
    const al = std.heap.GeneralPurposeAllocator(.{});
    var gpa = al.allocator();

    const wwik = try WalkExt.walk(&try WalkExt.initAbs(gpa, "/Users/clp/wiki/", ".md", asset_exts));
    const mdf = if (wwik.map) |md| md else std.StringArrayHashMap(str).init(al);
    const scf = if (wwik.sec_map) |md| md else std.StringArrayHashMap(str).init(al);
    const stdo = try std.io.getStdOut();
    for (mdf.keys()) |md_path, i| {
        const val = try mdf.get(md_path) orelse continue;
        try stdo.writer().writeAll(val);
        try stdo.write("\n\x1b33m [{d}] \x1b[32;1m MARKDOWN FILE @ {s}: ", i, md_path, val);
    }
    for (scf.keys()) |sc_path, i| {
        const val = try scf.get(sc_path) orelse continue;
        try stdo.writer().writeAll(val);
        try stdo.write("\n\x1b33m [{d}] \x1b[32;1m SECONDARY FILE @ {s}: ", i, sc_path, val);
    }
}

pub fn relDir(d: str) !Dir {
    return std.fs.cwd().openDir(d, .{ .iterate = true });
}

pub fn walkRel(a: std.mem.Allocator, dir: str) !std.fs.Dir.Walker {
    return std.fs.cwd().openDir(dir, .{}).walk(a);
}

pub const WalkExt = struct {
    ext: str,
    secondary_exts: std.ArrayList(str),
    a: std.mem.Allocator,
    abs_dir: Dir = std.fs.cwd(),
    map: ?std.StringArrayHashMap(str) = null,
    sec_map: ?std.StringArrayHashMap(str) = null,
    const Self = @This();

    pub fn initAbs(a: std.mem.Allocator, dir: str, ext: str, sec_ext: ?[]str) !Self {
        var smap = std.ArrayList(str).init(a);
        if (sec_ext) |se| try smap.appendSlice(se);
        return Self{
            .ext = ext,
            .a = a,
            .abs_dir = dir,
            .secondary_exts = smap,
        };
    }

    pub fn initRel(a: std.mem.Allocator, rel_dir: str, ext: str, sec_ext: ?[]str) !Self {
        var smap = std.ArrayList(str).init(a);
        if (sec_ext) |se| try smap.appendSlice(se);
        return Self{
            .ext = ext,
            .a = a,
            .abs_dir = try std.fs.cwd().openDir(rel_dir),
            .secondary_exts = smap,
        };
    }

    fn hasExt(p1: str, p2: str) bool {
        return std.mem.endsWith(u8, p1, p2);
    }

    pub fn walk(self: *Self) !*Self {
        var wk = try self.abs_dir.walk();
        var paths = std.ArrayList(str);
        var sec_paths = std.StringArrayHashMap(str).init(self.a);
        while (try wk.next()) |ent| {
            if (ent.kind != .File) continue;
            const p = ent.path;
            if (hasExt(p, self.ext)) {
                try paths.append(p);
                continue;
            }
            for (self.secondary_exts) |se| if (hasExt(p, se)) try sec_paths.put(se, p);
        }
        self.*.map = paths;
        self.*.sec_map = sec_paths;
        return self;
    }
};
