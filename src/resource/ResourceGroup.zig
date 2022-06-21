const Resource = @import("ResourceManager.zig").Resource;

const ResourceGroup = @This();
// Removes/unloads all resources which are in present group. The way is works is, check if
// ``resources[resources.len - i].group == current_group`` then unload the resource.
// Repeat this until we reach a different group in backward order.
pub fn destroy(self: *ResourceGroup) !void {
    _ = self;
}

// Loads the resource into current group. If the resource is already present, then don't
// do anything.
// Lets say uri is ``res://textures/ziggy.png`` (res is the collection name), so in a
// native device, it will load the resource present at ``{root}/textures/ziggy.png``
pub fn loadResource(self: *ResourceGroup, uri: []const u8) !void {
    _ = self;
    _ = uri;
}

// Returns the Resource. Loads if not already loaded.
pub fn getResource(self: *ResourceGroup, uri: []const u8) !Resource {
    _ = self;
    _ = uri;
}
