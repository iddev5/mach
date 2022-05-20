const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");
const glfw = @import("glfw");
const zm = @import("zmath");
const zigimg = @import("zigimg");
const Vertex = @import("cube_mesh.zig").Vertex;
const vertices = @import("cube_mesh.zig").vertices;

const UniformBufferObject = struct {
    mat: zm.Mat,
};

var timer: mach.Timer = undefined;

pipeline: gpu.RenderPipeline,
queue: gpu.Queue,
vertex_buffer: gpu.Buffer,
uniform_buffer: gpu.Buffer,
bind_group: gpu.BindGroup,
depth_texture: gpu.Texture,
depth_size: mach.Size,

const App = @This();

pub fn init(app: *App, engine: *mach.Engine) !void {
    timer = try mach.Timer.start();

    try engine.core.setSizeLimits(.{ .width = 20, .height = 20 }, .{ .width = null, .height = null });

    const vs_module = engine.gpu_driver.device.createShaderModule(&.{
        .label = "my vertex shader",
        .code = .{ .wgsl = @embedFile("vert.wgsl") },
    });

    const vertex_attributes = [_]gpu.VertexAttribute{
        .{ .format = .float32x4, .offset = @offsetOf(Vertex, "pos"), .shader_location = 0 },
        .{ .format = .float32x2, .offset = @offsetOf(Vertex, "uv"), .shader_location = 1 },
    };
    const vertex_buffer_layout = gpu.VertexBufferLayout{
        .array_stride = @sizeOf(Vertex),
        .step_mode = .vertex,
        .attribute_count = vertex_attributes.len,
        .attributes = &vertex_attributes,
    };

    const fs_module = engine.gpu_driver.device.createShaderModule(&.{
        .label = "my fragment shader",
        .code = .{ .wgsl = @embedFile("frag.wgsl") },
    });

    const blend = gpu.BlendState{
        .color = .{
            .operation = .add,
            .src_factor = .src_alpha,
            .dst_factor = .one_minus_src_alpha,
        },
        .alpha = .{
            .operation = .add,
            .src_factor = .one,
            .dst_factor = .zero,
        },
    };
    const color_target = gpu.ColorTargetState{
        .format = engine.gpu_driver.swap_chain_format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMask.all,
    };
    const fragment = gpu.FragmentState{
        .module = fs_module,
        .entry_point = "main",
        .targets = &.{color_target},
        .constants = null,
    };

    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        // Enable depth testing so that the fragment closest to the camera
        // is rendered in front.
        .depth_stencil = &.{
            .format = .depth24_plus,
            .depth_write_enabled = true,
            .depth_compare = .less,
        },
        .vertex = .{
            .module = vs_module,
            .entry_point = "main",
            .buffers = &.{vertex_buffer_layout},
        },
        .primitive = .{
            .topology = .triangle_list,

            // Backface culling since the cube is solid piece of geometry.
            // Faces pointing away from the camera will be occluded by faces
            // pointing toward the camera.
            .cull_mode = .back,
        },
    };
    const pipeline = engine.gpu_driver.device.createRenderPipeline(&pipeline_descriptor);

    const vertex_buffer = engine.gpu_driver.device.createBuffer(&.{
        .usage = .{ .vertex = true },
        .size = @sizeOf(Vertex) * vertices.len,
        .mapped_at_creation = true,
    });
    var vertex_mapped = vertex_buffer.getMappedRange(Vertex, 0, vertices.len);
    std.mem.copy(Vertex, vertex_mapped, vertices[0..]);
    vertex_buffer.unmap();

    // Create a sampler with linear filtering for smooth interpolation.
    const sampler = engine.gpu_driver.device.createSampler(&.{
        .mag_filter = .linear,
        .min_filter = .linear,
    });
    const queue = engine.gpu_driver.device.getQueue();
    const img = try zigimg.Image.fromFilePath(engine.allocator, "examples/assets/gotta-go-fast.png");
    const img_size = gpu.Extent3D{ .width = @intCast(u32, img.width), .height = @intCast(u32, img.height) };
    const cube_texture = engine.gpu_driver.device.createTexture(&.{
        .size = img_size,
        .format = .rgba8_unorm,
        .usage = .{
            .texture_binding = true,
            .copy_dst = true,
            .render_attachment = true,
        },
    });
    const data_layout = gpu.Texture.DataLayout{
        .bytes_per_row = @intCast(u32, img.width * 4),
        .rows_per_image = @intCast(u32, img.height),
    };
    switch (img.pixels.?) {
        .Rgba32 => |pixels| queue.writeTexture(&.{ .texture = cube_texture }, pixels, &data_layout, &img_size),
        .Rgb24 => |pixels| {
            const data = try rgb24ToRgba32(engine.allocator, pixels);
            //defer data.deinit(allocator);
            queue.writeTexture(&.{ .texture = cube_texture }, data.Rgba32, &data_layout, &img_size);
        },
        else => @panic("unsupported image color format"),
    }

    const uniform_buffer = engine.gpu_driver.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(UniformBufferObject),
        .mapped_at_creation = false,
    });

    const bind_group = engine.gpu_driver.device.createBindGroup(
        &gpu.BindGroup.Descriptor{
            .layout = pipeline.getBindGroupLayout(0),
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, uniform_buffer, 0, @sizeOf(UniformBufferObject)),
                gpu.BindGroup.Entry.sampler(1, sampler),
                gpu.BindGroup.Entry.textureView(2, cube_texture.createView(&gpu.TextureView.Descriptor{})),
            },
        },
    );

    const size = try engine.core.getFramebufferSize();
    const depth_texture = engine.gpu_driver.device.createTexture(&gpu.Texture.Descriptor{
        .size = gpu.Extent3D{
            .width = size.width,
            .height = size.height,
        },
        .format = .depth24_plus,
        .usage = .{
            .render_attachment = true,
            .texture_binding = true,
        },
    });

    app.pipeline = pipeline;
    app.queue = queue;
    app.vertex_buffer = vertex_buffer;
    app.uniform_buffer = uniform_buffer;
    app.bind_group = bind_group;
    app.depth_texture = depth_texture;
    app.depth_size = size;

    vs_module.release();
    fs_module.release();
}

