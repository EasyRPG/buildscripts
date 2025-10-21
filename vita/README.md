# EasyRPG buildscripts

## PSVita Toolchain and libraries

Local build process:

Run `0_build_everything.sh` in a terminal

Note: Since we overwrite some libraries from vitasdk with newer versions,
we use our own local installation. This means you need to redefine `$VITASDK`
when targetting our builds.

## Developer's notes

The switch supports:
- ✔ ARM NEON intrinsiscs
- ✔ floating point hardware
- ✘ problematic file access (slow, partly unsupported posix stuff)

These often need to be patched in or out of the libraries.