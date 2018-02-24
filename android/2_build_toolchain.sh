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
	echo "patching libraries"

	patches_common

	cp -rup icu icu-native

	# Accept api9 for make_standalone_toolchain
	perl -pi -e 's/min_api = 14/min_api = 9/' ./android-ndk-r15c/build/tools/make_standalone_toolchain.py

	# Patch cpufeatures, hangs in Android 4.0.3
	patch -Np0 < cpufeatures.patch

	# disable unsupported compiler flags by clang in libvorbis
	perl -pi -e 's/-mno-ieee-fp//' $LIBVORBIS_DIR/configure

        # Wildmidi: Support install for CMAKE_SYSTEM_NAME Generic
        pushd $WILDMIDI_DIR
        patch -Np1 < $SCRIPT_DIR/../shared/extra/wildmidi-generic-install.patch
        popd

	# use android config
	pushd $SDL2_DIR
	mv include/SDL_config_android.h include/SDL_config.h
	mkdir -p jni
	popd

	touch .patches-applied
fi

# Install mpg123
function install_lib_mpg123 {
	export CPPFLAGSOLD=$CPPFLAGS
	export CPPFLAGS="$CPPFLAGS -DHAVE_MMAP"
	rm $PLATFORM_PREFIX/config.cache
	install_lib $MPG123_DIR $MPG123_ARGS
	rm $PLATFORM_PREFIX/config.cache
	export CPPFLAGS=$CPPFLAGSOLD
}

# Install SDL2
function install_lib_sdl {
	# $1 => platform (armeabi armeabi-v7a x86 aarch64)

	pushd $SDL2_DIR
	echo "APP_ABI := $1" >> "jni/Application.mk"
	ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android.mk APP_PLATFORM=android-$TARGET_API
	mkdir -p $PLATFORM_PREFIX/lib
	mkdir -p $PLATFORM_PREFIX/include/SDL2
	cp libs/$1/* $PLATFORM_PREFIX/lib/
	cp include/* $PLATFORM_PREFIX/include/SDL2/
	cd ..
}

function build() {
	# $1: Toolchain Name
	# $2: Toolchain architecture
	# $3: Android arch
	# $4: host for configure
	# $5: additional CPP flags

	cd $WORKSPACE

	echo "preparing $1 toolchain"

	export TARGET_API=9
	if [ "$3"="arm64" ]; then
		# Minimum API 21 on ARM64
		export TARGET_API=21
	fi

	export PATH=$OLD_PATH
	export PLATFORM_PREFIX=$WORKSPACE/$2-toolchain
	$NDK_ROOT/build/tools/make_standalone_toolchain.py --api=$TARGET_API \
		--install-dir=$PLATFORM_PREFIX --stl=libc++ --arch=$3

	export PATH=$PLATFORM_PREFIX/bin:$PATH

	export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/cpufeatures $5"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib"
	export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
	export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
	export TARGET_HOST="$4"
	export CC="$TARGET_HOST-clang"
	export CXX="$TARGET_HOST-clang++"
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $TARGET_HOST-clang"
		export CXX="ccache $TARGET_HOST-clang++"
	fi

	install_lib $LIBPNG_DIR $LIBPNG_ARGS
	install_lib $FREETYPE_DIR $FREETYPE_ARGS --without-harfbuzz
	install_lib $HARFBUZZ_DIR $HARFBUZZ_ARGS
	install_lib $FREETYPE_DIR $FREETYPE_ARGS --with-harfbuzz
	install_lib $PIXMAN_DIR $PIXMAN_ARGS
	install_lib_cmake $EXPAT_DIR $EXPAT_ARGS -DCMAKE_SYSTEM_NAME=Generic
	install_lib $LIBOGG_DIR $LIBOGG_ARGS
	install_lib $LIBVORBIS_DIR $LIBVORBIS_ARGS
	install_lib_mpg123
	install_lib $LIBSNDFILE_DIR $LIBSNDFILE_ARGS
	install_lib $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
	install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS
	install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS -DCMAKE_SYSTEM_NAME=Generic
	install_lib_icu_cross
	install_lib_sdl "$2"
}

export NDK_ROOT=$WORKSPACE/android-ndk-r15c
export SDK_ROOT=$WORKSPACE/android-sdk

export MAKEFLAGS="-j${nproc:-2}"

# Setup PATH
PATH=$PATH:$NDK_ROOT:$SDK_ROOT/tools

export OLD_PATH=$PATH

# Install host ICU
cd $WORKSPACE

echo "preparing ICU host build"
install_lib_icu_native

####################################################
# Install standalone toolchain x86

build "x86" "x86" "x86" "i686-linux-android" ""

################################################################
# Install standalone toolchain ARMeabi

build "ARMeabi" "armeabi" "arm" "arm-linux-androideabi" ""

################################################################
# Install standalone toolchain ARMeabi-v7a

build "ARMeabi-v7a" "armeabi-v7a" "arm" "arm-linux-androideabi" "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3"

################################################################
# Install standalone toolchain arm64-v8a

build "AArch64" "arm64-v8a" "arm64" "aarch64-linux-android" ""
