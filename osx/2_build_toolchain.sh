#!/bin/bash

if [ "$(uname)" != "Darwin" ]; then
	echo "This buildscript requires MacOSX"
	exit 1
fi

# abort on error
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

# Number of CPU
nproc=$(getconf _NPROCESSORS_ONLN)

# Use ccache?
test_ccache

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	# Disable SDL2 mixer examples
	pushd $SDL2_MIXER_DIR
	patch -Np1 < $SCRIPT_DIR/../shared/extra/sdl2_mixer_disable_examples.patch
	autoreconf -fi
	popd

	touch .patches-applied
fi

function set_build_flags {
	CLANG=`xcodebuild -find clang`
	CLANGXX=`xcodebuild -find clang++`
	ARCH="-arch i386 -arch x86_64"
	SDKPATH=`xcrun -sdk macosx10.12 --show-sdk-path`

	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $CLANG $ARCH"
		export CXX="ccache $CLANGXX $ARCH"
	else
		export CC="$CLANG $ARCH"
		export CXX="$CLANGXX $ARCH"
	fi

	export CPP="$CLANG -arch i386 -E"
	export CXXCPP="$CLANGXX -arch i386 -E"

	export CFLAGS="-g -O2 -mmacosx-version-min=10.9 -isysroot $SDKPATH"
	export CXXFLAGS=$CFLAGS
	export CPPFLAGS="-I$PLATFORM_PREFIX/include"

	export LDFLAGS="-L$PLATFORM_PREFIX/lib $ARCH -mmacosx-version-min=10.9 -isysroot $SDKPATH"
}

cd $WORKSPACE

export PLATFORM_PREFIX=$WORKSPACE
export PKG_CONFIG_PATH=$WORKSPACE/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
export MAKEFLAGS="-j${nproc:-2}"

set_build_flags

install_lib $ICU_DIR/source $ICU_ARGS

# Install libraries
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
install_lib_cmake $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS
install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS
install_lib $OPUS_DIR $OPUS_ARGS
install_lib $OPUSFILE_DIR $OPUSFILE_ARGS
install_lib $ICU_DIR/source $ICU_ARGS
install_lib $SDL2_DIR $SDL2_ARGS
install_lib $SDL2_MIXER_DIR $SDL2_MIXER_ARGS
