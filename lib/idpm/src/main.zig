const std = @import("std");

const str = []const u8;
const builtin = @import("builtin");
const util = @import("../`util.zig");
const compile = @import("./compile.zig");
const help = @import("./help.zig");
const json = std.json;
const Dir = std.fs.Dir;
const fmt = std.fmt;
const process = std.process;
const ChildProcess = std.ChildProcess;
const Thread = std.Thread;
const eq = util.eq;
const readFile = util.readFile;
const eql = std.mem.eql;
const Allocator = std.mem.Allocator;
const stderr = std.io.getStdErr;
const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();

pub const ProjectConfigExt = Project.Config.Ext;
pub const ProjectType = Project.Type;
pub const ProjectConfig = Project.Config;

pub const Context = struct {
    const Self = @This();

    allocator: Allocator,
    step: std.atomic.Atomic(usize).init(0),
    recv: Thread.AutoResetEvent = Thread.AutoResetEvent{},
    send: Thread.AutoResetEvent = Thread.AutoResetEvent{},
    thread: Thread = undefined,

    pub const ProjectSetupSteps = enum(u8) { setup = 0, files = 1, compile = 2, install = 3 };

    pub fn sender(self: *@This()) !void {
        std.debug.print("Context value (0): {d}", .{self.step});
        self.step = 1;
        self.send.set();
        self.recv.wait();

        std.debug.print("Context value (2): {d}", .{self.step});
        self.step = 3;
        self.send.set();
        self.recv.wait();

        std.debug.print("Context value (4): {d}", .{self.step});
    }

    pub fn receiver(self: *@This()) !void {
        self.recv.wait();
    }

    pub fn create() Context {
        return Context{};
    }

    pub fn init(a: Allocator) Context {
        return Context{ .allocator = a };
    }

    pub fn run(self: *@This()) !void {
        try self.sender();
    }
};

