const std = @import("std");
const web = @import("application.zig");

export fn wasmInit() void {
    web.init(800, 600, "Demo", .{});
}

export fn wasmDeinit() void {
    web.deinit();
}

export fn wasmUpdate() bool {
    return true;
}
