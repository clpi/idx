//! derived from github.com/ziglibs/known-folders.zig with modifications, cheers 
//!
const std = @import("std");
const str = []const u8;
const Allocator = std.mem.Allocator;
const Dir = std.fs.Dir;
const root = @import("root");
const builtin = @import("builtin");

pub const windows_spec = Dirs.Spec.Windows.win_spec;
pub const mac_spec = Dirs.Spec.MacOs.mac_spec;
pub const xdg_spec = Dirs.Spec.Xdg.xdg_spec;

pub const Dirs = enum {
    home,
    documents,
    pictures,
    music,
    videos,
    desktop,
    downloads,
    public,
    fonts,
    app_menu,
    cache,
    roaming_configuration,
    local_configuration,
    global_configuration,
    data,
    runtime,
    executable_dir,

    pub fn open(a: Allocator, folder: Dirs, args: Dir.OpenDirOptions) OpenError!?Dir {
        var path_or_null = try getPath(a, folder);
        if (path_or_null) |path| {
            defer a.free(path);

            return try std.fs.cwd().openDir(path, args);
        } else {
            return null;
        }
    }
    fn getPathXdg(user_dirs: Dirs, allocator: Allocator, arena: *std.heap.ArenaAllocator) Dirs.Error!?[]const u8 {
        const folder_spec = xdg_spec.get(user_dirs);
        var env_opt = std.os.getenv(folder_spec.env.name);
        if (env_opt == null and folder_spec.env.user_dir) block: {
            const config_dir_path = if (std.io.is_async) blk: {
                var frame = arena.allocator().create(@Frame(getPathXdg)) catch break :block;
                _ = @asyncCall(frame, {}, getPathXdg, .{ arena.allocator(), arena, .local_configuration });
                break :blk (await frame) catch null orelse break :block;
            } else blk: {
                break :blk getPathXdg(arena.allocator(), arena, .local_configuration) catch null orelse break :block;
            };
            const config_dir = std.fs.cwd().openDir(config_dir_path, .{}) catch break :block;
            const home = std.os.getenv("HOME") orelse break :block;
            const user_dir = config_dir.openFile("user-dirs.dirs", .{}) catch null orelse break :block;

            var read: [1024 * 8]u8 = undefined;
            _ = user_dir.readAll(&read) catch null orelse break :block;
            const start = folder_spec.env.name.len + "=\"$HOME".len;

            var line_it = std.mem.split(u8, &read, "\n");
            while (line_it.next()) |line| {
                if (std.mem.startsWith(u8, line, folder_spec.env.name)) {
                    const end = line.len - 1;
                    if (start >= end) {
                        return error.ParseError;
                    }

                    var subdir = line[start..end];

                    env_opt = try std.mem.concat(arena.allocator(), u8, &[_][]const u8{ home, subdir });
                    break;
                }
            }
        }

        if (env_opt) |env| {
            if (folder_spec.env.suffix) |suffix| {
                return try std.mem.concat(allocator, u8, &[_][]const u8{ env, suffix });
            } else {
                return try allocator.dupe(u8, env);
            }
        } else {
            const default = folder_spec.default orelse return null;
            if (default[0] == '~') {
                const home = std.os.getenv("HOME") orelse return null;
                return try std.mem.concat(allocator, u8, &[_][]const u8{ home, default[1..] });
            } else {
                return try allocator.dupe(u8, default);
            }
        }
    }

    /// Returns the path to the folder or, if the folder does not exist, `null`.
    pub fn getPath(user_dir: Dirs, allocator: Allocator) Error!?[]const u8 {
        if (user_dir == .executable_dir) {
            return std.fs.selfExeDirPathAlloc(allocator) catch |err| switch (err) {
                error.OutOfMemory => return error.OutOfMemory,
                else => null,
            };
        }
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();

        switch (builtin.os.tag) {
            .windows => {
                const folder_spec = windows_spec.get(user_dir);

                switch (folder_spec) {
                    .by_guid => |guid| {
                        var dir_path_ptr: [*:0]u16 = undefined;
                        switch (std.os.windows.shell32.SHGetDirsPath(
                            &guid,
                            std.os.windows.KF_FLAG_CREATE, // TODO: Chose sane option here?
                            null,
                            &dir_path_ptr,
                        )) {
                            std.os.windows.S_OK => {
                                defer std.os.windows.ole32.CoTaskMemFree(@ptrCast(*anyopaque, dir_path_ptr));
                                const global_dir = std.unicode.utf16leToUtf8Alloc(allocator, std.mem.span(dir_path_ptr)) catch |err| switch (err) {
                                    error.UnexpectedSecondSurrogateHalf => return null,
                                    error.ExpectedSecondSurrogateHalf => return null,
                                    error.DanglingSurrogateHalf => return null,
                                    error.OutOfMemory => return error.OutOfMemory,
                                };
                                return global_dir;
                            },
                            std.os.windows.E_OUTOFMEMORY => return error.OutOfMemory,
                            else => return null,
                        }
                    },
                    .by_env => |env_path| {
                        if (env_path.subdir) |sub_dir| {
                            const root_path = std.process.getEnvVarOwned(arena.allocator(), env_path.env_var) catch |err| switch (err) {
                                error.EnvironmentVariableNotFound => return null,
                                error.InvalidUtf8 => return null,
                                error.OutOfMemory => |e| return e,
                            };
                            return try std.fs.path.join(allocator, &[_][]const u8{ root_path, sub_dir });
                        } else {
                            return std.process.getEnvVarOwned(allocator, env_path.env_var) catch |err| switch (err) {
                                error.EnvironmentVariableNotFound => return null,
                                error.InvalidUtf8 => return null,
                                error.OutOfMemory => |e| return e,
                            };
                        }
                    },
                }
            },
            .macos => {
                if (@hasDecl(root, "known_folders_config") and root.known_folders_config.xdg_on_mac) {
                    return getPathXdg(allocator, &arena, user_dir);
                }

                switch (mac_spec.get(user_dir)) {
                    .absolute => |abs| {
                        return try allocator.dupe(u8, abs);
                    },
                    .suffix => |s| {
                        const home_dir = if (std.os.getenv("HOME")) |home|
                            home
                        else
                            return null;

                        if (s) |suffix| {
                            return try std.fs.path.join(allocator, &[_][]const u8{ home_dir, suffix });
                        } else {
                            return try allocator.dupe(u8, home_dir);
                        }
                    },
                }
            },

            // Assume unix derivatives with XDG
            else => return getPathXdg(allocator, &arena, user_dir),
        }
        unreachable;
    }

    pub fn spec(dirs: Dirs, os: Dirs.Os) Os.Spec {
        inline for (std.meta.fields(Dirs)) |fld| {
            if (dirs == @field(Dirs, fld.name))
                return @field(os, fld.name);
        }
    }

    pub fn specOfOs(dirs: Dirs) Os.Spec {
        const os = switch (builtin.os.tag) {
            .windows => Os.windows,
            .linux => Os.linux,
            .macos => Os.macos,
        };
        return dirs.spec(os);
    }

    pub const Error = error{OutOfMemory};

    const OpenError = (Dir.OpenError || Dirs.Error);
};

