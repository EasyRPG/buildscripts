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
require_tool elf2dol

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	# Fix pixman
	patch -d $PIXMAN_DIR -Np1 < $SCRIPT_DIR/../shared/extra/pixman-no-tls.patch

	# Fix mpg123
	(cd $MPG123_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/mpg123.patch
		autoreconf -fi
	)

	# Fix opus
	(cd $OPUS_DIR
		# do not fortify source
		perl -pi -e 's/AX_ADD_FORTIFY_SOURCE//' configure.ac
		autoreconf -fi
	)

	# Fix Fluidlite
	(cd $FLUIDLITE_DIR
		# enable big endian
		perl -pi -e 's/#undef WORDS_BIGENDIAN/#define WORDS_BIGENDIAN/' src/fluid_config.h
	)

	# Fix lhasa
	patch -d $LHASA_DIR -Np1 < $SCRIPT_DIR/../shared/extra/lhasa.patch

	# Fix icu build
	# Do not write objects, but source files
	perl -pi -e 's|#ifndef U_DISABLE_OBJ_CODE|#if 0 // U_DISABLE_OBJ_CODE|' icu/source/tools/toolutil/pkg_genc.h
	# Emit correct bigendian icudata header
	patch -Np0 < icu-pkg_genc.patch
	# Remove mutexes (crashes)
	patch -Np0 < $SCRIPT_DIR/../shared/extra/icu-no-mutex.patch
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
	export CPPFLAGS="-I$PLATFORM_PREFIX/include -DGEKKO -I$DEVKITPRO/libogc/include"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib"
	export CMAKE_SYSTEM_NAME="Generic"

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
install_lib $TREMOR_DIR $TREMOR_ARGS
install_lib $MPG123_DIR $MPG123_ARGS
install_lib_cmake $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS
install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS
install_lib_cmake $FLUIDLITE_DIR $FLUIDLITE_ARGS
install_lib $OPUS_DIR $OPUS_ARGS
install_lib $OPUSFILE_DIR $OPUSFILE_ARGS
install_lib_meson $INIH_DIR $INIH_ARGS
install_lib $LHASA_DIR $LHASA_ARGS
install_lib_cmake $FMT_DIR $FMT_ARGS
install_lib_icu_cross
install_lib_liblcf
