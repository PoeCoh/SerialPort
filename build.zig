const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("SerialPort", .{
        .root_source_file = b.pathFromRoot("src/SerialPort.zig"),
        .target = target,
        .optimize = optimize,
    });
}
