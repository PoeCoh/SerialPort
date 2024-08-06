const std = @import("std");
const SerialPort = @import("SerialPort.zig");

// Using com0com to loopback serial ports on windows.

test "loopback" {
    var sp1 = try SerialPort.init("COM100", .{
        .baud_rate = 115200,
        .data_bits = .CS8,
        .parity = .none,
        .stop_bits = .one,
        .flow_control = .none,
        .timeout = 1000,
    });
    defer sp1.deinit();
    var sp2 = try SerialPort.init("COM101", .{
        .baud_rate = 115200,
        .data_bits = .CS8,
        .parity = .none,
        .stop_bits = .one,
        .flow_control = .none,
        .timeout = 1000,
    });
    defer sp2.deinit();
    var hello = std.mem.zeroes([100:0]u8);
    std.mem.copyForwards(u8, &hello, "Hello World!");
    var buffer = std.mem.zeroes([100:0]u8);
    try sp1.flush(.input);
    try sp2.flush(.output);
    try sp1.writeAll(&hello);
    _ = try sp2.read(&buffer);
    try std.testing.expectEqualStrings(&hello, &buffer);
}

test "input flush" {
    var sp1 = try SerialPort.init("COM100", .{
        .baud_rate = 115200,
        .data_bits = .CS8,
        .parity = .none,
        .stop_bits = .one,
        .flow_control = .none,
        .timeout = 1000,
    });
    defer sp1.deinit();
    var sp2 = try SerialPort.init("COM101", .{
        .baud_rate = 115200,
        .data_bits = .CS8,
        .parity = .none,
        .stop_bits = .one,
        .flow_control = .none,
        .timeout = 1000,
    });
    defer sp2.deinit();
    var hello = std.mem.zeroes([100:0]u8);
    var buffer = std.mem.zeroes([100:0]u8);
    try sp1.writeAll("Hello World!");
    try sp2.flush(.input);
    _ = try sp2.read(&buffer);
    try std.testing.expectEqualStrings(&hello, &buffer);
}

test "output flush" {
    // need to figure out how to write and not hang. maybe set p2 input buffer to zero?
    var sp1 = try SerialPort.init("COM100", .{
        .baud_rate = 115200,
        .data_bits = .CS8,
        .parity = .none,
        .stop_bits = .one,
        .flow_control = .none,
        .timeout = 1000,
    });
    defer sp1.deinit();
    var hello = std.mem.zeroes([100:0]u8);
    var buffer = std.mem.zeroes([100:0]u8);
    _ = try sp1.write("Hello World!");
    // try sp1.flush(.output);
    var sp2 = try SerialPort.init("COM101", .{
        .baud_rate = 115200,
        .data_bits = .CS8,
        .parity = .none,
        .stop_bits = .one,
        .flow_control = .none,
        .timeout = 1000,
    });
    defer sp2.deinit();
    _ = try sp2.read(&buffer);
    try std.testing.expectEqualStrings(&hello, &buffer);
}

test "stats" {
    var sp1 = try SerialPort.init("COM100", .{
        .baud_rate = 115200,
        .data_bits = .CS8,
        .parity = .none,
        .stop_bits = .one,
        .flow_control = .none,
        .timeout = 1000,
    });
    defer sp1.deinit();
    var sp2 = try SerialPort.init("COM101", .{
        .baud_rate = 115200,
        .data_bits = .CS8,
        .parity = .none,
        .stop_bits = .one,
        .flow_control = .none,
        .timeout = 1000,
    });
    defer sp2.deinit();
    try sp1.writeAll("Hello World!");
    const stats = try sp2.stat();
    std.debug.print("Stats: {any}\n", .{stats});
}