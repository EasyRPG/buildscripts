# Windows buildscript

This repo provides build files to compile the libs used by the EasyRPG project
for Windows (Visual Studio compiler) easily.

## Requirements

Any version of Visual Studio 2015 Update 3 or newer.

## How to compile

Run build.cmd. This bootstraps vcpkg and builds all required libraries.

## After compiling

Use vcpkg in combination with CMake.

When not using the Visual Studio generator open a Visual Studio command prompt
beforehand.

For 32bit:

    cmake -DSHARED_RUNTIME=OFF -DVCPKG_TARGET_TRIPLET=x86-windows-static^
      -DCMAKE_TOOLCHAIN_FILE=[VCPKG_PATH]\scripts\buildsystems\vcpkg.cmake^
      -DCMAKE_BUILD_TYPE=[BUILD_TYPE]

For 64bit:

    cmake -DSHARED_RUNTIME=OFF -DVCPKG_TARGET_TRIPLET=x64-windows-static^
      -DCMAKE_TOOLCHAIN_FILE=[VCPKG_PATH]\scripts\buildsystems\vcpkg.cmake^
      -DCMAKE_BUILD_TYPE=[BUILD_TYPE]

Replace ``[VCPKG_PATH]`` with the path to vcpkg (you find in this folder) and
``[BUILD_TYPE]`` with Debug, Release or RelWithDebInfo. This is even needed
when generating Visual Studio Projects, otherwise the wrong library versions
are selected because not all have a debug suffix.

In case you used x86-windows or x64-windows change the triplet accordingly and
use ``SHARED_RUNTIME=ON``.