pub const Os = enum(u2) {
    linux,
    windows,
    macos,

    pub const Spec = union(Os) {
        linux: Xdg,
        windows: Windows,
        macos: MacOs,
        const Self = @This();

        pub const Xdg = packed struct {
            default: ?str = null,
            env: packed struct {
                name: []const u8,
                user_dir: bool = false,
                suffix: ?[]const u8 = null,
            },

            pub const spec = Dirs.SpecAlt(Xdg){
                .home = Xdg.init("HOME", false, null),
                .documents = init("XDG_DOCUMENTS_DIR", true, "~/Documents"),
                .pictures = init("XDG_PICTURES_DIR", true, "~/Pictures"),
                .music = init("XDG_MUSIC_DIR", true, "~/Music"),
                .videos = init("XDG_VIDEOS_DIR", true, "~/Videos"),
                .desktop = init("XDG_DESKTOP_DIR", true, "~/Desktop"),
                .downloads = init("XDG_DOWNLOAD_DIR", true, "~/Downloads"),
                .public = init("XDG_PUBLICSHARE_DIR", true, "~/Public"),
                .fonts = init("XDG_DATA_HOME", false, "/fonts", "~/.local/share/fonts"),
                .app_menu = init("XDG_DATA_HOME", false, "/applications", "~/.local/share/applications"),
                .cache = init("XDG_CACHE_HOME", false, "~/.cache", null),
                .roaming_configuration = init("XDG_CONFIG_HOME", false, "~/.config"),
                .local_configuration = init("XDG_CONFIG_HOME", false, "~/.config"),
                .global_configuration = init("XDG_CONFIG_DIRS", false, "/etc"),
                .data = init("XDG_DATA_HOME", false, "~/.local/share"),
                .runtime = init("XDG_RUNTIME_DIR", false, null),
            };

            pub fn init(name: str, user_dir: bool, suffix: ?str, default: ?str) Xdg {
                const env = .{ .name = name, .user_dir = user_dir, .suffix = suffix };
                return Xdg{ .env = env, .default = default };
            }
        };

        pub const MacOs = union(enum(u2)) {
            suffixo: ?[]const u8 = null,
            absolute: []const u8,

            pub const spec = Dirs.SpecAlt(MacOs){
                .home = MacOs{null},
                .documents = MacOs{"Documents"},
                .pictures = MacOs{"Pictures"},
                .music = MacOs{"Music"},
                .videos = MacOs{"Movies"},
                .desktop = MacOs{"Desktop"},
                .downloads = MacOs{"Downloads"},
                .public = MacOs{"Public"},
                .fonts = MacOs{"Library/Fonts"},
                .app_menu = MacOs{"Applications"},
                .cache = MacOs{"Library/Caches"},
                .roaming_configuration = MacOs{"Library/Preferences"},
                .local_configuration = MacOs{"Library/Application Support"},
                .global_configuration = MacOs{ .absolute = "/Library/Preferences" },
                .data = MacOs{"Library/Application Support"},
                .runtime = MacOs{"Library/Application Support"},
            };
        };

        pub const Windows = union(enum) {
            by_env: packed struct {
                env_var: []const u8,
                subdir: ?[]const u8 = null,
            },
            by_guid: std.os.windows.GUID,

            pub fn byGuid(guid: str) Windows {
                const guid_parsed = std.os.windows.GUID.parse(guid);
                return Windows{ .by_guid = guid_parsed };
            }

            pub fn byEnv(evar: str, subdir: ?str) Windows {
                const env = .{ .env_var = evar, .subdir = subdir };
                return Windows{ .by_env = env };
            }

            pub const spec = blk: {
                @setEvalBranchQuota(10_000); // workaround for zig eval branch quota when parsing the GUIDs
                break :blk Dirs.SpecAlt(Windows){
                    .home = byGuid("{5E6C858F-0E22-4760-9AFE-EA3317B67173}"),
                    .documents = byGuid("{FDD39AD0-238F-46AF-ADB4-6C85480369C7}"),
                    .pictures = byGuid("{33E28130-4E1E-4676-835A-98395C3BC3BB}"),
                    .music = byGuid("{4BD8D571-6D19-48D3-BE97-422220080E43}"),
                    .videos = byGuid("{18989B1D-99B5-455B-841C-AB7C74E4DDFC}"),
                    .desktop = byGuid("{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}"),
                    .downloads = byGuid("{374DE290-123F-4565-9164-39C4925E467B}"),
                    .public = byGuid("{DFDF76A2-C82A-4D63-906A-5644AC457385}"),
                    .fonts = byGuid("{FD228CB7-AE11-4AE3-864C-16F3910AB8FE}"),
                    .app_menu = byGuid("{625B53C3-AB48-4EC1-BA1F-A1EF4146FC19}"),
                    .cache = byEnv("LOCALAPPDATA", "Temp"),
                    .roaming_configuration = byGuid("{3EB685DB-65F9-4CF6-A03A-E3EF65729F3D}"), // FOLDERID_RoamingAppData
                    .local_configuration = byGuid("{F1B32785-6FBA-4FCF-9D55-7B8E7F157091}"), // FOLDERID_LocalAppData
                    .global_configuration = byGuid("{62AB5D82-FDC1-4DC3-A9DD-070D1D495D97}"), // FOLDERID_ProgramData
                    .data = byEnv("APPDATA", null),
                    .runtime = byEnv("LOCALAPPDATA", "Temp"),
                };
            };
        };
    };
    // NOTE: This doesn't seem like the best way to do this,
    // but my spec function up there hasn't been tested yet so
    // i'll leave this implementation in for now.
    fn SpecAlt(comptime T: type) type {
        return struct {
            const Self = @This();

            home: T,
            documents: T,
            pictures: T,
            music: T,
            videos: T,
            desktop: T,
            downloads: T,
            public: T,
            fonts: T,
            app_menu: T,
            cache: T,
            roaming_configuration: T,
            local_configuration: T,
            global_configuration: T,
            data: T,
            runtime: T,

            fn get(self: Self, folder: Dirs) T {
                inline for (std.meta.fields(Self)) |fld| {
                    if (folder == @field(Dirs, fld.name))
                        return @field(self, fld.name);
                }
            }
        };
    }
};

// Ref decls
// comptime {
//     _ = Dirs;
//     _ = Dirs.Error;
//     _ = Dirs.open;
//     _ = Dirs.getPath;
// }
