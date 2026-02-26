# Emscripten buildscript

This repository provides build files to easily compile the libraries used by
the EasyRPG project for emscripten (web).

## Requirements

Only Linux and macOS are supported. On Windows, consider using WSL2 (install
Ubuntu through the Windows Store).

## In this repository

To build `liblcf` as part of the buildscripts, set the environment variable
`BUILD_LIBLCF` to `1`:

```
export BUILD_LIBLCF=1
```

Run `0_build_everything.sh` to obtain all the necessary dependencies:

```
./0_build_everything.sh
```

Building will take a while.

## In the Player repository

### Configuring

**Option 1**: In `builds/cmake/CMakePresetsUser.json`, set
`EASYRPG_BUILDSCRIPTS` to the path of the buildscripts repository.

**Option 2**: Set the environment variable `EASYRPG_BUILDSCRIPTS` to the path
of the buildscripts repository:

```
export EASYRPG_BUILDSCRIPTS=/path/to/buildscripts
```

To configure the Player, run:

```
cmake --preset emscripten-[BUILD_TYPE]
```

Options for ``[BUILD_TYPE]``:

- `debug`: Debug build
- `relwithdebinfo`: Release build with debug symbols
- `release`: Release build without debug symbols (recommended)

Other useful options:

- `-DPLAYER_BUILD_LIBLCF=ON`: Builds `liblcf` if you haven't compiled it as
part of the buildscripts
- `-DPLAYER_JS_OUTPUT_NAME=index`: By default, the resulting file is called
`easyrpg-player.html`. This option names it `index.html`.

### Building

To build the Player run:

```
cmake --build --preset=[PRESET]
```

`[PRESET]` should match the value used after `--preset` in the configure step.

The resulting HTML, JS, and WASM files will be located in `build/[PRESET]`.

Copy them to their own directory and place any games inside a `games/` subdirectory.

### Deployment

For further information, read our [web player set up guide].

[web player set up guide]: https://easyrpg.org/player/guide/webplayer/

