# EasyRPG buildscripts

## Switch Toolchain and libraries

### Prequisites:

- Install devkitA64, libnx, switch-tools, switch-glad and switch-cmake.
  (Environment variables `DEVKITPRO` needs to be set)

### Local build process:

- Run `0_build_everything.sh` in a terminal

## Developer's notes

The switch supports:
- ✔ ARM NEON intrinsiscs
- ✔ TLS (thread local storage)
- ✔ PIC (position independent code)
- ✔ floating point hardware

These often need to be patched in or out of the libraries.