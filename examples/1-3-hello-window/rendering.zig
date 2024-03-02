const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;
const sgapp = sokol.app_gfx_glue;
const slog = sokol.log;
const print = std.debug.print;

var pass_action: sg.PassAction = .{};

export fn init() void {
    sg.setup(.{
        .context = sgapp.context(),
        .logger = .{ .func = slog.func },
    });
    pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.2, .g = 0.5, .b = 0, .a = 1 },
    };
    print("Backend: {}\n", .{sg.queryBackend()});
}

export fn frame() void {
    const b = pass_action.colors[0].clear_value.b + 0.01;
    pass_action.colors[0].clear_value.b = if (b > 1.0) 0.0 else b;
    sg.beginDefaultPass(pass_action, sapp.width(), sapp.height());
    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    sg.shutdown();
}

export fn event(e: ?*const sapp.Event) void {
    const ev = e.?; _ = &ev;
    switch(ev.type) {
        .KEY_DOWN => switch(ev.key_code) {
            .ESCAPE => sapp.quit(),
            else => undefined,
        },
        else => undefined,
    }
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .width = 400,
        .height = 300,
        .window_title = "Rendering",
        .icon = .{ .sokol_default = true, },
        .logger = .{ .func = slog.func, },
        .win32_console_attach = true,
    });
}

