# EasyRPG buildscripts

## Wii Toolchain and libraries

### Prequisites:

- Install devkitPPC, libogc, libfat-ogc, gamecube-tools, wii-sdl2 and wii-cmake.
  (Environment variables `DEVKITPRO` and `DEVKITPPC` need to be set)

### Local build process:

- Run `0_build_everything.sh` in a terminal

## Developer's notes

The Wii supports:
- ✘ VMX intrinsics
- ✘ TLS (thread local storage)
- ✔ floating point hardware (albeit slow)
- ✘ slow CPU performance and little memory size

These often need to be patched in or out of the libraries.