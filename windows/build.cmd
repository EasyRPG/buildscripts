:: Builds the dependencies for EasyRPG Player

call helper\prepare.cmd

:: Install yasm (required for 64 bit mpg123 build)
vcpkg install --triplet x86-windows^
 yasm-tool[core]

:: Build 32-bit libraries
:: Using [core] everywhere to prevent surprises when new default-features are
:: added to libraries.
vcpkg install --triplet x86-windows-static --recurse^
 libpng[core] expat[core] pixman[core] freetype[core] harfbuzz[core]^
 libvorbis[core] libsndfile[core] wildmidi[core] libxmp-lite[core]^
 speexdsp[core] mpg123[core] opusfile[core] fluidlite[core]^
 sdl2-image[core] sdl2-mixer[core,nativemidi]^
 icu-easyrpg[core] nlohmann-json[core] fmt[core]

:: Build 64-bit libraries
vcpkg install --triplet x64-windows-static --recurse^
 libpng[core] expat[core] pixman[core] freetype[core] harfbuzz[core]^
 libvorbis[core] libsndfile[core] wildmidi[core] libxmp-lite[core]^
 speexdsp[core] mpg123[core] opusfile[core] fluidlite[core]^
 sdl2-image[core] sdl2-mixer[core,nativemidi]^
 icu-easyrpg[core] nlohmann-json[core] fmt[core]
