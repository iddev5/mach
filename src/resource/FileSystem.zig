const std = @import("std");
const builtin = @import("builtin");

pub const FileSystem = struct {
    internal: GetFileSystemType(),

    pub fn init(allocator: std.mem.Allocator, allow_absolute_access: bool) !FileSystem {
        return FileSystem{ .internal = try GetFileSystemType().init(allocator, allow_absolute_access) };
    }

    pub fn deinit(fs: *FileSystem) void {
        fs.internal.deinit();
    }

    pub fn fetchFile(fs: *FileSystem, path: []const u8) !FileSystem.File {
        return try fs.internal.fetchFile(path);
    }

    pub const File = struct {
        internal: GetFileType(),

        pub fn close(file: *File) void {
            file.internal.close();
        }

        pub fn readAll(file: *File, allocator: std.mem.Allocator) ![]const u8 {
            return try file.internal.readAll(allocator);
        }
    };
};

fn GetFileSystemType() type {
    if (builtin.cpu.arch != .wasm32) return @import("fs_native.zig").PlatformFs;
}

fn GetFileType() type {
    return GetFileSystemType().PlatformFile;
}
