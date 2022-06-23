const std = @import("std");
const Fetch = @import("Fetch.zig");

const js = struct {
    extern fn machFetchFileLength(str: [*]const u8, length: u32, ctx: *anyopaque) void;
    extern fn machFetchFile(str: [*]const u8, length: u32, ctx: *anyopaque, mem: *u8) void;
};

pub const PlatformFetch = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !PlatformFetch {
        return PlatformFetch{
            .allocator = allocator,
        };
    }

    pub fn deinit(fetch: *PlatformFetch) void {
        _ = fetch;
    }

    pub fn fetchFile(fetch: *PlatformFetch, path: []const u8, ctx: *anyopaque, cb: fn (ctx: *anyopaque, mem: []const u8) void) anyerror!void {
        var length: ?u32 = null;
        js.machFetchFileLength(path.ptr, path.len, &length);

        while (length == null) {}

        var mem: ?[]u8 = try fetch.allocator.alloc(u8, length.?);
        defer if (mem) |m| fetch.allocator.free(m);

        while (mem == null) {}

        js.machFetchFile(path.ptr, path.len, ctx, &mem.?[0]);
        cb(ctx, mem.?);
    }
};

export fn wasmFileLenCb(ctx: *anyopaque, len: u32) void {
    var length = @ptrCast(*u32, @alignCast(std.meta.alignment(*u32), ctx));
    length.* = len;
}
