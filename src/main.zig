const str = []const u8;
const std = @import("std");
const zig = std.zig.Ast;
const lang = @import("idla");
const pkg = @import("idpkg");
const core = @import("core");
const data = @import("./data.zig");
const Graph = core.Graph;
const Tree = core.Tree;
const Dirs = core.Dirs;
const Cli = @import("./util/cli.zig");
const Keys = @import("./keys.zig");
var Gpa = std.heap.GeneralPurposeAllocator(.{}){};
const Arena = std.heap.ArenaAllocator;
// const A = std.atomic.o

pub fn main() anyerror!void {
    const gpa = Gpa.allocator();
    const keys = try Keys.init(null);
    var args: [][:0]u8 = try std.process.argsAlloc(gpa);

    defer std.process.argsFree(gpa, args);

    var clio = try Cli.init(gpa, &Cli.user_opts, args);
    clio.printOpts();
    keys.printPair();

    const msg = "hello world";
    const signed = try keys.sign(msg);
    var sfmt = std.fmt.fmtSliceHexLower(&signed);
    std.debug.print("msg: {s} \nsigned msg: {s}", .{ msg, sfmt });
}
