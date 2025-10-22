# EasyRPG buildscripts

## Nintendo 3DS Toolchain and libraries

### Prequisites:

- Install devkitARM, libctru, citro3d, citro2d, tex3ds, 3dstools and 3ds-cmake.
  (Environment variables `DEVKITPRO` and `DEVKITARM` need to be set)

### Local build process:

- Run `0_build_everything.sh` in a terminal

## Developer's notes

The 3DS supports:
- ✘ ARM NEON intrinsiscs
- ✘ TLS (thread local storage)
- ✔ floating point hardware (albeit slow)
- ✔ mediocre CPU performance and memory size

These often need to be patched in or out of the libraries.