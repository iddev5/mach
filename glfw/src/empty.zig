const std = @import("std");
const testing = std.testing;

test "empty" {
    std.debug.print("hello..\n", .{});
}
