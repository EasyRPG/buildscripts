#!/bin/bash

# abort on error
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import

# Override ICU version to 58.1
source $SCRIPT_DIR/packages

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

	cp -rup icu icu-native
	# Fix ICU compilation problems on Wii
	patch -Np0 < icu-wii.patch
	# Emit correct bigendian icudata header
	patch -Np0 < icu-pkg_genc.patch

	# Patch SDL+SDL_mixer
	cd sdl-wii
	git reset --hard
	cd ..
	patch --binary -Np0 < $SCRIPT_DIR/sdl-wii.patch

	touch .patches-applied
fi

cd $WORKSPACE

echo "Preparing toolchain"

export DEVKITPRO=${WORKSPACE}/devkitPro
export DEVKITPPC=${DEVKITPRO}/devkitPPC
export PATH=$DEVKITPPC/bin:$PATH

export PLATFORM_PREFIX=$WORKSPACE
export TARGET_HOST=powerpc-eabi
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
	export CFLAGS="-I$PLATFORM_PREFIX/include -g -O2 -DGEKKO"
	export CPPFLAGS="$CFLAGS"
	export CXXFLAGS=$CFLAGS
	export LDFLAGS="-L$PLATFORM_PREFIX/lib"
}

# Install ICU
function install_lib_icu_native_big() {
	# Compile native version
	unset CC
	unset CXX
	unset CFLAGS
	unset CPPFLAGS
	unset CXXFLAGS
	unset LDFLAGS

	pushd icu-native/source
	chmod u+x configure
	CPPFLAGS="-DBUILD_DATA_WITHOUT_ASSEMBLY -DU_DISABLE_OBJ_CODE" ./configure \
		--enable-static --enable-shared=no --enable-tools=no $ICU_ARGS
	make

	export ICU_CROSS_BUILD=$PWD

	popd
}

function install_lib_sdl() {
	echo ""
	echo "**** Building SDL ****"
	echo ""

	cd sdl-wii/SDL
	make clean
	make install INSTALL_HEADER_DIR="$WORKSPACE/include" INSTALL_LIB_DIR="$WORKSPACE/lib"
	cd ../..

	echo " -> done"
}

function install_lib_sdlmixer() {
	echo ""
	echo "**** Building SDL_mixer ****"
	echo ""

	cd sdl-wii/SDL_mixer
	make clean
	make install INSTALL_HEADER_DIR="$WORKSPACE/include" INSTALL_LIB_DIR="$WORKSPACE/lib"
	cd ../..

	echo " -> done"
}

# build native ICU
# custom native compile because of big endian
install_lib_icu_native_big

# Install libraries
set_build_flags

install_lib_zlib
install_lib $LIBPNG_DIR $LIBPNG_ARGS
install_lib $FREETYPE_DIR $FREETYPE_ARGS --without-harfbuzz
install_lib $HARFBUZZ_DIR $HARFBUZZ_ARGS
install_lib $FREETYPE_DIR $FREETYPE_ARGS --with-harfbuzz
install_lib $PIXMAN_DIR $PIXMAN_ARGS --disable-vmx
install_lib_cmake $EXPAT_DIR $EXPAT_ARGS -DCMAKE_SYSTEM_NAME=Generic
install_lib $LIBOGG_DIR $LIBOGG_ARGS
install_lib $LIBVORBIS_DIR $LIBVORBIS_ARGS
install_lib $TREMOR_DIR $TREMOR_ARGS
install_lib $MPG123_DIR $MPG123_ARGS
install_lib $LIBSNDFILE_DIR $LIBSNDFILE_ARGS
install_lib $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS
install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS -DCMAKE_SYSTEM_NAME=Generic
install_lib $OPUS_DIR $OPUS_ARGS
install_lib $OPUSFILE_DIR $OPUSFILE_ARGS
install_lib_icu_cross

# Platform libs
install_lib_sdl
install_lib_sdlmixer
