const std = @import("std");
const builtin = @import("builtin");

const Fetch = @This();

internal: GetFetchType(),

pub fn init(allocator: std.mem.Allocator) !Fetch {
    return Fetch{ .internal = try GetFetchType().init(allocator) };
}

pub fn deinit(fetch: *Fetch) void {
    fetch.internal.deinit();
}

pub fn fetchFile(fetch: *Fetch, path: []const u8) ![]const u8 {
    return try fetch.internal.fetchFile(path);
}

fn GetFetchType() type {
    if (builtin.cpu.arch == .wasm32)
        return @import("fetch_wasm.zig").PlatformFetch;
    return @import("fetch_native.zig").PlatformFetch;
}

fn GetFileType() type {
    return GetFetchType().PlatformFile;
}
