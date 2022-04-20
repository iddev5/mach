const std = @import("std");
const web = @import("mach-web");

pub fn webInit() void {
    web.init(800, 600, "Demo", .{});
    std.log.info("Demo init!", .{});
}

pub fn webDeinit() void {
    web.deinit();
}

pub fn webUpdate() bool {
    return true;
}
