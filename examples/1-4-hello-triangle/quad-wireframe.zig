const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
//const slog = sokol.log;
const sapp = sokol.app;
const sgapp = sokol.app_gfx_glue;
const print = std.debug.print;

const glsl = @import("quad-wireframe.glsl.zig");

const state = struct {
    var pass_action: sg.PassAction = .{};
    var bind: sg.Bindings = .{};
    var pip: sg.Pipeline = .{};
};

export fn init() void {
    sg.setup(.{
        .context = sgapp.context(),
        //.logger = .{ .func = slog.func },
    });
    const vertices = [_]f32 {
        // positions
        0.5,  0.5, 0.0,      // top right
        0.5, -0.5, 0.0,      // bottom right
        -0.5, -0.5, 0.0,     // bottom left
        -0.5,  0.5, 0.0,     // top left
    };
    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&vertices),
    });
    // an index buffer with 2 triangles
    const indices = [_]u16 {
        0, 1, 1, 3, 3, 0,    // first triangle
        1, 2, 2, 3, 3, 1     // second triangle
    };
    state.bind.index_buffer = sg.makeBuffer(.{
        .type = .INDEXBUFFER,
        .data = sg.asRange(&indices),
    });
    // create shader from code-generated sg_shader_desc
    const shd = sg.makeShader(glsl.simpleShaderDesc(sg.queryBackend()));
    // create a pipeline object (default render states are fine for triangle)
    var pip_desc = sg.PipelineDesc {
        .shader = shd,
        .index_type = .UINT16,
        .primitive_type = .LINES,
    };
    pip_desc.layout.attrs[0].format = .FLOAT3;
    //pip_desc.layout.attrs[1].format = .FLOAT4;
    state.pip = sg.makePipeline(pip_desc);

    // a pass action to clear framebuffer
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.2, .g = 0.3, .b = 0.3, .a = 1 },
    };
    print("Backend: {}\n", .{sg.queryBackend()});
}

export fn frame() void {
    sg.beginDefaultPass(state.pass_action, sapp.width(), sapp.height());
    sg.applyPipeline(state.pip);
    sg.applyBindings(state.bind);
    sg.draw(0, 12, 1);
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
        .window_title = "Quad",
        .icon = .{ .sokol_default = true, },
        //.logger = .{ .func = slog.func, },
        .win32_console_attach = true,
    });
}

