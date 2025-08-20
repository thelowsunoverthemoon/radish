:: By Grub4k

@echo off
setlocal enableDelayedExpansion

zig-x86_64-windows-0.14.1\zig version >nul 2>&1
if errorlevel 1 (
    call :download
)
call :compile
exit /b

:download
mkdir fmod ntdll >nul 2>&1
set "urls="

set "urls=!urls! -O https://ziglang.org/download/0.14.1/zig-x86_64-windows-0.14.1.zip"
set "urls=!urls! -O https://github.com/thelowsunoverthemoon/radish/raw/refs/heads/main/src/radish.c"
set "urls=!urls! -O https://github.com/thelowsunoverthemoon/radish/raw/refs/heads/main/bin/fmod.dll"

set "fmodBaseUrl=https://github.com/pohldaniel/OpenGL_Games/raw/0e357aa486148360ddc02a0be21ebd3f7bb91b28/30Robot/FMOD/include"
for %%A in (
    fmod.h
    fmod_common.h
    fmod_codec.h
    fmod_dsp.h
    fmod_dsp_effects.h
    fmod_errors.h
    fmod_output.h
) do set "urls=!urls! -o fmod/%%A %fmodBaseUrl%/%%A"

set "urls=!urls! -o ntdll/ntdll.h https://github.com/x64dbg/ScyllaHide/raw/refs/heads/master/3rdparty/ntdll/ntdll.h"

curl.exe -LZ !urls! || exit /b 1
tar xf zig-x86_64-windows-0.14.1.zip || exit /b 1
del zig-x86_64-windows-0.14.1.zip || exit /b 1

exit /b 0

:compile
zig-x86_64-windows-0.14.1\zig.exe cc -w -s -O2 -target x86_64-windows-gnu -Wno-incompatible-pointer-types -L. -lfmod -o radish.exe radish.c
exit /b
