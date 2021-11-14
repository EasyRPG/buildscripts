# Windows buildscript

This repo provides build files to compile the libs used by the EasyRPG project
for Windows (Visual Studio compiler) easily.

## Requirements

Any version of Visual Studio 2019 or newer.

## How to compile

 - For EasyRPG Player: Run build.cmd
 - For EasyRPG Editor: Run build_qt5.cmd

This bootstraps vcpkg and builds all required libraries.

Please note that this can take a long time.

## Precompiled libraries

Instead of compiling you can obtain [precompiled libraries from our CI system].

## After compiling (or extracting the precompiled onces)

Use vcpkg in combination with CMake.

When CMake is not detected open a Visual Studio command prompt beforehand.

For 32bit:

    cmake . -A Win32 -B build-win32^
      -DVCPKG_TARGET_TRIPLET=x86-windows-static^
      -DCMAKE_TOOLCHAIN_FILE=[VCPKG_PATH]\scripts\buildsystems\vcpkg.cmake^
      -DCMAKE_BUILD_TYPE=[BUILD_TYPE]

For 64bit:

    cmake . -A x64 -B build-x64^
      -DVCPKG_TARGET_TRIPLET=x64-windows-static^
      -DCMAKE_TOOLCHAIN_FILE=[VCPKG_PATH]\scripts\buildsystems\vcpkg.cmake^
      -DCMAKE_BUILD_TYPE=[BUILD_TYPE]

Replace ``[VCPKG_PATH]`` with the path to vcpkg (you find in this folder) and
``[BUILD_TYPE]`` with ``Debug``, ``Release`` or ``RelWithDebInfo``. This is
even needed when generating Visual Studio Projects, otherwise the wrong library
versions are selected because not all have a debug suffix.

The Visual Studio project files are in ``build-win32`` and ``build-win64``.

[precompiled libraries from our CI system]: https://ci.easyrpg.org/view/Toolchains/job/toolchain-windows
