file: std.fs.File,

pub fn init(port_name: []const u8, config: Config) !SerialPort {
    var buffer: [std.fs.max_name_bytes:0]u8 = undefined;
    const name = try std.fmt.bufPrint(&buffer, "{s}{s}", .{
        switch (native_os) {
            .windows => "\\\\.\\",
            else => "/dev/",
        },
        port_name,
    });
    var file = try std.fs.cwd().openFile(name, .{ .mode = .read_write });
    errdefer file.close();
    try switch (native_os) {
        .windows => wConfigure(file, config),
        else => pConfigure(file, config),
    };
    return .{ .file = file };
}

pub fn deinit(self: *SerialPort) void {
    self.file.close();
}

pub fn flush(self: *SerialPort, buffers: Buffers) !void {
    const mode = @intFromEnum(buffers);
    const failed = switch (native_os) {
        .windows => 0 == windows.PurgeComm(self.file.handle, mode),
        .macos => 0 != termios.tcflush(self.file.handle, mode),
        else => 0 != std.os.linux.syscall3(.ioctl, @bitCast(@as(isize, self.file.handle)), 0x540B, mode),
    };
    if (failed) return error.FlushFailed;
}

pub fn controlPins(self: *SerialPort, pins: ControlPins) !void {
    switch (native_os) {
        .windows => {
            if (pins.dtr) |pin| {
                if (0 == windows.EscapeCommFunction(self.file.handle, if (pin) 5 else 6))
                    return error.ControlPinsFailed;
            }
            if (pins.rts) |pin| {
                if (0 == windows.EscapeCommFunction(self.file.handle, if (pin) 3 else 4))
                    return error.ControlPinsFailed;
            }
        },
        .macos => @panic("Not implemented for macOS"),
        else => {
            var flags: c_int = 0;
            if (pins.dtr) |pin| {
                if (pin) flags |= 0x002 else flags &= ~0x002;
            }
            if (pins.rts) |pin| {
                if (pin) flags |= 0x004 else flags &= ~0x004;
            }
            if (0 != std.os.linux.ioctl(self.file.handle, 0x5418, @intFromPtr(&flags)))
                return error.ControlPinsFailed;
        },
    }
}

pub fn write(self: *SerialPort, bytes: []const u8) !usize {
    return self.file.write(bytes);
}

pub fn writeAll(self: *SerialPort, bytes: []const u8) !void {
    return self.file.writeAll(bytes);
}

pub fn writer(self: *SerialPort) std.fs.File.Writer {
    return self.file.writer();
}

pub fn read(self: *SerialPort, buffer: []u8) !usize {
    return self.file.read(buffer);
}

pub fn readAll(self: *SerialPort, buffer: []u8) !usize {
    return self.file.readAll(buffer);
}

pub fn reader(self: *SerialPort) std.fs.File.Reader {
    return self.file.reader();
}

pub fn stat(self: *SerialPort) !std.fs.File.Stat {
    return self.file.stat();
}

const SerialPort = @This();
const std = @import("std");
const windows = @import("windows.zig");
const termios = @cImport(@cInclude("termios.h"));
const native_os = @import("builtin").os.tag;
const target_os = @import("builtin").target.os.tag;

const Config = struct {
    baud_rate: u32 = 115200,
    data_bits: DataBits = .CS8,
    parity: Parity = .none,
    stop_bits: StopBits = .one,
    flow_control: FlowControl = .none,
    timeout: ?u32 = null,
};

const DataBits = switch (native_os) {
    .windows => enum(u8) {
        CS5 = 5,
        CS6 = 6,
        CS7 = 7,
        CS8 = 8,
    },
    else => std.posix.CSIZE,
};

const Parity = enum {
    none,
    odd,
    even,
    mark,
    space,
};

const StopBits = enum {
    one,
    one_point_five,
    two,
};

const FlowControl = enum {
    none,
    software,
    hardware,
};

const Buffers = switch (native_os) {
    .windows => enum(u32) {
        input = 0x0004,
        output = 0x0008,
        both = 0x000C,
    },
    .macos => enum(usize) {
        input = 1,
        output = 2,
        both = 3,
    },
    else => enum(usize) {
        input = 0,
        output = 1,
        both = 2,
    },
};

const ControlPins = struct {
    dtr: ?bool = null,
    rts: ?bool = null,
};

