const str = []const u8;
const std = @import("std");
const dirs = @import("./util/dirs.zig");
const Pkg = @import("./util/pkg.zig");
const Cli = @import("./util/cli.zig");

pub var Gpa = std.heap.GeneralPurposeAllocator(.{}){};
const Arena = std.heap.ArenaAllocator;

pub fn main() anyerror!void {
    const gpa = Gpa.allocator();

    var args: [][:0]u8 = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    var clir = try Cli.init(gpa, &Cli.user_opts, args);
    clir.printOpts();
    // const res  = try cf.parse(args);
         
        // std.debug.print("{s}\n", .{r});
    // const pc = try PkgConfig.read_cwd();
    // try cf.print();
    // try res.print();
}

