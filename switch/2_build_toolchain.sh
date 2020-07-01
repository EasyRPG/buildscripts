#!/bin/bash

# abort on error
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

# Installation directory
set_workspace

# Number of CPU
nproc=$(nproc)

# Use ccache?
test_ccache

# Toolchain available?
if [[ -z $DEVKITPRO || ! -d "$DEVKITPRO/devkitA64" ]]; then
	echo "Setup devkitA64 properly. \$DEVKITPRO needs to be set."
	exit 1
fi

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	# Fix mpg123
	(cd $MPG123_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/mpg123.patch
		autoreconf -fi
	)

	# Fix libsndfile
	(cd $LIBSNDFILE_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/libsndfile.patch
		autoreconf -fi
	)

	# Enable pixman SIMD
	(cd $PIXMAN_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/pixman-simd.patch
	)

	# disable libsamplerate examples and tests
	(cd $LIBSAMPLERATE_DIR
		perl -pi -e 's/examples tests//' Makefile.am
		autoreconf -fi
	)

	# Fix harfbuzz
	(cd $HARFBUZZ_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/harfbuzz-climits.patch
	)

	cp -rup icu icu-native
	# Fix icu build
	patch -Np0 < $SCRIPT_DIR/icu59-switch.patch

	touch .patches-applied
fi

cd $WORKSPACE

echo "Preparing toolchain"

export PATH=$DEVKITPRO/devkitA64/bin:$PATH

export PLATFORM_PREFIX=$WORKSPACE
export TARGET_HOST=aarch64-none-elf
unset PKG_CONFIG_PATH
export PKG_CONFIG_LIBDIR=$PLATFORM_PREFIX/lib/pkgconfig
export MAKEFLAGS="-j${nproc:-2}"

function set_build_flags {
	export CC="$TARGET_HOST-gcc"
	export CXX="$TARGET_HOST-g++"
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $CC"
		export CXX="ccache $CXX"
	fi
	ARCH_FLAGS="-march=armv8-a -mtune=cortex-a57 -mtp=soft -fPIC -ftls-model=local-exec"
	export CFLAGS="-g0 -O2 $ARCH_FLAGS -ffunction-sections"
	export CXXFLAGS="$CFLAGS"
	export CPPFLAGS="-D__SWITCH__ -I$PLATFORM_PREFIX/include -I$DEVKITPRO/libnx/include"
	export LDFLAGS="$ARCH_FLAGS -L$PLATFORM_PREFIX/lib -L$DEVKITPRO/libnx/lib"
	export LIBS="-lnx"
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
install_lib $TREMOR_DIR $TREMOR_ARGS
install_lib $MPG123_DIR $MPG123_ARGS
install_lib $LIBSNDFILE_DIR $LIBSNDFILE_ARGS
install_lib_cmake $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $LIBSAMPLERATE_DIR $LIBSAMPLERATE_ARGS
install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS
install_lib $OPUS_DIR $OPUS_ARGS
install_lib $OPUSFILE_DIR $OPUSFILE_ARGS
install_lib_cmake $FMT_DIR $FMT_ARGS
install_lib_icu_cross