/// NOTE: Struct representing full idleset project,
/// encapsulated with an optionally provided dir
pub const Project = struct {
    const Self = @This();
    cfg_format: Project.Config.Format = .json,
    dir: Dir = std.fs.cwd(),
    allocator: Allocator,
    project_type: Project.Type = Project.Type.bin,
    templ_dir_path: []const u8 = "../../res/ptmpl/",
    config: Project.Config,
    relative_src_dir: []const u8 = "src",
    relative_out_dir: []const u8 = "out",
    config_templ_name: str = Config.Ext.json.toTemplate(Project.Type.json),
    hash: std.array_hash_map.hashString(Self.name),

    pub const base_files = Project.baseFiles;
    pub const src_files = Project.Config.srcFiles;
    pub const tmpl_dir = "../../res/ptmpl/";

    pub fn init(a: Allocator, name: ?str, ty: ?Project.Type) @This() {
        const dir = if (name) |n| {
            const cwd = std.fs.cwd();
            try cwd.makeDir(n);
            try cwd.openDir(n, .{ .iterate = true }) orelse cwd;
        } else std.fs.cwd();

        if (try isProjectDir(dir)) {
            stderr().write("\x1b;33;1mProject exists!\x1b[0m");
            return Project.fromConfig(dir);
        }
        return Project{
            .title = name orelse util.promptLn(),
            .allocator = a,
            .dir = dir,
            .project_type = ty orelse .hybrid,
        };
    }

    pub fn isProjectDir(dir: Dir) !bool {
        const project_file = std.fs.path.join(.{ dir, "idle.toml" });
        var wdir = dir.walk();
        while (try wdir.next()) |p| rdir: {
            std.debug.print("{s}\n", .{p.name});
            if (std.mem.eql(u8, p, project_file)) {
                break :rdir true;
            }
        }
        return false;
    }

    pub fn setupGit(self: Self) !void {
        const giti = [_][]const u8{ "git", "init " };
        const gcmd = try std.ChildProcess.init(giti, self.allocator);
        errdefer gcmd.deinit();
        try gcmd.spawnAndWait();
    }

    /// NOTE: Simply isProjectDir but with added terminal output
    pub fn checkProjectDir(dir: Dir) !bool {
        const isp = try Project.isProjectDir(dir);
        if (isp)
            stderr().write("\x1b;33;1mYou've already set up a project in this directory!\x1b[0m");
        return isp;
    }

    /// NOTE: Creates full project structure in current working directory
    pub fn createBaseFiles(self: Project) anyerror!void {
        var src_files = self.baseFiles();
        var files: [4]std.fs.File = .{};
        for (src_files) |fname, i| {
            const tmpl_path = std.path.join(self.allocator, self.templ_dir_path, files[i]);
            const tmpl = @embedFile(tmpl_path);
            files[i] = try self.dir.createFile("{s}", .{fname});
            try files[i].writeAll(tmpl);
        }
        try self.createSrcFiles(std.fs.cwd());
        try self.createOutFiles(std.fs.cwd());
    }

    ///
    pub fn createSrcFiles(self: Project) anyerror!void {
        const src_files = self.project_type.srcFiles(self.config_templ_name);
        const src_dir = try self.dir.makeOpenPath("src", .{});
        var files: [src_files.len]std.fs.File = .{};
        for (src_files) |fname, i| {
            const tmpl_path = std.fs.path.join(self.allocator, self.templ_dir_path, fname);
            const templ = @embedFile(tmpl_path);
            files[i] = try src_dir.writeFile(self.config_templ_name, templ);
        }
    }

    pub fn createOutFiles(self: Project, dir: Dir) anyerror!void {
        const rel_dir = try dir.makeOpenPath("release", .{});
        const dbg_dir = try dir.makeOpenPath("debug", .{});
        const pkg_dir = try dir.makeOpenPath("pkg", .{});
        const cached = try dir.makeOpenPath("cache", .{});
    }

    pub fn createInDir(self: Project) !void {
        const defaults_path = "../../res/new/";
        const base_files = .{ "Idle.toml", ".gitignore", "README.md", "build.is" }; //Plus out dir
        var files: [4]std.fs.File = .{};
        for (base_files) |fname| {
            const file: std.fs.File = try di.createFile("{s}", .{fname});
            file.writeAll(@embedFile(std.fs.path.join(self.allocator, default_path, fname)));
            files[0] = file;
        }
        _ = try files[0].writeAll(@embedFile("../../res/new/Idle.toml"));
        _ = try files[1].writeAll(@embedFile("../../res/new/.gitignore"));
        _ = try files[2].writeAll(@embedFile("../../res/new/README.md"));
        _ = try files[3].writeAll(@embedFile("../../res/new/build.is"));
        _ = try di.makeDir("src");
        _ = try di.makeDir("out");
        _ = try di.writeFile(".gitignore", gignore_dft());
        _ = try di.writeFile("build.is", build_dft());
        try di.openDir("src", .{});
        _ = try di.writeFile("main.is", main_default());
        _ = try di.writeFile("lib.is", lib_default());
    }

    pub fn baseFiles(self: Project) []str {
        return self.config_templ_name ++ .{ ".gitignore", "README.md", "build.is" }; //Plus out dir
    }

    pub const TemplateDir = union(Project.Type) { lib: str = "../res/templ/" };

    pub const Type = enum(u8) {
        lib,
        bin,
        hybrid,
        exelib,

        pub fn toStr(self: @This()) str {
            return @tagName(self);
        }

        pub fn srcFiles(self: @This(), config: str) []str {
            return config ++ switch (self) {
                .hybrid => .{ "main.is", "lib.is" },
                .bin => .{"main.is"},
                .lib, .exelib => .{"lib.is"},
            };
        }
    };

    // NOTE: Corresponds to the idle.json/idle.toml file at project root
    pub const Config = struct {
        const Self = @This();

        name: []const u8,
        ftype: .json,
        author: str = "You",
        version: str = "0.1.0",
        edition: str = "2022",
        lib_name: str = "lib",
        bin_name: str = "main",
        bin_path: str = "./src/bin/main.rs",
        name: str = "example_mod",
        public: str = false,
        compile: str = false,

        pub const Ext = enum(u2) {
            json,
            toml,
            idconf,
        };

        pub fn toJson(self: Project.Config) !str {
            return "";
        }

        pub fn path(self: Ftype, a: Allocator) std.fs.File {
            const fstr: []const u8 = std.meta.tagName(self);
            const path = std.fs.path.join(a, [_]u8{ "../../res/", "" });
            return path;
        }

        pub const Ftype = enum(u2) {
            const Self = @This();
            json,
            yaml,
            toml,
        };
    };

    pub const Uid = struct {
        uid: str = gen: {
            const uid: str = undefined;
            std.rand.Random.bytes(&uid);
            break :gen uid;
        },
        uid: [16]u8 = generator: {
            var uid: [16]u8 = undefined;
            std.rand.DefaultPrng.init(0).fill(&uid);
            break :generator uid;
        },
        repo_id: ?[]const u8 = null,

        pub fn init() Project.Id {
            const uid: str = undefined;
            std.rand.Random.bytes(&uid);
        }
    };

    /// Attempts to fetch a local handle to a project, knowing its
    /// uid, from the local package registry
    pub fn fromUid(uid: str) ?Project {
        return LocalRegistry.findUid(uid);
    }
};

