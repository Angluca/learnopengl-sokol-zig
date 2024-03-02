const std = @import("std");
const builtin = @import("builtin");
const Build = std.Build;
const ResolvedTarget = std.Build.ResolvedTarget;
const OptimizeMode = std.builtin.OptimizeMode;
const Dependency = std.Build.Dependency;

var target: ResolvedTarget = undefined;
var optimize: OptimizeMode = undefined;
var dep_sokol: *Dependency = undefined;

const sokol_tools_bin_dir = "../sokol-tools-bin/bin/";
const examples = .{
    // 0:dir, 1:names, 2:shaders_idx_or_name, 3:libs_idx:0~n
    .{"1-3-hello-window", .{"rendering"}, .{}, .{}},
    .{"1-4-hello-triangle", .{"triangle", "quad", "quad-wireframe"}, .{"quad", 2}, .{}},
    .{"1-5-shaders", .{"in-out", "uniforms", "attributes"}, .{0, 1, 2}, .{}},
};

const libs_dir = "libs";
const libs = .{
    // dir, name
    .{"", ""}, // 0
};

pub fn build(b: *Build) !void {
    target = b.standardTargetOptions(.{});
    optimize = b.standardOptimizeOption(.{});
    dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });
    inline for(examples)|e| {
        const dir = e[0];
        const names = e[1];
        const shaders = e[2];
        const libs_idx = e[3];
        const cur_dir = "examples/" ++ dir ++ "/";

        inline for(names)|name| {
            const exe = BuildExample(b, cur_dir, name);
            exe.addIncludePath(.{.path = "libs",});
            inline for(libs_idx)|idx| {
                if(idx < 1 or idx > libs.len - 1) continue;
                const lib = libs[idx];
                exe.addCSourceFile(.{
                    .file = .{ .path = libs_dir ++ "/" ++ lib[0] ++ "/" ++ lib[1] },
                    .flags = &.{
                        "-std=c99", "-fno-sanitize=undefined",
                        "-g", "-O3",
                    },
                });
            }
            exe.linkLibC();
        }
        inline for(shaders)|idx_or_name| {
            if(@TypeOf(idx_or_name) == comptime_int) {
                if(idx_or_name >= names.len or idx_or_name < 0) continue;
                buildShaders(b, cur_dir, names[idx_or_name]); // idx
            } else  {
                buildShaders(b, cur_dir, idx_or_name); // name
            }
        }
    }
}

fn BuildExample(b: *Build, comptime dir: []const u8, comptime name: []const u8) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = name,
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = dir ++ "/" ++ name ++ ".zig" },
    });
    exe.root_module.addImport("sokol", dep_sokol.module("sokol"));
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    b.step(name, "Run example " ++ name).dependOn(&run_cmd.step);
    return exe;
}

var shdc_step: ?*std.Build.Step = null;
const optional_shdc: ?[:0]const u8 = switch (builtin.os.tag) {
    .windows => "win32/sokol-shdc.exe",
    .linux => "linux/sokol-shdc",
    .macos => if (builtin.cpu.arch.isX86()) "osx/sokol-shdc" else "osx_arm64/sokol-shdc",
    else => null,
};
fn buildShaders(b: *Build, comptime dir: []const u8, comptime name: []const u8) void {
    const shdc_path = sokol_tools_bin_dir ++ optional_shdc.?;
    if(shdc_step == null) {
        shdc_step = b.step("shaders", "Compile shaders (needs " ++ sokol_tools_bin_dir ++ ")");
    }
    const shdc_one_step = b.step("shaders-" ++ name, "Compile shaders (needs " ++ sokol_tools_bin_dir ++ ")");
    const cmd = b.addSystemCommand(&.{
        shdc_path,
        "-i", dir ++ "/" ++ name ++ ".glsl",
        "-o", dir ++ "/" ++ name ++ ".glsl.zig",
        "-l", "glsl330:metal_macos:hlsl4:glsl300es:wgsl",
        "-f", "sokol_zig",
    });
    shdc_step.?.dependOn(&cmd.step);
    shdc_one_step.dependOn(&cmd.step);
}

