const std = @import("std");
const FileSystem = @import("FileSystem.zig").FileSystem;

pub const PlatformFs = struct {
    self_dir: std.fs.Dir = undefined,
    allow_absolute_access: bool = false,

    pub fn init(allocator: std.mem.Allocator, allow_absolute_access: bool) !PlatformFs {
        const self_path = try std.fs.selfExeDirPathAlloc(allocator);
        defer allocator.free(self_path);

        var self_dir = try std.fs.openDirAbsolute(self_path, .{});
        errdefer self_dir.close();

        return PlatformFs{
            .self_dir = self_dir,
            .allow_absolute_access = allow_absolute_access,
        };
    }

    pub fn deinit(fs: *PlatformFs) void {
        fs.self_dir.close();
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
