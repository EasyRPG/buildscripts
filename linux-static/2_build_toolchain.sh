#!/bin/bash

# abort on error
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import

# Number of CPU
nproc=$(nproc)

# Use ccache?
test_ccache

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	# Wildmidi: Disable libm
	perl -pi -e 's/FIND_LIBRARY\(M_LIBRARY m REQUIRED\)//' wildmidi-wildmidi-0.4.1/CMakeLists.txt

	touch .patches-applied
fi

cd $WORKSPACE

echo "Preparing toolchain"

export CFLAGS="-Os -g0 -ffunction-sections -fdata-sections"
export CXXFLAGS=$CFLAGS
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
install_lib $MPG123_DIR $MPG123_ARGS
install_lib $LIBSNDFILE_DIR $LIBSNDFILE_ARGS
install_lib $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS
install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS
install_lib $OPUS_DIR $OPUS_ARGS
install_lib $OPUSFILE_DIR $OPUSFILE_ARGS
install_lib $ICU_DIR/source $ICU_ARGS
install_lib $SDL2_DIR $SDL2_ARGS
install_lib $SDL2_MIXER_DIR $SDL2_MIXER_ARGS
install_lib $SDL2_IMAGE_DIR $SDL2_IMAGE_ARGS

# allows minimal Player build with xmplite version, while using the full version otherwise
mv $WORKSPACE/lib/pkgconfig/libxmp-lite.pc $WORKSPACE/lib/pkgconfig/libxmp.pc
