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
test_dkp "devkitARM"
export PATH=$DEVKITARM/bin:$DEVKITPRO/tools/bin:$PATH

# Extra tools available?
if test_tool bannertool && test_tool makerom && test_tool 3dstool; then
	: # nothing
else
	msg "The following tools need to be installed to allow building .cia"
	msg "bundles or creating custom banners:"
	msg "  https://github.com/dnasdw/3dstool"
	msg "  https://github.com/carstene1ns/3ds-bannertool"
	msg "  https://github.com/profi200/Project_CTR"
fi
require_tool tex3ds
require_tool 3dsxtool

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	verbosemsg "pixman"
	(cd $PIXMAN_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/pixman-no-tls.patch
		patch -Np1 < $SCRIPT_DIR/pixman-fix-types.patch
	)

	verbosemsg "mpg123"
	(cd $MPG123_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/mpg123.patch
		autoreconf -fi
	)

	verbosemsg "tremor"
	patch -d $TREMOR_DIR -Np1 < $SCRIPT_DIR/tremor-fix-types.patch

	verbosemsg "opusfile"
	patch -d $OPUSFILE_DIR -Np1 < $SCRIPT_DIR/../shared/extra/opusfile-devkit.patch

	verbosemsg "lhasa"
	patch -d $LHASA_DIR -Np1 < $SCRIPT_DIR/../shared/extra/lhasa.patch

	verbosemsg "ICU"
	patch -Np0 < $SCRIPT_DIR/icu77-no-mutex.patch
	patch -Np0 < $SCRIPT_DIR/icu-data-char16.patch

	touch .patches-applied
fi

cd $WORKSPACE

echo "Preparing toolchain"

export PLATFORM_PREFIX=$WORKSPACE
export TARGET_HOST=arm-none-eabi
unset PKG_CONFIG_PATH
export PKG_CONFIG_LIBDIR=$PLATFORM_PREFIX/lib/pkgconfig
export MAKEFLAGS="-j${nproc:-2}"

function set_build_flags {
	export CC="$TARGET_HOST-gcc"
	export CXX="$TARGET_HOST-g++"
	ARCH_FLAGS="-march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft -mword-relocations"
	export CFLAGS="-g0 -O2 $ARCH_FLAGS -ffunction-sections -fdata-sections"
	export CXXFLAGS="$CFLAGS"
	export CPPFLAGS="-D_3DS -I$PLATFORM_PREFIX/include -I$DEVKITPRO/libctru/include"
	export LDFLAGS="$ARCH_FLAGS -L$PLATFORM_PREFIX/lib -L$DEVKITPRO/libctru/lib"
	export LIBS="-lctru"
	export CMAKE_SYSTEM_NAME="Generic"
	export CMAKE_EXTRA_ARGS="-DCMAKE_SYSTEM_PROCESSOR=arm"

	make_meson_cross 3ds > meson-cross.txt
}

install_lib_icu_native

set_build_flags

install_lib_cmake $ZLIB_DIR $ZLIB_ARGS
install_lib_cmake $LIBPNG_DIR $LIBPNG_ARGS
install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=ON
#install_lib_meson $HARFBUZZ_DIR $HARFBUZZ_ARGS
#install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=OFF
install_lib_meson $PIXMAN_DIR $PIXMAN_ARGS -Dneon=disabled
install_lib_cmake $EXPAT_DIR $EXPAT_ARGS
install_lib $LIBOGG_DIR $LIBOGG_ARGS
install_lib $TREMOR_DIR $TREMOR_ARGS
install_lib $MPG123_DIR $MPG123_ARGS
install_lib_cmake $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS
install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS
# asm support is missing in opus cmake, but might be added one day,
# likely -DOPUS_ASM=OFF then, beware if switching to meson
install_lib_cmake $OPUS_DIR $OPUS_ARGS -DOPUS_FIXED_POINT=ON
install_lib $OPUSFILE_DIR $OPUSFILE_ARGS --enable-fixed-point
install_lib_cmake $FLUIDLITE_DIR $FLUIDLITE_ARGS
install_lib_meson $INIH_DIR $INIH_ARGS
install_lib $LHASA_DIR $LHASA_ARGS
install_lib_cmake $FMT_DIR $FMT_ARGS
install_lib_icu_cross
install_lib_liblcf
