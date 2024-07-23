const std = @import("std");
const SerialPort = @import("SerialPort.zig");

test "loopback" {
    var sp1 = try SerialPort.init("COM100", .{
        .baud_rate = 115200,
        .data_bits = .CS8,
        .parity = .none,
        .stop_bits = .one,
        .flow_control = .none,
        .timeout = 100,
    });
    defer sp1.deinit();
    var sp2 = try SerialPort.init("COM101", .{
        .baud_rate = 115200,
        .data_bits = .CS8,
        .parity = .none,
        .stop_bits = .one,
        .flow_control = .none,
        .timeout = 100,
    });
    defer sp2.deinit();

    try sp1.writeAll("Hello World!\n");
    std.debug.print("Sent: Hello World!\n", .{});
    var buffer = [_]u8{0} ** 5;
    _ = try sp2.readAll(&buffer);
    std.debug.print("Received: {s}\n", .{buffer});
}