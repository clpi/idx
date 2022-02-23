//! NOTE: Configuration governing all aspects of idleset
//! ecosystem usage. Structs below are ordered in the
//! order they are loaded when a component in the system
//! is called upon.
const std = @import("std");
const builtin = @import("builtin");
const str = []const u8;

pub const Toolchain = @import("./toolchain.zig");
pub const Config = @import("./config.zig");
pub const Registry = @import("./registry.zig");
pub const Cli = @import("./registry.zig");

const io = std.io;
const fs = std.fs;
const path = fs.path;
const event = std.event;
const process = std.process;
const Thread = std.Thread;
const Target = std.Target;
const Allocator = std.mem.Allocator;

// NOTE: Not sure how necesssary.. can just call
// all these stdlib functions at a whim
pub const SystemCfg = struct {
    os: ?std.Target.Os.Tag = null,
    cpu_num: u32 = @as(u32, Thread.getCpuCount() catch 1),

    pub fn init() SystemCfg {
        return SystemCfg{};
    }
};

// NOTE: Primarily for setings intended to default to an
// appropriate path/value/location, but all can be changed
pub const EnvConfig = struct {
    const Self = @This();

    pub const default_home  = .{.a="$HOME/.idle/", .b="~/.idle/"};
    pub const default_conf  = .{.a="$HOME/.config/idle/", .b = "$HOME/.idle/conf/"};
    pub const default_data  = .{.a="$HOME/.local/share/idle/", .b="$HOME/.idle/data"};
    pub const default_cache = .{.a="$HOME/.cache/idle/", .b="$HOME/.idle/cache/"};

    pub const DirConfig = struct {
        data_dir: str = path.join(fs.getAppDataDir("idle") catch default_home.a),
        home_dir: str = EnvConfig.default_home.a, 
        conf_dir: str = EnvConfig.default_conf.a,
        cache_dir: str = EnvConfig.default_cache.a,
    };

    pub const ProjConfig = struct {
        project_rel_outp_dir: str = "out/",
        project_rel_src_dir: str  = "src/",
        project_config_name: str = "idle", //    -> ${src}/idle.spec
        project_main_file_name: str = "main", // -> ${src}/main.id
        project_lib_file_name: str = "lib", //   -> ${src}/lib.id
        project_config_format: str = .json,
        project_default_vcs = .git,
        project_create_with_vcs = true,
    };
    verbosity: u8 = "1",

    pub fn init(a: Allocator) EnvConfig {
        var eval = try std.process.getEnvVarOwned(a, key);
        if (!std.mem.eql(u8, val, eval)) eval = val else continue;
    }
    pub fn keys(a: Allocator) std.ArrayList(str) {
        var keyl = std.ArrayList(str).init(a);
        keyl.appendSlice(std.meta.fieldNames(Self));
        return keyl;
    }

    pub fn get(a: Allocator, key: str) anyerror!?str {
        return if (try std.process.getEnvVarOwned(a, key)) |ev| ev else {
            const def = EnvConfig.default();
            if (@hasField(def, key)) @field(def, key) else null;
        };
    }

    pub fn default() Self {
        return Self{
            .home_dir = path.join(fs.getAppDataDir("idle") catch "~/.idle/"),
            .verbosity = "1",
        };
    }

    pub fn set(a: Allocator, key: str, val: str) !void {
        var eval = try std.process.getEnvVarOwned(a, key);
        if (!std.mem.eql(u8, val, eval)) eval = val else continue;
    }
};

pub const CentralCfg = struct {
    const Self = @This();

    pub const Active = union(enum) {
        root: CentralCfg,
        project: struct {
            config: CentralCfg,
            project_dir: std.fs.Dir,
        },
        workspace: struct {
            config: CentralCfg,
            workspace_dir: std.fs.Dir,
        },
    };
};

pub const RootConfig = struct {
    const Self = @This();
};

pub const LocalConfig = struct {};

pub const ParseError = error{
    InvalidKey,
    InvalidKeyValue,
};

pub const CfgError = process.GetEnvVarOwnedError || ParseErrorerror ||
    error{
    FileDoesNotExist,
    DirDoesNotExist,
    InvalidKey,
};

pub const ProjectCfg = struct {
    name: str,
    author: str,
    edition: .v2022,
    fmt: Fmt.json,

    pub const Fmt = enum {
        json, toml, idspec, yaml,
    };

};

// NOTE: Ater integrating this into the main,
// root src folder, present meta info like this
// somewhere more appropriate
pub const IdlaAbout = struct {
    edition: IdlaAbout.Edition.current,
    version: std.SemanticVersion = std.SemanticVersion.parse("0.1.0"),

    pub const Edition = enum { 
        pub const current = @This().v2022;
        v2022,
    };


};
