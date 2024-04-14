#!/bin/bash

if [ "$(uname)" != "Darwin" ]; then
	errormsg "This buildscript requires macOS!"
fi

# abort on error
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

# Number of CPU
nproc=$(getconf _NPROCESSORS_ONLN)

test_ccache

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	cp -rp icu icu-native

	touch .patches-applied
fi

function set_build_flags {
	# $1: Arch (either armv7 or arm64)
	# $2: host for configure
	# $3: additional cpp flags
	CLANG="xcrun --sdk iphoneos clang"
	CLANGXX="xcrun --sdk iphoneos clang++"
	ARCH="-arch $1"
	SDKPATH=`xcrun -sdk iphoneos --show-sdk-path`
	PLATFORM_PREFIX="$WORKSPACE/$1"

	echo "Preparing for $1 arch"

	export PATH=$PLATFORM_PREFIX/bin:$PATH
	export CC="$CLANG $ARCH"
	export CXX="$CLANGXX $ARCH"
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $CC"
		export CXX="ccache $CXX"
	fi
	export CFLAGS="-g -O2 -miphoneos-version-min=9.0 -isysroot $SDKPATH $3"
	export CXXFLAGS=$CFLAGS
	# ICU include is required for arm64
	export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$WORKSPACE/icu/source/common"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib $ARCH -miphoneos-version-min=9.0 -isysroot $SDKPATH"

	export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
	export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
	export TARGET_HOST="$2"

	mkdir -p $PLATFORM_PREFIX
	$SCRIPT_DIR/../shared/mk-meson-cross.sh "${TARGET_HOST}" > $PLATFORM_PREFIX/meson-cross.txt
}

function build() {
	cd "$WORKSPACE"

	install_lib_zlib
	install_lib $LIBPNG_DIR $LIBPNG_ARGS
	install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=ON
	install_lib_meson $HARFBUZZ_DIR $HARFBUZZ_ARGS
	install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=OFF
	install_lib_meson $PIXMAN_DIR $PIXMAN_ARGS -Da64-neon=disabled
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
	install_lib_cmake $FLUIDSYNTH_DIR $FLUIDSYNTH_ARGS
	install_lib_cmake $NLOHMANNJSON_DIR $NLOHMANNJSON_ARGS
	install_lib_meson $INIH_DIR $INIH_ARGS
	install_lib $LHASA_DIR $LHASA_ARGS
	install_lib_cmake $FMT_DIR $FMT_ARGS
	install_lib_icu_cross
	icu_force_data_install
	install_lib_liblcf
	install_lib $SDL2_DIR $SDL2_ARGS --disable-assembly
}

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

# Required for freetype, otherwise adds "-mmacosx-version-min"
export CMAKE_SYSTEM_NAME="iOS"

set_build_flags "armv7" "armv7-apple-darwin"
build
set_build_flags "arm64" "aarch64-apple-darwin"
build
