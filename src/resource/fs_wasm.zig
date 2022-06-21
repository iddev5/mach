const std = @import("std");
const FileSystem = @import("FileSystem.zig").FileSystem;

pub const PlatformFs = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, allow_absolute_access: bool) !PlatformFs {
        _ = allow_absolute_access;
        return PlatformFs{ .allocator = allocator };
    }

    pub fn deinit(fs: *PlatformFs) void {
        _ = fs;
    }

    pub fn fetchFile(fs: *PlatformFs, path: []const u8) !FileSystem.File {
        var file = try fs.self_dir.openFile(path, .{});
        errdefer file.close();

        return FileSystem.File{ .internal = .{ .fd = file } };
    }

    pub const PlatformFile = struct {
        fd: std.fs.File,

        pub fn close(file: *PlatformFile) void {
            file.fs.close();
        }

        pub fn readAll(file: *PlatformFile, allocator: std.mem.Allocator) ![]const u8 {
            return try file.fd.reader().readAllAlloc(allocator, std.math.maxInt(usize));
        }
    };
};
