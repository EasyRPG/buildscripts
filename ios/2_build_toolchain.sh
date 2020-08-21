#!/bin/bash

if [ "$(uname)" != "Darwin" ]; then
	echo "This buildscript requires macOS!"
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

	# Fix ogg build
	# Remove this when the next version is out
	(cd $LIBOGG_DIR
		patch -Np1 < $SCRIPT_DIR/libogg-fix-typedefs.patch
	)

	cp -r icu icu-native

	touch .patches-applied
fi

function set_build_flags {
	CLANG=`xcodebuild -find clang`
	CLANGXX=`xcodebuild -find clang++`
	SDKPATH=`xcrun -sdk iphoneos --show-sdk-path`
	ARCH="-arch armv7 -arch arm64"

	export CC="$CLANG $ARCH"
	export CXX="$CLANGXX $ARCH"
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $CC"
		export CXX="ccache $CXX"
	fi
	export CPP="$CLANG -arch armv7 -E -isysroot $SDKPATH"
	export CXXCPP="$CLANGXX -arch armv7 -E -isysroot $SDKPATH"

	export CFLAGS="-g -O2 -miphoneos-version-min=7.0 -isysroot $SDKPATH -fobjc-arc"
	export CXXFLAGS=$CFLAGS
	export CPPFLAGS="-I$PLATFORM_PREFIX/include"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib $ARCH -miphoneos-version-min=7.0 -isysroot $SDKPATH"
}

export WORKSPACE=$PWD

export PLATFORM_PREFIX=$WORKSPACE
export TARGET_HOST=arm-apple-darwin
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
export MAKEFLAGS="-j${nproc:-2}"

function install_lib_sdl2() {
	msg "Building SDL2"

	(cd $SDL2_DIR
		./configure --host=$TARGET_HOST --prefix=$WORKSPACE \
			--disable-shared --enable-static
		cp include/SDL_config_iphoneos.h include/SDL_config.h
		make clean
		make
		make install
	)
}

install_lib_icu_native

set_build_flags

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
install_lib_cmake $FMT_DIR $FMT_ARGS
install_lib_icu_cross

install_lib_sdl2
