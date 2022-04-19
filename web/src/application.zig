const std = @import("std");

const js = struct {
    extern fn webCanvasInit() void;
    extern fn webCanvasDeinit() void;
    extern fn webCanvasSetSize(width: u32, height: u32) void;
    extern fn webCanvasSetTitle(title: [*]const u8, len: u32) void;
};

pub const Hints = struct {};

pub fn init(width: u32, height: u32, title: []const u8, hints: Hints) void {
    js.webCanvasInit();

    setSize(width, height);
    setTitle(title);

    _ = hints;
}

pub fn deinit() void {
    js.webCanvasDeinit();
}

pub fn setSize(width: u32, height: u32) void {
    js.webCanvasSetSize(width, height);
}

pub fn setTitle(title: []const u8) void {
    js.webCanvasSetTitle(title.ptr, title.len);
}
