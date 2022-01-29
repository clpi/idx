const std = @import("std");
const Allocator = std.mem.Allocator;
const str = []const u8;

pub const Cli = @This();

allocator: std.mem.Allocator = std.heap.c_allocator,
cmds: *std.BufSet,
matches: *std.BufSet,
opts: std.ArrayList(Arg) = std.ArrayList(Arg).init(std.heap.c_allocator),
args: std.ArrayList([:0]u8) = std.ArrayList([:0]u8).init(std.heap.c_allocator),

pub fn init(a: std.mem.Allocator, ops: []Arg, args: [][:0]u8) !*Cli {
    var opt = std.ArrayList(Arg).init(a);
    var as = std.ArrayList([:0]u8).init(a);
    try as.appendSlice(args);
    try opt.appendSlice(ops);
    var match = Cli.verify_matches(a, opt);
    var cmds = Cli.cmdSet(a, opt);
    var cli = Cli{ 
        .opts = opt,
        .allocator = a, 
        .args = as,
        .matches = &match, 
        .cmds = &cmds,
    };
    return Cli.parse(&cli);
}

pub fn verify_matches(a: Allocator, opts: std.ArrayList(Arg)) std.BufSet {
    var match = std.BufSet.init(a);
    for (opts.items) |opt| {
        if (match.contains(opt.short)) 
            @panic("Short key already exists!")
        else if (match.contains(opt.long)) 
            @panic("Long key already exists!")
        else {
            match.insert(opt.short) catch unreachable;
            match.insert(opt.long) catch unreachable;
        } 
    }
    return match;
}

pub fn cmdSet(a: Allocator, opts: std.ArrayList(Arg)) std.BufSet {
    var cmds = std.BufSet.init(a);
    for (opts.items) |o| 
        if (!Arg.isCmd(o)) 
            continue
        else if (cmds.contains(o.short))
            @panic("Short cmd already exists!")
        else if (cmds.contains(o.long))
            @panic("Long cmd already exists!")
        else {
            cmds.insert(o.short) catch unreachable;
            cmds.insert(o.long) catch unreachable;
        };
    return cmds; 
}

pub fn deinit(self: Cli) void {
    self.allocator.free(self.opts);
    self.matches.deinit();
}

pub fn fromArg(self: Cli, arg: Arg) void {
    switch(arg.kind) {
        .cmd => |c| if (c) { self.cmd = arg.long; },
        .opt => |v| if (v) |val| { @field(self, arg.long) = val; },
        .flag => |f| if (f) { @field(self, arg.long) = f; },
    }
}


pub fn eq(arg: str, short: str, long: str) bool {
    return (std.mem.eql(u8, arg, long) or std.mem.eql(u8, arg, short));
}

pub fn parse(self: *Cli) *Cli {
    var fl = false;
    var len = self.args.items.len;
    for (self.args.items) |arg, i| {
        if (fl) { fl = false; continue; }
        for (self.opts.items) |op, j| if (op.eq(arg)) {
            var nx: ?[:0]u8 = if (i == len - 1) null else self.args.items[i + 1];
            self.opts.items[j].pos = i;
            switch (op.kind) {
                .cmd => |_| {
                    if (i < 3) 
                        self.opts.items[j].kind = Arg.Kind{.cmd = i}
                    else
                        @panic("Command given with position > 2 -- invalid");
                },
                .flag => |_| { self.opts.items[j].kind = Arg.Kind{ .flag = true }; },
                .opt => |_| { self.opts.items[j].kind = Arg.Kind{ .opt = if (nx) |n| n else null }; fl = true; },
            }
        };
    }
    return self;
}

pub fn print(self: Cli) !void {
    try std.json.stringify(self, .{}, std.io.getStdOut().writer());

}
pub fn printCmd(self: Cli) void {
    var i: usize = 0;
    while (self.cmds.keyIterator().next()) |k| : (i += 1)  {
        std.debug.print("{d}: matches: {s} \n", .{i, k});
    }
}
pub fn printMatches(self: Cli) void {
    var i: usize = 0;
    while (self.matches.keyIterator().next()) |k| : (i += 1)  {
        std.debug.print("{d}: matches: {s} \n", .{i, k});
    }
}
pub fn printOpts(self: Cli) void {
    for (self.opts.items) |r| switch (r.kind) {
        .cmd => |c| std.debug.print("\x1b[32;1mCMD:\x1b[0m \x1b[32m{s}\x1b[0m {d}\n", .{r.long, c}),
        .opt => |o| std.debug.print("\x1b[31;1mOPT:\x1b[0m \x1b[35m{s}\x1b[0m {s}\n", .{r.long, o}),
        .flag=> |f| std.debug.print("\x1b[34;1mFLG:\x1b[0m \x1b[36m{s}\x1b[0m {s}\n", .{r.long, f}),
    };
}

pub const Arg = struct {
    short: str,
    long: str,
    pos: ?usize = null,
    kind: Kind,

    pub fn isCmd(self: Arg) bool {
        return (!std.mem.startsWith(u8, self.short, "-") and !std.mem.startsWith(u8, self.long, "--"));
    }
    pub fn isSubcmd(self: Arg) ?bool {
        if (self.isCmd()) if (self.pos) |pos| 
            if (pos == 1) return false
            else if (pos == 2) return true
            else return null; //@panic("Invalid position for cmd");
    }
    pub fn eq(self: Arg, arg: str) bool {
        return (std.mem.eql(u8, arg, self.short) or std.mem.eql(u8, arg, self.long));
    }
    const Kind = union(enum) { 
        cmd: ?usize,
        flag: bool,
        opt: ?[]const u8,

        const Cmd = struct {
            pos: ?usize = null,
            takes_sub: bool = true,
            sub: ?[]const u8,
        };
    };

    pub fn opt(comptime short: str, comptime long: str) Arg {
        return Arg{ .short = "-"++short, .long = "--"++long, .kind = Kind{.opt = null} };
    }

    pub fn flag(comptime short: str, comptime long: str) Arg {
        return Arg{ .short = "-"++short, .long = "--"++long, .kind = Kind{.flag = false} };
    }

    pub fn cmd(comptime short: str, comptime long: str) Arg {
        return Arg{ .short = short, .long = long, .kind = Kind{.cmd = null} };
    }
};

    pub var user_opts = [_]Cli.Arg{ 
        Cli.Arg.opt("n", "name"), 
        Cli.Arg.opt("p", "path"),
        Cli.Arg.cmd("b", "build"),
        Cli.Arg.cmd("i", "init"),
        Cli.Arg.cmd("r", "run"),
        Cli.Arg.flag("q", "quiet"),
    };
