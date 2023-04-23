:: Builds the dependencies for EasyRPG Player

call helper\prepare.cmd

:: Build 32-bit libraries
:: Using [core] everywhere to prevent surprises when new default-features are
:: added to libraries.
vcpkg install --triplet x86-windows-static --recurse^
 libpng[core] expat[core] pixman[core] freetype[core,zlib] harfbuzz[core]^
 libvorbis[core] libsndfile[core] wildmidi[core] libxmp[core]^
 speexdsp[core] mpg123[core] opusfile[core] fluidsynth-easyrpg[core]^
 sdl2-image[core] icu-easyrpg[core] nlohmann-json[core] fmt[core]

:: Build 64-bit libraries
vcpkg install --triplet x64-windows-static --recurse^
 libpng[core] expat[core] pixman[core] freetype[core,zlib] harfbuzz[core]^
 libvorbis[core] libsndfile[core] wildmidi[core] libxmp[core]^
 speexdsp[core] mpg123[core] opusfile[core] fluidsynth-easyrpg[core]^
 sdl2-image[core] icu-easyrpg[core] nlohmann-json[core] fmt[core]
