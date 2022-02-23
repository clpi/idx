//! NOTE: Responsible for managing the Idleset
//! home dir, packages, repositories,
//! local project management and workspaces,
//! language distributions, and toolchains.
const std = @import("std");

pub const Toolchain = @import("./toolchain.zig");
pub const Config = @import("./config.zig");
pub const Registry = @import("./registry.zig");
pub const Cli = @import("./registry.zig");

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