fn wConfigure(file: std.fs.File, config: Config) !void {
    var buffer = [_]u8{0} ** 100;
    var fbs = std.io.fixedBufferStream(&buffer);
    const fbs_writer = fbs.writer();
    try fbs_writer.print("baud={d} data={d}", .{ config.baud_rate, @intFromEnum(config.data_bits) });
    try fbs_writer.print(" parity={s}", .{@tagName(config.parity)[0..1]});
    try fbs_writer.print(" stop={s}", .{switch (config.stop_bits) {
        .one => "1",
        .one_point_five => "1.5",
        .two => "2",
    }});
    // Specifies whether infinite time-out processing is on or off. The default is off.
    try fbs_writer.print(" to={s}", .{"on"});
    // Specifies whether the xon or xoff protocol for data-flow control is on or off.
    try fbs_writer.print(" xon={s}", .{
        if (config.flow_control == .hardware) "on" else "off",
    });
    // Specifies whether output handshaking that uses the Data Set Ready (DSR) circuit is on or off.
    try fbs_writer.print(" odsr={s}", .{"on"});
    // Specifies whether output handshaking that uses the Clear To Send (CTS) circuit is on or off.
    try fbs_writer.print(" octs={s}", .{"on"});
    // Specifies whether the Data Terminal Ready (DTR) circuit is on or off or set to handshake. (on|off|hs)
    // try fbs_writer.print(" dtr={s}", .{"on"});
    // Specifies whether the Request To Send (RTS) circuit is set to on, off, handshake, or toggle. (on|off|hs|tg)
    // try fbs_writer.print(" rts={s}", .{"on"});
    // Specifies whether the DSR circuit sensitivity is on or off.
    try fbs_writer.print(" idsr={s}", .{"on"});
    var dcb = std.mem.zeroes(windows.DCB);
    var comm_timeouts = std.mem.zeroes(windows.CommTimeouts);
    std.debug.print("{s}\n", .{fbs.getWritten()});
    if (0 == windows.BuildCommDCBAndTimeoutsA(@ptrCast(fbs.getWritten()), &dcb, &comm_timeouts)) {
        std.debug.print("BuildCommDCBAndTimeoutsA: {d}\n", .{std.os.windows.GetLastError()});
        return error.ConfigurationFailed;
    }
    dcb.XonChar = 0x11;
    dcb.XoffChar = 0x13;
    dcb.EofChar = 0x04;
    std.debug.print("{any}\n", .{dcb});

    if (0 == windows.SetCommState(file.handle, &dcb)) {
        std.debug.print("SetCommState: {d}\n", .{std.os.windows.GetLastError()});
        return error.ConfigurationFailed;
    }
    if (null == config.timeout) return;

    std.debug.print("{any}\n", .{comm_timeouts});
    if (0 == windows.SetCommTimeouts(file.handle, &comm_timeouts)) {
        std.debug.print("SetCommTimeouts: {d}\n", .{std.os.windows.GetLastError()});
        return error.ConfigurationFailed;
    }
}

fn pConfigure(file: std.fs.File, config: Config) !void {
    var settings = try std.posix.tcgetattr(file.handle);
    settings.iflag = .{};
    settings.oflag = .{};
    settings.cflag = .{ .CREAD = true };
    settings.lflag = .{};
    settings.ispeed = config.baud_rate;
    settings.ospeed = config.baud_rate;
    settings.cflag.PARODD = config.parity == .odd or config.parity == .mark;
    if (config.parity == .mark) settings.cflag._ |= 1 << 14;
    if (config.parity == .space) settings.cflag._ |= 1;
    settings.iflag.INPCK = config.parity != .none;
    settings.cflag.PARENB = config.parity != .none;
    settings.cflag.CLOCAL = config.flow_control == .none;
    settings.iflag.IXON = config.flow_control == .software;
    settings.iflag.IXOFF = config.flow_control == .software;
    if (config.flow_control == .hardware) settings.cflag._ |= 1 << 15;
    settings.cflag.CSTOPB = config.stop_bits == .two;
    settings.cflag.CSIZE = config.data_bits;

    // timeouts
    settings.cc[5] = 0; // VTIME
    settings.cc[6] = 1; // VMIN
    settings.cc[8] = 0x11; // VSTART
    settings.cc[9] = 0x13; // VSTOP
    try std.posix.tcsetattr(file.handle, .NOW, settings);
}
