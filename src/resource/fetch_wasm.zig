const std = @import("std");
const Fetch = @import("Fetch.zig");

const js = struct {
    extern fn machFetchFileLength(str: [*]const u8, length: u32, length: *u32, frame: *anyopaque) void;
    extern fn machFetchFile(str: [*]const u8, length: u32, mem: *u8, frame: *anyopaque) void;
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

    fn getFileSize(_: *PlatformFetch, path: []const u8) u32 {
        var length: u32 = undefined;
        suspend js.machFetchFileLength(path.ptr, path.len, &length, @frame());
        return length;
    }

    pub fn fetchFile(fetch: *PlatformFetch, path: []const u8) anyerror![]const u8 {
        const name = try fetch.allocator.dupe(u8, path);
        defer fetch.allocator.free(name);

        var frame = async fetch.getFileSize(path);
        var mem: []u8 = try fetch.allocator.alloc(u8, await frame);

        suspend js.machFetchFile(name.ptr, name.len, &mem[0], @frame());
        return mem;
    }
};

export fn wasmFileLenCb(frame: *anyopaque, length: *u32, len: u32) void {
    const cb = @ptrCast(anyframe, @alignCast(std.meta.alignment(anyframe), frame));
    length.* = len;
    resume cb;
}

export fn wasmFileFetchCb(frame: *anyopaque) void {
    const cb = @ptrCast(anyframe, @alignCast(std.meta.alignment(anyframe), frame));
    resume cb;
}
