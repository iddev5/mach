const std = @import("std");
const Fetch = @import("Fetch.zig");

pub const PlatformFetch = struct {
    self_dir: std.fs.Dir = undefined,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !PlatformFetch {
        const self_path = try std.fs.selfExeDirPathAlloc(allocator);
        defer allocator.free(self_path);

        var self_dir = try std.fs.openDirAbsolute(self_path, .{});
        errdefer self_dir.close();

        return PlatformFetch{
            .self_dir = self_dir,
            .allocator = allocator,
        };
    }

    pub fn deinit(fetch: *PlatformFetch) void {
        fetch.self_dir.close();
    }

    pub fn fetchFile(fetch: *PlatformFetch, path: []const u8) ![]const u8 {
        var file = try fetch.self_dir.openFile(path, .{});
        defer file.close();

        const mem = try file.reader().readAllAlloc(fetch.allocator, std.math.maxInt(usize));
        errdefer fetch.allocator.free(mem);

        return mem;
    }
};
