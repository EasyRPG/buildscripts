#!/bin/bash

if [ "$(uname)" != "Darwin" ]; then
	echo "This buildscript requires macOS!"
	exit 1
fi

# abort on error
set -e

IS_IPHONEOS=1
export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh
CMAKE_SYSTEM_NAME="iOS"

# Number of CPU
nproc=$(getconf _NPROCESSORS_ONLN)

# Use ccache?
test_ccache

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	# Fix inih
	# Remove when r58 is out
	(cd $INIH_DIR
		patch -Np1 < $SCRIPT_DIR/inih-std11.patch
	)

	touch .patches-applied
fi

function set_universal_build_flags() {
	export PLATFORM_PREFIX=$WORKSPACE
	export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
	export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
	CLANG=`xcodebuild -find clang`
	CLANGXX=`xcodebuild -find clang++`
	SDKPATH=`xcrun -sdk iphoneos --show-sdk-path`
	ARCH="-arch armv7 -arch arm64"

	export CC="$CLANG $ARCH"
	export CXX="$CLANGXX $ARCH"
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $CC"
		export CXX="ccache $CXX"
	fi
	export CPP="$CLANG -arch armv7 -E -isysroot $SDKPATH"
	export CXXCPP="$CLANGXX -arch armv7 -E -isysroot $SDKPATH"

	export CFLAGS="-g -O2 -miphoneos-version-min=7.0 -isysroot $SDKPATH -fobjc-arc"
	export CXXFLAGS=$CFLAGS
	export CPPFLAGS="-I$PLATFORM_PREFIX/include"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib $ARCH -miphoneos-version-min=7.0 -isysroot $SDKPATH"
}

function set_build_flags() {
	if [ ! -d $1 ]; then
		mkdir $1
	fi
	export PLATFORM_PREFIX=$WORKSPACE/$1
	export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
	export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
	ARCH="-arch $1"

	export CC="$CLANG $ARCH"
	export CXX="$CLANGXX $ARCH"
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $CC"
		export CXX="ccache $CXX"
	fi
	export CPP="$CLANG -arch $1 -E -isysroot $SDKPATH"
	export CXXCPP="$CLANGXX -arch $1 -E -isysroot $SDKPATH"

	export CFLAGS="-g -O2 -miphoneos-version-min=7.0 -isysroot $SDKPATH -fobjc-arc"
	export CXXFLAGS=$CFLAGS
	export CPPFLAGS="-I$PLATFORM_PREFIX/include"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib $ARCH -miphoneos-version-min=7.0 -isysroot $SDKPATH"
}

export WORKSPACE=$PWD

export PLATFORM_PREFIX=$WORKSPACE
export TARGET_HOST=arm-apple-darwin
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
export MAKEFLAGS="-j${nproc:-2}"

function install_lib_sdl2() {
	msg "Building SDL2"

	(cd $SDL2_DIR
		./configure --host=$TARGET_HOST --prefix=$WORKSPACE \
			--disable-shared --enable-static
		cp include/SDL_config_iphoneos.h include/SDL_config.h
		make clean
		make
		make install
	)
}

function make_inih_universal() {
	echo "Making inih universal"
	# Copy files needed by CMake
	cp -R armv7/include armv7/lib .
	# Merge inih libraries using lipo
	for armv7_file in $(find armv7/lib -type f -name "*.a")
	do
		filename=$(basename $armv7_file)
		arm64_file="arm64/lib/$filename"
		universal_file="lib/$filename"
		echo "[*] Merging $filename"
		lipo -create "$armv7_file" "$arm64_file" -output "$universal_file"
	done
	# Delete the armv7 and arm64 folder
	rm -rf armv7 arm64
}

function install_lib_inih() {
	# Seems like Meson doesn't support buildling for multiple architectures (armv7 and arm64) so we will build them seperately and then make them universal
	echo "Building inih for armv7"
	set_build_flags "armv7"
	install_lib_meson $INIH_DIR $INIH_ARGS
	echo "Building inih for arm64"
	set_build_flags "arm64"
	install_lib_meson $INIH_DIR $INIH_ARGS
	make_inih_universal
}

install_lib_icu_native

set_universal_build_flags

install_lib_zlib
install_lib $LIBPNG_DIR $LIBPNG_ARGS
install_lib $FREETYPE_DIR $FREETYPE_ARGS --without-harfbuzz
install_lib $HARFBUZZ_DIR $HARFBUZZ_ARGS
install_lib $FREETYPE_DIR $FREETYPE_ARGS --with-harfbuzz
install_lib $PIXMAN_DIR $PIXMAN_ARGS
install_lib_cmake $EXPAT_DIR $EXPAT_ARGS
install_lib $LIBOGG_DIR $LIBOGG_ARGS
install_lib $LIBVORBIS_DIR $LIBVORBIS_ARGS
install_lib_mpg123
install_lib $LIBSNDFILE_DIR $LIBSNDFILE_ARGS
install_lib_cmake $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS
install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS
install_lib $OPUS_DIR $OPUS_ARGS
install_lib $OPUSFILE_DIR $OPUSFILE_ARGS
install_lib_cmake $FLUIDLITE_DIR $FLUIDLITE_ARGS -DENABLE_SF3=ON
install_lib_inih
set_universal_build_flags
install_lib $LHASA_DIR $LHASA_ARGS
install_lib_cmake $FMT_DIR $FMT_ARGS
install_lib_icu_cross
install_lib_liblcf

install_lib_sdl2
