#!/bin/bash

# abort on error
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

# Number of CPU
nproc=$(nproc)

# Use ccache?
test_ccache

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	touch .patches-applied
fi

cd $WORKSPACE

echo "Preparing toolchain"

export PLATFORM_PREFIX=$WORKSPACE

export CFLAGS="-Os -g0 -fPIC -ffunction-sections -fdata-sections"
export CXXFLAGS=$CFLAGS
export CPPFLAGS="-I$PLATFORM_PREFIX/include"
export LDFLAGS="-fPIC -L$PLATFORM_PREFIX/lib"
export MAKEFLAGS="-j${nproc:-2}"
export PKG_CONFIG_PATH=$WORKSPACE/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
if [ "$ENABLE_CCACHE" ]; then
	export CC="ccache gcc"
	export CXX="ccache g++"
fi

install_lib_zlib
install_lib $LIBPNG_DIR $LIBPNG_ARGS
install_lib $FREETYPE_DIR $FREETYPE_ARGS --without-harfbuzz
install_lib $HARFBUZZ_DIR $HARFBUZZ_ARGS
install_lib $FREETYPE_DIR $FREETYPE_ARGS --with-harfbuzz
install_lib $PIXMAN_DIR $PIXMAN_ARGS
install_lib_cmake $EXPAT_DIR $EXPAT_ARGS
install_lib $LIBOGG_DIR $LIBOGG_ARGS
install_lib $LIBVORBIS_DIR $LIBVORBIS_ARGS
install_lib_mpg123
install_lib $LIBSNDFILE_DIR $LIBSNDFILE_ARGS
install_lib_cmake $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS
install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS
install_lib $OPUS_DIR $OPUS_ARGS
install_lib $OPUSFILE_DIR $OPUSFILE_ARGS
install_lib_cmake $FLUIDLITE_DIR $FLUIDLITE_ARGS -DENABLE_SF3=ON
install_lib_cmake $NLOHMANNJSON_DIR $NLOHMANNJSON_ARGS
install_lib_cmake $FMT_DIR $FMT_ARGS
install_lib $ICU_DIR/source $ICU_ARGS
install_lib $SDL2_DIR $SDL2_ARGS PULSEAUDIO_CFLAGS=-Ixxxdir PULSEAUDIO_LIBS=-lxxxlib
install_lib $SDL2_MIXER_DIR $SDL2_MIXER_ARGS
install_lib $SDL2_IMAGE_DIR $SDL2_IMAGE_ARGS
