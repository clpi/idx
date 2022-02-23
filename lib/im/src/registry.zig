//! Local registry data, including the path, packages stored, etc.
const Self = @This();
const std = @import("std");
pub const Toolchain = @import("./toolchain.zig");
pub const Config = @import("./config.zig");
pub const Registry = @import("./registry.zig");
pub const Cli = @import("./registry.zig");
pub const fs = std.fs;

dir: fs.Dir = fs.openDirAbsolute(""),
