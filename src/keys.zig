const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const log = std.log.scoped(.keys);
const Dirs = @import("core").Dirs;
const Allocator = std.mem.Allocator;
const crypto = std.crypto;
const Atomic = std.atomic.Atomic;
const Ed25519 = crypto.sign.Ed25519;
const Blake3 = crypto.hash.Blake3;
const KeyPair = Ed25519.KeyPair;
const str = []const u8;

pub const Tag = enum { nop, add, del };

pub const Keys = @This();

pair: KeyPair,

pub fn file(a: Allocator) !?std.fs.File {
    const hdir = try Dirs.getPath(Dirs.home, a) catch "~/";
    const idir = std.fs.path.join(a, .{hdir, ".idla"});
    const id = try std.fs.openDirAbsolute(idir, .{});
    const kfile = try id.openFile(".keys", .{});
    if (kfile) |f| return f;
    return null;
}
pub fn initFromFile(a: Allocator) !?Keys {
    const hdir = try Dirs.getPath(Dirs.home, a) catch "~/";
    const idir = std.fs.path.join(a, .{hdir, ".idla"});
    const id = try std.fs.openDirAbsolute(idir, .{});
    const kfile = try id.openFile(".keys", .{});
    const kstr = try kfile.readToEndAlloc(a, 512);
    const kp = try std.json.Parser.init(a, true).parse(kstr);
    var pvk: [Ed25519.secret_length]u8 = undefined;
    pvk = kp.root.Object.get("privatekey") orelse null;
    if (pvk == null) { return null; }
    else return try Ed25519.KeyPair.fromSecretKey(&pvk);
    return null;
}

pub fn init(seed: ?[Ed25519.seed_length]u8) !Keys {
    return Keys { .pair = try KeyPair.create(seed) };
}

pub fn toStr(self: Keys, a: Allocator) !str {
    const pkey = self.pair.public_key;
    const priv = self.pair.secret_key[0..Ed25519.secret_length];
    const cmb = try std.mem.join(a, "\n", [_][]u8{ pkey, priv });
    return cmb;
}
pub fn toFile(self: Keys, a: Allocator, ) !void {
    if (try Keys.file(a)) |f| {
        try f.writer().writeAll(try self.toStr());
    }
}
pub fn printPair(self: Keys) void {
    const fmtHex = std.fmt.fmtSliceHexLower;
    print("\n\x1b[32;1mpubkey\x1b[0m: {}\n", .{fmtHex(&self.pair.public_key)});
    print("\x1b[34;1mseckey\x1b[0m: {}\n", .{fmtHex(self.pair.secret_key[0..Ed25519.secret_length])});
}

pub fn sign(keys: Keys, msg: str) ![64]u8 {
    return Ed25519.sign(msg, keys.pair, null);
}

/// Local record of modification
pub const Entry = struct {
    id: [32]u8 = undefined,
    len: u32 = 0,
    signature: [64]u8 = undefined,
    tag: Tag = Tag.nop,
    sender_id: [32]u8,
    sender_nonce: u64 = 0,
    data: [*]u8 = @ptrCast([*]u8, ""),
    created: i64 = std.time.timestamp(),

    pub fn hash(self: *Entry) ![32]u8 {
        var b: [32]u8 = undefined;
        var hasher = Blake3.init(.{});
        try self.write(hasher.writer());
        hasher.final(&b);
        return b;
    }

    pub fn initMsg(a: Allocator, data: []const u8, keys: Keys) !*Entry {
        return Entry.init(a, 0, data, keys, Tag.nop);
    }
    pub fn init(a: Allocator, nonce: u64, data: []const u8, keys: Keys, tag: Tag) !*Entry{
        const byt = try a.alignedAlloc(u8, std.math.max(@alignOf(Entry), @alignOf(u8)), @sizeOf(Entry) + data.len);
        errdefer a.free(byt);
        var entry = @ptrCast(*Entry, byt.ptr);
        std.mem.copy(u8, entry.data[0..data.len], data);
        entry.len = @intCast(u32, data.len);
        entry.tag = tag;
        entry.sender_id = keys.pair.public_key;
        entry.sender_nonce = nonce;
        entry.signature = try keys.sign(data);
        entry.id = try entry.hash();
        return entry;
    }

    pub fn write(self: Entry, w: anytype) !void {
        try w.writeAll(&self.sender_id);
        try w.writeAll(&self.signature);
        try w.writeIntLittle(u32, self.len);
        try w.writeIntLittle(u64, self.sender_nonce);
        try w.writeIntLittle(u64, @intCast(u64, self.created));
        try w.writeIntLittle(u8, @enumToInt(self.tag));
        try w.writeAll(self.data[0..self.len]);
    }

    pub fn read(gpa: mem.Allocator, reader: anytype) !*Entry {
        var ent = try gpa.create(Entry);
        errdefer gpa.destroy(ent);
        ent.sender_id = reader.readBytesNoEof(32);
        ent.signature = reader.readBytesNoEof(64);
        ent.len = reader.readIntLittle(u32);
        if (ent.len > 65536) return error.DataTooLarge;

        ent = @ptrCast(*Entry, try gpa.realloc(std.mem.span(std.mem.asBytes(ent)), @sizeOf(Entry) + ent.len));
        ent.sender_nonce = try reader.readIntLittle(u64);
        ent.created = try reader.readIntLittle(u64);
        ent.tag = try reader.readEnum(Entry.Tag, .Little);
        ent.data = @ptrCast([*]u8, ent.data.ptr) + @sizeOf(Entry);

        try reader.readNoEof(ent.data[0..ent.len]);
        ent.id = try Entry.hash(&ent);
        return ent;
    }
};
