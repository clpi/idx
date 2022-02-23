const std = @import("std");
const event = std.event;
const Thread = std.Thread;
const m = std.macho.createLoadDylibCommand;

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
