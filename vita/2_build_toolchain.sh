#!/bin/bash

# abort on errors
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

# Number of CPU
nproc=$(nproc)

# Use ccache?
test_ccache

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	# Fix mpg123
	(cd $MPG123_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/mpg123.patch
		autoreconf -fi
	)

	# Fix lhasa
	(cd $LHASA_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/lhasa.patch
	)

	# Fix fmt
	(cd $FMT_DIR
		# Fix undefined reference to funlockfile
		perl -pi -e 's/define FMT_USE_FALLBACK_FILE 0/define FMT_USE_FALLBACK_FILE 1/' include/fmt/format-inl.h
	)

	# Fix icu build
	patch -Np0 < $SCRIPT_DIR/icu-vita.patch

	# Disable vita2dlib jpeg dependency
	patch -Np0 < $SCRIPT_DIR/libvita2d-no-jpeg.patch

	# Allow the cmake toolchain finding libfmt
	patch -Np0 < $SCRIPT_DIR/vitasdk-cmake.patch

	touch .patches-applied
fi

cd $WORKSPACE

echo "Preparing toolchain"

export VITASDK=$PWD/vitasdk
export PATH=$PWD/vitasdk/bin:$PATH

export TARGET_HOST=arm-vita-eabi
export PLATFORM_PREFIX=$VITASDK/$TARGET_HOST
unset PKG_CONFIG_PATH
export PKG_CONFIG_LIBDIR=$PLATFORM_PREFIX/lib/pkgconfig
export MAKEFLAGS="-j${nproc:-2}"

function set_build_flags {
	export CC="$TARGET_HOST-gcc"
	export CXX="$TARGET_HOST-g++"
	export CFLAGS="-g0 -O2"
	export CXXFLAGS="$CFLAGS"
	export CPPFLAGS="-DPSP2"
	export CMAKE_SYSTEM_NAME="Generic"
	export CMAKE_EXTRA_ARGS="-DCMAKE_SYSTEM_PROCESSOR=arm64"

	make_meson_cross vita > $PLATFORM_PREFIX/meson-cross.txt
}

function install_lib_vita2d() {
	msg "Building patched libvita2d"

	(cd libvita2d/libvita2d
		make clean
		make -j1 CFLAGS='-Wl,-q -Wall -O3 -I$(INCLUDES) -I$(VITASDK)/arm-vita-eabi/include/freetype2'
		make install
	)
}

install_lib_icu_native

set_build_flags

install_lib_cmake $ZLIB_DIR $ZLIB_ARGS
install_lib_cmake $LIBPNG_DIR $LIBPNG_ARGS
install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=ON
install_lib_meson $HARFBUZZ_DIR $HARFBUZZ_ARGS
install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=OFF
install_lib_meson $PIXMAN_DIR $PIXMAN_ARGS
install_lib_cmake $EXPAT_DIR $EXPAT_ARGS
install_lib $LIBOGG_DIR $LIBOGG_ARGS
install_lib $LIBVORBIS_DIR $LIBVORBIS_ARGS
install_lib $MPG123_DIR $MPG123_ARGS
install_lib_cmake $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS
install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS
install_lib_cmake $FLUIDLITE_DIR $FLUIDLITE_ARGS -DENABLE_SF3=ON
install_lib $OPUS_DIR $OPUS_ARGS
install_lib $OPUSFILE_DIR $OPUSFILE_ARGS
install_lib_meson $INIH_DIR $INIH_ARGS
install_lib $LHASA_DIR $LHASA_ARGS
install_lib_cmake $FMT_DIR $FMT_ARGS
install_lib_icu_cross
install_lib_liblcf

install_lib_vita2d
