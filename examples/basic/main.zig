const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");

const App = @This();

resource_manager: mach.ResourceManager,

pub fn init(app: *App, engine: *mach.Engine) !void {
    _ = app;
    _ = engine;

    const Context = struct { allocator: std.mem.Allocator };

    const Texture = struct {
        fn load(ctx: ?*anyopaque, mem: []const u8) error{ InvalidResource, CorruptData }!*anyopaque {
            const context = @ptrCast(*Context, @alignCast(std.meta.alignment(*Context), ctx.?));
            var al = context.allocator.create(std.ArrayListUnmanaged(u8)) catch unreachable;
            al.* = .{};
            al.*.appendSlice(context.allocator, mem[0..4]) catch unreachable;
            return al;
        }

        fn unload(ctx: ?*anyopaque, res: *anyopaque) void {
            const context = @ptrCast(*Context, @alignCast(std.meta.alignment(*Context), ctx.?));
            var al = @ptrCast(*std.ArrayListUnmanaged(u8), @alignCast(std.meta.alignment(*std.ArrayListUnmanaged(u8)), res)).*;
            al.deinit(context.allocator);
        }
    };

    app.resource_manager = try mach.ResourceManager.init(engine.allocator, &.{"assets"}, &.{mach.ResourceManager.ResourceType{
        .name = "texture",
        .load = Texture.load,
        .unload = Texture.unload,
    }});

    app.resource_manager.setLoadContext(.{ .allocator = engine.allocator });

    try app.resource_manager.loadResource("texture://gotta-go-fast.png");
    var res = app.resource_manager.getResource("texture://gotta-go-fast.png").?;
    //res = try app.resource_manager.getResource("texture://gotta-go-fast.png");
    //app.resource_manager.unloadResource(res);
    //res = try app.resource_manager.getResource("texture://gotta-go-fast.png");
    //res = try app.resource_manager.getResource("texture://gotta-go-fast.png");
    //app.resource_manager.unloadResource(res);
    //res = try app.resource_manager.getResource("texture://gotta-go-fast.png");
    std.log.info("{s}", .{blk: {
        const data = res.getData(std.ArrayListUnmanaged(u8));
        break :blk data.items[0..4];
    }});
    _ = res;
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
                } else if (ev.key == .enter) {
                    const res = app.resource_manager.getResource("texture://gotta-go-fast.png").?;
                    std.log.info("u: {s}", .{blk: {
                        const data = res.getData(std.ArrayListUnmanaged(u8));
                        break :blk data.items[0..4];
                    }});
                }
            },
            else => {},
        }
    }
}