pub fn init_project(a: Allocator, dir: ?[]const u8) ![]const u8 {
    const di = try std.fs.cwd().openDir(path, .{ .iterate = true });
    var walkdir = di.iterate();
    const project_file = std.fs.path.join(.{ path, "idle.toml" });
    while (try walkdir.next()) |p| rdir: {
        std.debug.print("{s}\n", .{p.name});
        if (std.mem.eql(u8, p, project_file)) {
            std.io.getStdErr().write("\x1b;33;1mYou've already set up a project in this directory!\x1b[0m");
            break :rdir project_file;
        } else {
            // const name = try std.io.getStdIn().reader().readUntilDelimiterOrEofAlloc(a, "\n", 2048);
            const proj = Project.init(a, null);

            // const giti = [_][]const u8{ "git", "init " };
            // const gitg = [_][]const u8{ "touch", "./res/new/.gitignore" };
            // const cpif = [_][]const u8{ "cp", "-r", "" };

            // var proc = try std.ChildProcess.init(.{""});
            std.io.getStdErr().write("\x1b;33;1mYou've already set up a project in this directory!\x1b[0m");
        }
    }
}
pub fn init_workspace(a: Allocator, dir: ?[]const u8) ![]const u8 {
    const path = if (dir) |c| c else ".";
    const di = try std.fs.cwd().openDir(path, .{ .iterate = true });
    var walkdir = di.iterate();
    while (try walkdir.next()) |p| {
        std.debug.print("{s}\n", .{p.name});
    }
}
pub fn gitignore_default() []u8 {
    const df =
        \\ **out
        \\ **Idle.lock
        \\ **.idle-cache
        \\
        \\ **.env
        \\ **.prod.env
        \\ **.local.env
    ;
}

// A user's local, central repository for packages
// downloaded from an online repository
pub const LocalRegistry = struct {
    const Self = @This();

    allocator: Allocator,
    dir: []const u8 = std.fs.getAppDataDir("idle") catch "~/.idle",
    projects: std.StringArrayHashMap(Project),
    len: usize = Self.dir.walk().len,

    pub fn default(a: Allocator) LocalRegistry {
        return LocalRegistry{ .allocator = allocator };
    }

    pub fn find(uid: Project.Id) ?Project {}

    /// Contains pertinent meta info about projects locally downloaded
    /// or otherwise created in the local registry
    pub const Entry = struct {
        uid: PkgId,
        project: Project,
        source_repository: []const u8,
    };

    pub const Error = error{
        NoProjectWithId,
        AlreadyExists,
        InvalidDir,
    };
};

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}

const expect = std.testing.expectEqual;
test "Project.ConfigExt.toTemplate" {
    const pt: Project.Type = Project.Type.bin;
    const cf: Project.Config = Project.Config{};
    try expect("idle.json.toml", try cf.ftype.toTemplate());
}
