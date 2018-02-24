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

	cp -rup icu icu-native

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

	# Wildmidi: Support install for CMAKE_SYSTEM_NAME Generic
	pushd $WILDMIDI_DIR
	patch -Np1 < $SCRIPT_DIR/../shared/extra/wildmidi-generic-install.patch
	# Switch compatibility
	patch -Np1 < $SCRIPT_DIR/wildmidi-switch.patch
	popd

	# disable libsamplerate examples and tests
	cd libsamplerate-0.1.9
	perl -pi -e 's/examples tests//' Makefile.am
	autoreconf -fi
	cd ..

	# Fix icu build
	cp -rup icu icu-native
	patch -Np0 < $SCRIPT_DIR/icu59-switch.patch

	touch .patches-applied
fi

cd $WORKSPACE

echo "Preparing toolchain"

export DEVKITPRO=${WORKSPACE}/devkitPro
export DEVKITA64=${DEVKITPRO}/devkitA64
export PATH=$DEVKITA64/bin:$PATH

export PLATFORM_PREFIX=$WORKSPACE
export TARGET_HOST=aarch64-none-elf
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
	export CFLAGS="-I$WORKSPACE/include -I$DEVKITPRO/libnx/include -g0 -O2 -march=armv8-a -mtune=cortex-a57 -mtp=soft -fPIC -ftls-model=local-exec -DSWITCH"
	export CPPFLAGS="$CFLAGS"
	export CXXFLAGS=$CFLAGS
	export LDFLAGS="-L$WORKSPACE/lib"
}

# Build native icu59
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
install_lib $MPG123_DIR $MPG123_ARGS
install_lib $LIBSNDFILE_DIR $LIBSNDFILE_ARGS
install_lib $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $LIBSAMPLERATE_DIR $LIBSAMPLERATE_ARGS
install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS -DCMAKE_SYSTEM_NAME=Generic
install_lib_icu_cross