pub fn deinit(app: *App, _: *mach.Engine) void {
    app.vertex_buffer.release();
    app.uniform_buffer.release();
    app.bind_group.release();
}

pub fn update(app: *App, engine: *mach.Engine) !bool {
    while (engine.core.pollEvent()) |event| {
        switch (event) {
            .key_press => |ev| {
                if (ev.key == .space)
                    engine.core.setShouldClose(true);
            },
            else => {},
        }
    }

    // If window is resized, recreate depth buffer otherwise we cannot use it.
    const size = engine.core.getFramebufferSize() catch unreachable; // TODO: return type inference can't handle this
    if (size.width != app.depth_size.width or size.height != app.depth_size.height) {
        app.depth_texture = engine.gpu_driver.device.createTexture(&gpu.Texture.Descriptor{
            .size = gpu.Extent3D{
                .width = size.width,
                .height = size.height,
            },
            .format = .depth24_plus,
            .usage = .{
                .render_attachment = true,
                .texture_binding = true,
            },
        });
        app.depth_size = size;
    }

    const back_buffer_view = engine.gpu_driver.swap_chain.?.getCurrentTextureView();
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .clear_value = .{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 0.0 },
        .load_op = .clear,
        .store_op = .store,
    };

    const encoder = engine.gpu_driver.device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassEncoder.Descriptor{
        .color_attachments = &.{color_attachment},
        .depth_stencil_attachment = &.{
            .view = app.depth_texture.createView(&gpu.TextureView.Descriptor{
                .format = .depth24_plus,
                .dimension = .dimension_2d,
                .array_layer_count = 1,
                .mip_level_count = 1,
            }),
            .depth_clear_value = 1.0,
            .depth_load_op = .clear,
            .depth_store_op = .store,
        },
    };

    {
        const time = timer.read();
        const model = zm.mul(zm.rotationX(time * (std.math.pi / 2.0)), zm.rotationZ(time * (std.math.pi / 2.0)));
        const view = zm.lookAtRh(
            zm.f32x4(0, 4, 2, 1),
            zm.f32x4(0, 0, 0, 1),
            zm.f32x4(0, 0, 1, 0),
        );
        const proj = zm.perspectiveFovRh(
            (std.math.pi / 4.0),
            @intToFloat(f32, engine.gpu_driver.current_desc.width) / @intToFloat(f32, engine.gpu_driver.current_desc.height),
            0.1,
            10,
        );
        const mvp = zm.mul(zm.mul(model, view), proj);
        const ubo = UniformBufferObject{
            .mat = zm.transpose(mvp),
        };
        encoder.writeBuffer(app.uniform_buffer, 0, UniformBufferObject, &.{ubo});
    }

    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(app.pipeline);
    pass.setVertexBuffer(0, app.vertex_buffer, 0, @sizeOf(Vertex) * vertices.len);
    pass.setBindGroup(0, app.bind_group, &.{});
    pass.draw(vertices.len, 1, 0, 0);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    app.queue.submit(&.{command});
    command.release();
    engine.gpu_driver.swap_chain.?.present();
    back_buffer_view.release();

    return true;
}

fn rgb24ToRgba32(allocator: std.mem.Allocator, in: []zigimg.color.Rgb24) !zigimg.color.ColorStorage {
    const out = try zigimg.color.ColorStorage.init(allocator, .Rgba32, in.len);
    var i: usize = 0;
    while (i < in.len) : (i += 1) {
        out.Rgba32[i] = zigimg.color.Rgba32{ .R = in[i].R, .G = in[i].G, .B = in[i].B, .A = 255 };
    }
    return out;
}
