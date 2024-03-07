#!/bin/bash

if [ "$(uname)" != "Darwin" ]; then
	echo "This buildscript requires macOS!"
	exit 1
fi

# abort on error
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

if [ ! -d "icu-native" ]; then
	msg "Copying icu to icu-native"
	cp -r icu icu-native
fi

CMAKE_SYSTEM_NAME="iOS"
export WORKSPACE=$PWD

# Number of CPU
nproc=$(getconf _NPROCESSORS_ONLN)

# Use ccache?
test_ccache

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	# Fix inih
	# Remove when r58 is out
	(cd $INIH_DIR
		patch -Np1 < $SCRIPT_DIR/inih-std11.patch
	)
	# Fix SDL2 for iOS
	(cd $SDL2_DIR
		patch -Np1 < $SCRIPT_DIR/SDL2-iOS.patch
	)

	touch .patches-applied
fi

function set_build_flags() {
	if [ ! -d $1 ]; then
		mkdir $1
	fi
	export PLATFORM_PREFIX=$WORKSPACE/$1
	export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
	export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
	CLANG=`xcodebuild -find clang`
	CLANGXX=`xcodebuild -find clang++`
	SDKPATH=`xcrun -sdk iphoneos --show-sdk-path`
	ARCH="-arch $1"

	export CC="$CLANG $ARCH"
	export CXX="$CLANGXX $ARCH"
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $CC"
		export CXX="ccache $CXX"
	fi
	export CPP="$CLANG $ARCH -E -isysroot $SDKPATH"
	export CXXCPP="$CLANGXX $ARCH -E -isysroot $SDKPATH"

	export CFLAGS="-g -O2 -miphoneos-version-min=7.0 -isysroot $SDKPATH -fobjc-arc"
	export CXXFLAGS=$CFLAGS
	export CPPFLAGS="-I$PLATFORM_PREFIX/include"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib $ARCH -miphoneos-version-min=7.0 -isysroot $SDKPATH"
}

export TARGET_HOST=arm-apple-darwin
export MAKEFLAGS="-j${nproc:-2}"

function install_lib_sdl2() {
	msg "Building SDL2"

	(cd $SDL2_DIR
		./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX \
			--disable-shared --enable-static
		cp include/SDL_config_iphoneos.h include/SDL_config.h
		make clean
		make
		make install
	)
}

function build() {
	# Add some arguments to FreeType and Harfbuzz to fix library missing errors
	HB_FREETYPE_ARGS="-DFREETYPE_LIBRARY=$PLATFORM_PREFIX/lib/libfreetype.a -DFREETYPE_INCLUDE_DIRS=$PLATFORM_PREFIX/include/freetype2"
	FT_LIBPNG_ARGS="-DPNG_LIBRARY=$PLATFORM_PREFIX/lib/libpng16.a -DPNG_PNG_INCLUDE_DIR=$PLATFORM_PREFIX/include/libpng16"

	install_lib_zlib
	install_lib $LIBPNG_DIR $LIBPNG_ARGS
	install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS $FT_LIBPNG_ARGS -DFT_DISABLE_HARFBUZZ=ON
	install_lib_cmake $HARFBUZZ_DIR $HARFBUZZ_ARGS $HB_FREETYPE_ARGS
	install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS $FT_LIBPNG_ARGS -DFT_DISABLE_HARFBUZZ=OFF
	install_lib $PIXMAN_DIR $PIXMAN_ARGS --disable-arm-a64-neon --disable-arm-neon
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
	install_lib_cmake $FLUIDLITE_DIR $FLUIDLITE_ARGS -DENABLE_SF3=ON
	install_lib_meson $INIH_DIR $INIH_ARGS
	install_lib $LHASA_DIR $LHASA_ARGS
	install_lib_cmake $FMT_DIR $FMT_ARGS
	install_lib_icu_cross
	install_lib_liblcf
	install_lib_sdl2
}

install_lib_icu_native

set_build_flags "armv7"
build
set_build_flags "arm64"
build
