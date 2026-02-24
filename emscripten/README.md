# EasyRPG buildscripts

## Building EasyRPG player with emscripten

In this repo:
- Run `0_build_everything.sh` to build all the necessary dependencies.
    - Set the environment variable `BUILD_LIBLCF` to `1` to also build `liblcf`.
- An `emsdk_portable` directory should have been created. Run `emsdk_env.sh` in it to add `emsdk` to the path.
- Run `emsdk activate`.

In the player repo:
- In `builds/cmake/CMakePresetsUser.json`, set `EASYRPG_BUILDSCRIPTS` to the path to the buildscripts repo.
- Run `emcmake cmake --preset=emscripten-release .` to configure the build.
    - By default, the resulting file is called `easyrpg-player.html`. To name it `index.html` instead, use the `-DPLAYER_JS_OUTPUT_NAME=index` option.
- Run `emcmake cmake --build --preset=emscripten-release`.
- The resulting html, js and wasm files should be in `build/emscripten-release`. Copy them to their own directory and place any games inside a `games/` subdir.
