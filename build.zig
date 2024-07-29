const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("SimpleFile", .{
        .root_source_file = .{ .path = "src/SerialPort.zig" },
        .target = target,
        .optimize = optimize,
    });
}
