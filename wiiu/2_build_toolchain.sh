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
test_dkp "devkitPPC"
export PATH=$DEVKITPPC/bin:$DEVKITPRO/tools/bin:$PATH

# Extra tools available?
require_tool wuhbtool

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	verbosemsg "pixman"
	(cd $PIXMAN_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/pixman-no-tls.patch
	)

	verbosemsg "expat"
	(cd $EXPAT_DIR
		perl -pi -e 's/.*arc4random.*//g' ConfigureChecks.cmake
	)

	verbosemsg "lhasa"
	(cd $LHASA_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/lhasa.patch
	)

	verbosemsg "fluidsynth"
	(cd $FLUIDSYNTH_DIR
		patch -Np1 < $SCRIPT_DIR/fluidsynth-no-pthread.patch
	)

	verbosemsg "ICU"
	# Do not write objects, but source files
	perl -pi -e 's|#ifndef U_DISABLE_OBJ_CODE.*|#if 0 // U_DISABLE_OBJ_CODE|' icu/source/tools/toolutil/pkg_genc.h
	# Emit correct bigendian icudata header
	patch -Np0 < icu-pkg_genc.patch
	# Fix char16 detection
	patch -Np0 < $SCRIPT_DIR/icu-data-char16.patch

	touch .patches-applied
fi

cd $WORKSPACE

echo "Preparing toolchain"

export PLATFORM_PREFIX=$WORKSPACE
export TARGET_HOST=powerpc-eabi
unset PKG_CONFIG_PATH
export PKG_CONFIG_LIBDIR=$PLATFORM_PREFIX/lib/pkgconfig
export MAKEFLAGS="-j${nproc:-2}"

function set_build_flags {
	export CC="$TARGET_HOST-gcc"
	export CXX="$TARGET_HOST-g++"
	export CFLAGS="-g0 -O2 -mcpu=750 -meabi -mhard-float -ffunction-sections -fdata-sections"
	export CXXFLAGS="$CFLAGS"
	export CPPFLAGS="-DESPRESSO -D__WIIU__ -D__WUT__ -I$PLATFORM_PREFIX/include -I$DEVKITPRO/wut/include"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib -L$DEVKITPRO/wut/lib -specs=$DEVKITPRO/wut/share/wut.specs"
	export LIBS="-lwut"
	export CMAKE_SYSTEM_NAME="Generic"
	export CMAKE_EXTRA_ARGS="-DCMAKE_C_BYTE_ORDER=BIG_ENDIAN"

	make_meson_cross ogc > meson-cross.txt
}

install_lib_icu_native

set_build_flags

install_lib_cmake $ZLIB_DIR $ZLIB_ARGS
install_lib_cmake $LIBPNG_DIR $LIBPNG_ARGS
install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=ON
#install_lib_meson $HARFBUZZ_DIR $HARFBUZZ_ARGS
#install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=OFF
install_lib_meson $PIXMAN_DIR $PIXMAN_ARGS -Dvmx=disabled
install_lib_cmake $EXPAT_DIR $EXPAT_ARGS
install_lib $LIBOGG_DIR $LIBOGG_ARGS
install_lib $LIBVORBIS_DIR $LIBVORBIS_ARGS
install_lib $MPG123_DIR $MPG123_ARGS
install_lib_cmake $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS
install_lib_cmake $FLUIDSYNTH_DIR $FLUIDSYNTH_ARGS
install_lib_cmake $OPUS_DIR $OPUS_ARGS
install_lib $OPUSFILE_DIR $OPUSFILE_ARGS
install_lib_meson $INIH_DIR $INIH_ARGS
install_lib $LHASA_DIR $LHASA_ARGS
install_lib_cmake $FMT_DIR $FMT_ARGS
install_lib_icu_cross
install_lib_liblcf
