SETLOCAL

SET CB_GCC_TOOLCHAIN=C:\Program Files\CodeBlocks\MinGW

SET CB_GCC_TOOL_GCC=mingw32-gcc.exe
SET CB_GCC_TOOL_GXX=mingw32-g++.exe
SET CB_GCC_TOOL_LD=mingw32-g++.exe

SET PATH=%CB_GCC_TOOLCHAIN%\bin;%PATH%

if not exist "bin"            mkdir bin
if not exist "bin\DebugWin32" mkdir bin\DebugWin32
if not exist "obj\DebugWin32" mkdir obj
if not exist "obj\DebugWin32" mkdir obj\DebugWin32

%CB_GCC_TOOL_GCC% -Wall -fexceptions -g -c main.c -o obj\DebugWin32\main.o
%CB_GCC_TOOL_GXX%  -o bin\DebugWin32\HelloWorld.exe obj\DebugWin32\main.o

bin\DebugWin32\HelloWorld.exe

PAUSE
