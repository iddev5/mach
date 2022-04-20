const std = @import("std");
const app = @import("app");
pub usingnamespace @import("application.zig");

const js = struct {
    extern fn webLogWrite(str: [*]const u8, len: u32) void;
    extern fn webLogFlush() void;
    extern fn webPanic(str: [*]const u8, len: u32) void;
};

pub const log_level = .info;

const LogError = error{};
const LogWriter = std.io.Writer(void, LogError, writeLog);

fn writeLog(_: void, msg: []const u8) LogError!usize {
    js.webLogWrite(msg.ptr, msg.len);
    return msg.len;
}

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const prefix = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    const writer = LogWriter{ .context = {} };

    writer.print(message_level.asText() ++ prefix ++ format ++ "\n", args) catch return;
    js.webLogFlush();
}

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    js.webPanic(msg.ptr, msg.len);
    unreachable;
}

export fn wasmInit() void {
    app.webInit();
}

export fn wasmUpdate() bool {
    return app.webUpdate();
}

export fn wasmDeinit() void {
    app.webDeinit();
}
