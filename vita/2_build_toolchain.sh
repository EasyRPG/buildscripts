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

	# Wildmidi: Vita compatibility
	pushd $WILDMIDI_DIR
	patch -Np1 < $SCRIPT_DIR/wildmidi-vita.patch
	popd

	# Fix icu build
	# Custom patch because vita newlib provides pthread
	cp -rup icu icu-native
	patch -Np0 < $SCRIPT_DIR/icu59-vita.patch

	touch .patches-applied
fi

cd $WORKSPACE

echo "Preparing toolchain"

export VITASDK=$PWD/vitasdk
export PATH=$PWD/vitasdk/bin:$PATH

export PLATFORM_PREFIX=$WORKSPACE
export TARGET_HOST=arm-vita-eabi
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
export MAKEFLAGS="-j${nproc:-2}"

function set_build_flags {
	export CC="$TARGET_HOST-gcc"
	export CXX="$TARGET_HOST-g++"
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $CC"
		export CXX="ccache $CXX"
	fi
	export CFLAGS="-g0 -O2"
	export CXXFLAGS=$CFLAGS
	export CPPFLAGS="-I$PLATFORM_PREFIX/include -DPSP2"

	export LDFLAGS="-L$PLATFORM_PREFIX/lib"
}

# Install patched libvita2d
function install_lib_vita2d() {
	cd vita2dlib
	git checkout fbo
	cd libvita2d
	make clean
	make -j1
	make install
	cd ../..
}

# Install precompiled shaders
function install_shaders() {
	cd vitashaders
	cp -a ./lib/. $VITASDK/$TARGET_HOST/lib/
	cp -a ./includes/. $VITASDK/$TARGET_HOST/include/
	cd ..
}

function install_vdpm() {
	pushd vdpm
	./install-all.sh
	popd
}

# Build native icu59
install_lib_icu_native

# Platform libs
install_vdpm
install_lib_vita2d

# Install libraries
set_build_flags
install_lib_zlib
install_lib $LIBPNG_DIR $LIBPNG_ARGS
install_lib $FREETYPE_DIR $FREETYPE_ARGS --without-harfbuzz
install_lib $HARFBUZZ_DIR $HARFBUZZ_ARGS
install_lib $FREETYPE_DIR $FREETYPE_ARGS --with-harfbuzz
install_lib $PIXMAN_DIR $PIXMAN_ARGS
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
install_lib_icu_cross

# Precompiled shaders
install_shaders
