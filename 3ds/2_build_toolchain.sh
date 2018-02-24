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
	echo "patching libraries"

	patches_common

	# Fix mpg123
	pushd $MPG123_DIR
	patch -Np1 < $SCRIPT_DIR/../shared/extra/mpg123.patch
	autoreconf -fi
	popd

	# Fix libsndfile
	pushd $LIBSNDFILE_DIR
	patch -Np1 < $SCRIPT_DIR/../shared/extra/libsndfile.patch
	autoreconf -fi
	popd

	# Support install for CMAKE_SYSTEM_NAME Generic
	pushd $WILDMIDI_DIR
	patch -Np1 < $SCRIPT_DIR/../shared/extra/wildmidi-generic-install.patch
	popd

	# Disable pthread and other newlib issues
	cp -rup icu icu-native
	patch -Np0 < $SCRIPT_DIR/../shared/extra/icu59.patch

	touch .patches-applied
fi

cd $WORKSPACE

echo "Preparing toolchain"

export DEVKITPRO=${WORKSPACE}/devkitPro
export DEVKITARM=${DEVKITPRO}/devkitARM
export PATH=$DEVKITARM/bin:$PATH
export CTRULIB=${DEVKITPRO}/libctru

export PLATFORM_PREFIX=$WORKSPACE
export TARGET_HOST=arm-none-eabi
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
export MAKEFLAGS="-j${nproc:-2}"

function set_build_flags {
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $TARGET_HOST-gcc"
		export CXX="ccache $TARGET_HOST-g++"
	else
		export CC="$TARGET_HOST-gcc"
		export CXX="$TARGET_HOST-g++"
	fi
	export CFLAGS="-I$PLATFORM_PREFIX/include -g0 -O2 -mword-relocations -fomit-frame-pointer -ffast-math -march=armv6k -mtune=mpcore -mfloat-abi=hard -D_3DS"
	export CPPFLAGS=$CFLAGS
	export CXXFLAGS=$CFLAGS
	export LDFLAGS="-L$PLATFORM_PREFIX/lib"
}

function install_lib_sf2d() {
	cd sf2dlib/libsf2d/
	make clean
	make
	cp -r include/* ../../include/
	cp -r lib/* ../../lib/
	cd ../..
}

# Build native ICU
install_lib_icu_native

# Install libraries
set_build_flags

install_lib_zlib
install_lib $LIBPNG_DIR $LIBPNG_ARGS
install_lib $FREETYPE_DIR $FREETYPE_ARGS --without-harfbuzz
install_lib $HARFBUZZ_DIR $HARFBUZZ_ARGS
install_lib $FREETYPE_DIR $FREETYPE_ARGS --with-harfbuzz
install_lib $PIXMAN_DIR $PIXMAN_ARGS
install_lib_cmake $EXPAT_DIR $EXPAT_ARGS -DCMAKE_SYSTEM_NAME=Generic
install_lib $LIBOGG_DIR $LIBOGG_ARGS
install_lib $LIBVORBIS_DIR $LIBVORBIS_ARGS
install_lib $TREMOR_DIR $TREMOR_ARGS
install_lib $MPG123_DIR $MPG123_ARGS
install_lib $LIBSNDFILE_DIR $LIBSNDFILE_ARGS
install_lib $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS
install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS -DCMAKE_SYSTEM_NAME=Generic
install_lib_icu_cross

# Platform libs
install_lib_sf2d
