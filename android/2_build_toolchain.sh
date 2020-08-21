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

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	cp -rup icu icu-native

	# Patch cpufeatures, hangs in Android 4.0.3
	patch -Np0 < cpufeatures.patch

	# use android config
	pushd $SDL2_DIR
	mv include/SDL_config_android.h include/SDL_config.h
	mkdir -p jni
	popd

	touch .patches-applied
fi

# Install SDL2
function install_lib_sdl {
	# $1: platform (armeabi-v7a aarch64 x86 x86_x64)

	pushd $SDL2_DIR
	echo "APP_ABI := $1" >> "jni/Application.mk"
	ndk-build NDK_PROJECT_PATH=. NDK_DEBUG=0 APP_BUILD_SCRIPT=./Android.mk APP_PLATFORM=android-$TARGET_API
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

	echo "Preparing $1 toolchain"

	export TARGET_API=14
	if [ "$3" = "arm64" ]; then
		# Minimum API 21 on ARM64
		export TARGET_API=21
	fi
	if [ "$3" = "x86_64" ]; then
		# Minimum API 21 on x86_64
		export TARGET_API=21
	fi

	export PATH=$OLD_PATH
	export PLATFORM_PREFIX=$WORKSPACE/$2-toolchain
	$NDK_ROOT/build/tools/make_standalone_toolchain.py --api=$TARGET_API \
		--install-dir=$PLATFORM_PREFIX --stl=libc++ --arch=$3

	export PATH=$PLATFORM_PREFIX/bin:$PATH

	export CFLAGS="-g0 -O2 $5"
	export CXXFLAGS="$CFLAGS -DHB_NO_MMAP"
	export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/cpufeatures"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib"
	unset PKG_CONFIG_PATH
	export PKG_CONFIG_LIBDIR=$PLATFORM_PREFIX/lib/pkgconfig
	export TARGET_HOST="$4"
	export CC="$TARGET_HOST-clang"
	export CXX="$TARGET_HOST-clang++"
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $CC"
		export CXX="ccache $CXX"
	fi

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
	install_lib_cmake $FMT_DIR $FMT_ARGS
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

install_lib_icu_native

# Correctly detected mmap support in mpg123
export ac_cv_func_mmap_fixed_mapped=yes

# Install standalone toolchain ARMeabi-v7a
build "ARMeabi-v7a" "armeabi-v7a" "arm" "arm-linux-androideabi" "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3"

# Install standalone toolchain arm64-v8a
build "AArch64" "arm64-v8a" "arm64" "aarch64-linux-android" ""

# Install standalone toolchain x86
build "x86" "x86" "x86" "i686-linux-android" ""

# Install standalone toolchain x86_64
build "x86_64" "x86_64" "x86_64" "x86_64-linux-android" ""
