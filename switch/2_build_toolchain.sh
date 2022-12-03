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

	# disable libsamplerate examples and tests
	(cd $LIBSAMPLERATE_DIR
		perl -pi -e 's/examples tests//' Makefile.am
		autoreconf -fi
	)

	cp -rup icu icu-native

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
	ARCH_FLAGS="-march=armv8-a+crc+crypto -mtune=cortex-a57 -mtp=soft -fPIC -ftls-model=local-exec"
	export CFLAGS="-g0 -O2 $ARCH_FLAGS -ffunction-sections -fdata-sections"
	export CXXFLAGS="$CFLAGS"
	export CPPFLAGS="-D__SWITCH__ -I$PLATFORM_PREFIX/include -isystem $DEVKITPRO/libnx/include"
	export LDFLAGS="$ARCH_FLAGS -L$PLATFORM_PREFIX/lib -L$DEVKITPRO/libnx/lib"
	export LIBS="-lnx"
	export CMAKE_SYSTEM_NAME="Generic"
}

install_lib_icu_native

set_build_flags

install_lib_zlib
install_lib $LIBPNG_DIR $LIBPNG_ARGS
install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=ON
install_lib_cmake $HARFBUZZ_DIR $HARFBUZZ_ARGS
install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=OFF
install_lib $PIXMAN_DIR $PIXMAN_ARGS
install_lib_cmake $EXPAT_DIR $EXPAT_ARGS
install_lib $LIBOGG_DIR $LIBOGG_ARGS
install_lib $TREMOR_DIR $TREMOR_ARGS
install_lib_mpg123
install_lib_cmake $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $LIBSAMPLERATE_DIR $LIBSAMPLERATE_ARGS
install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS
install_lib $OPUS_DIR $OPUS_ARGS
install_lib $OPUSFILE_DIR $OPUSFILE_ARGS
install_lib_cmake $FLUIDSYNTH_DIR $FLUIDSYNTH_ARGS
install_lib_cmake $FMT_DIR $FMT_ARGS
install_lib_icu_cross
install_lib_liblcf
