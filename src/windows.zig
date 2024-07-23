const std = @import("std");
const DWORD = std.os.windows.DWORD;
const LPCSTR = std.os.windows.LPCSTR;
const LPDCB = std.os.windows.LPDCB;
const BOOL = std.os.windows.BOOL;
const WORD = std.os.windows.WORD;
const BYTE = std.os.windows.BYTE;
const HANDLE = std.os.windows.HANDLE;
const WINAPI = std.os.windows.WINAPI;


pub const DCB = extern struct {
    DCBlength: DWORD,
    BaudRate: DWORD,
    flags: DWORD,
    wReserved: WORD,
    XonLim: WORD,
    XoffLim: WORD,
    ByteSize: BYTE,
    Parity: BYTE,
    StopBits: BYTE,
    XonChar: u8,
    XoffChar: u8,
    ErrorChar: u8,
    EofChar: u8,
    EvtChar: u8,
    wReserved1: WORD,
};

pub const CommTimeouts = extern struct {
    ReadIntervalTimeout: DWORD,
    ReadTotalTimeoutMultiplier: DWORD,
    ReadTotalTimeoutConstant: DWORD,
    WriteTotalTimeoutMultiplier: DWORD,
    WriteTotalTimeoutConstant: DWORD,
};

pub extern "kernel32" fn BuildCommDCBA(in_lpDef: LPCSTR, out_lpDCB: *DCB) callconv (WINAPI) BOOL;
pub extern "kernel32" fn BuildCommDCBAndTimeoutsA(in_lpDef: LPCSTR, out_lpDCB: *DCB, out_lpCommTimeouts: *CommTimeouts) callconv(WINAPI) BOOL;
pub extern "kernel32" fn SetCommState(in_hFile: HANDLE, in_lpDCB: *DCB) callconv(WINAPI) BOOL;
pub extern "kernel32" fn SetCommTimeouts(in_hFile: HANDLE, in_lpCommTimeouts: *CommTimeouts) callconv(WINAPI) BOOL;
pub extern "kernel32" fn PurgeComm(in_hFile: HANDLE, in_dwFlags: DWORD) callconv(WINAPI) BOOL;
pub extern "kernel32" fn EscapeCommFunction(in_hFile: HANDLE, in_dwFunc: DWORD) callconv(WINAPI) BOOL;
