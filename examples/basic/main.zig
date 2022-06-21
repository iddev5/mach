const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");

const App = @This();

is_full: bool = false,

pub fn init(app: *App, engine: *mach.Engine) !void {
    _ = app;
    _ = engine;
    //engine.setWaitEvent(std.math.floatMax(f64));
    try engine.setOptions(.{ .fullscreen = false });
}

pub fn deinit(_: *App, _: *mach.Engine) void {}

pub fn update(app: *App, engine: *mach.Engine) !void {
    _ = app;
    while (engine.pollEvent()) |event| {
        switch (event) {
            .key_press => |ev| {
                std.log.info("event", .{});
                if (ev.key == .escape) {
                    engine.setShouldClose(true);
                } else if (ev.key == .a) {
                    std.log.info("changed", .{});
                    try engine.setOptions(.{ .fullscreen = !app.is_full });
                    app.is_full = !app.is_full;
                }
                std.log.info("key pressed: {s}", .{@tagName(ev.key)});
            },
            else => {},
        }
    }
    std.log.info("here", .{});
}
