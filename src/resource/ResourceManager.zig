const std = @import("std");
const uri_parser = @import("uri_parser.zig");
const Fetch = @import("Fetch.zig");

const ResourceManager = @This();

allocator: std.mem.Allocator,
paths: []const []const u8,
// TODO: Use comptime hash map for resource_types
resource_map: std.StringArrayHashMapUnmanaged(ResourceType) = .{},
resources: std.StringHashMapUnmanaged(Resource) = .{},
context: ?*anyopaque = null,
fetch: Fetch,

pub fn init(allocator: std.mem.Allocator, paths: []const []const u8, resource_types: []const ResourceType) !ResourceManager {
    var fetch = try Fetch.init(allocator);
    errdefer fetch.deinit();

    var resource_map: std.StringArrayHashMapUnmanaged(ResourceType) = .{};
    for (resource_types) |res| {
        try resource_map.put(allocator, res.name, res);
    }

    return ResourceManager{
        .allocator = allocator,
        .paths = paths,
        .resource_map = resource_map,
        .fetch = fetch,
    };
}

pub const ResourceType = struct {
    name: []const u8,
    load: fn (context: ?*anyopaque, mem: []const u8) error{ InvalidResource, CorruptData }!*anyopaque,
    unload: fn (context: ?*anyopaque, resource: *anyopaque) void,
};

pub fn setLoadContext(resource_manager: *ResourceManager, ctx: anytype) void {
    var context = resource_manager.allocator.create(@TypeOf(ctx)) catch unreachable;
    context.* = ctx;
    resource_manager.context = context;
}

pub fn loadResource(resource_manager: *ResourceManager, uri: []const u8) !Resource {
    const uri_data = try uri_parser.parseUri(uri);

    var memory: ?[]const u8 = null;
    for (resource_manager.paths) |path| {
        const full_path = try std.fs.path.join(resource_manager.allocator, &.{ path, uri_data.path });
        defer resource_manager.allocator.free(full_path);

        var frame = async resource_manager.fetch.fetchFile(full_path);
        memory = await frame catch |err| switch (err) {
            error.FileNotFound => continue,
            else => |e| return e,
        };
    }

    if (memory) |mem| {
        if (resource_manager.resource_map.get(uri_data.scheme)) |res_type| {
            const resource = try res_type.load(resource_manager.context, mem);
            errdefer res_type.unload(resource_manager.context, resource);

            const res = Resource{
                .uri = try resource_manager.allocator.dupe(u8, uri),
                .resource = resource,
                .size = mem.len,
            };
            try resource_manager.resources.putNoClobber(resource_manager.allocator, uri, res);
            return res;
        }

        return error.UnknownResourceType;
    }

    return error.ResourceNotFound;
}

pub fn getResource(resource_manager: *ResourceManager, uri: []const u8) ?Resource {
    return resource_manager.resources.get(uri);
}

pub fn unloadResource(resource_manager: *ResourceManager, res: Resource) void {
    const uri_data = uri_parser.parseUri(res.uri) catch unreachable;
    if (resource_manager.resource_map.get(uri_data.scheme)) |res_type| {
        res_type.unload(resource_manager.context, res.resource);
    }

    _ = resource_manager.resources.remove(res.uri);
}

pub const Resource = struct {
    uri: []const u8,
    resource: *anyopaque,
    size: u64,

    // Returns the raw data, which you can use in any ways. Internally it is stored
    // as an *anyopaque
    pub fn getData(res: *const Resource, comptime T: type) *T {
        return @ptrCast(*T, @alignCast(std.meta.alignment(*T), res.resource));
    }
};
