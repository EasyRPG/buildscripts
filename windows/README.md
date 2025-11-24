# Windows buildscript

This repo provides build files to compile the libs used by the EasyRPG project
for Windows (Visual Studio compiler) easily.

## Requirements

The latest version of Visual Studio 2022.

The ARM architecture is not supported.

## Compiling

 - For EasyRPG Player: Run `build.cmd`
 - For EasyRPG Editor: Run `download_qt6.cmd` and `build_editor.cmd` 

This bootstraps vcpkg and builds all required libraries.

The first time you run the build it will take about 30 minutes to complete.

## Prebuilt libraries

If you do not want to build the libraries yourself, you can download a
prebuilt version. Run ``download_prebuilt.cmd`` to obtain them.

This precompiled version will only work on the latest version of Visual Studio
2022. If you are using a different version, please compile it yourself.

## Environment setup

Run ``setup_env.cmd`` once to configure the necessary environment variables.

Then log out of Windows to ensure that the changes take effect.

## Compile instructions for EasyRPG Player

### Configuring

Open the "Developer Command Prompt for Visual Studio 2022" from the Start menu
and navigate to your _EasyRPG Player_ directory.

To configure for a standalone Player run:

```
cmake --preset windows-[ARCH]-vs2022-[BUILD_TYPE]
```

To configure for a libretro core run:

```
cmake --preset windows-[ARCH]-vs2022-libretro-[BUILD_TYPE]
```

Options for ``[ARCH]``:

- ``x86``: Build for 32-bit architecture
- ``x64``: Build for 64-bit architecture

Options for ``[BUILD_TYPE]``:

- ``debug``: Debug build
- ``relwithdebinfo``: Release build with debug symbols
- ``release``: Release build without debug symbols

liblcf is not provided by the buildscript. Either compile it yourself or add
``-DPLAYER_BUILD_LIBLCF=ON`` to the CMake line to build it as part of the
Player.

### Building

Open the ``EasyRPG_Player.sln`` file created in ``build\[PRESET]`` in Visual
Studio (``[PRESET]`` is equal to the value after ``--preset`` above).

## Compile instructions for EasyRPG Editor

### Configuring

Open the "Developer Command Prompt for Visual Studio 2022" from the Start menu
and navigate to your _EasyRPG Editor_ directory.

To configure the editor run:

```
cmake --preset windows-x64-vs2022-[BUILD_TYPE]
```

liblcf is not provided by the buildscript. Either compile it yourself or use
the triplet `windows-x64-vs2022-liblcf-[BUILD_TYPE]` to build it as part of
the Editor.

Options for ``[BUILD_TYPE]``:

- ``debug``: Debug build
- ``relwithdebinfo``: Release build with debug symbols
- ``release``: Release build without debug symbols

### Building

Open the ``EasyRPG_Editor.sln`` file created in ``build\[PRESET]`` in Visual
Studio (``[PRESET]`` is equal to the value after ``--preset`` above).
