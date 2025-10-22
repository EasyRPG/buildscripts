# EasyRPG buildscripts

## WiiU Toolchain and libraries

### Prequisites:

- Install devkitPPC, wut, wut-tools, wiiu-cmake and wiiu-sdl2.
  (Environment variables `DEVKITPRO` and `DEVKITPPC` need to be set)

### Local build process:

- Run `0_build_everything.sh` in a terminal

## Developer's notes

The Wii U supports:
- ✘ VMX intrinsics
- ✘ TLS (thread local storage)
- ✔ floating point hardware (slow, but present)

These often need to be patched in or out of the libraries.