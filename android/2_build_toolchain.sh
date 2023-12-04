#!/bin/bash

# abort on error
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

# Platform configuration
os=`uname`
if [ $os = "Darwin" ] ; then
	nproc=$(getconf _NPROCESSORS_ONLN)
	CP_ARGS="-r"
	NDK_ARCH="darwin-x86_64"
else
	nproc=$(nproc)
	CP_ARGS="-rup"
	NDK_ARCH="linux-x86_64"
fi

# Use ccache?
test_ccache

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	cp $CP_ARGS icu icu-native

	# pixman: hardcode cpufeatures (crashes armeabi-v7a)
	(cd $PIXMAN_DIR
		patch -Np1 < ../pixman-cpufeatures.patch
	)

	# use android config
	(cd $SDL2_DIR
		mv include/SDL_config_android.h include/SDL_config.h
		mkdir -p jni
	)

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

	export TARGET_API=16
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

	export PATH=$PLATFORM_PREFIX/bin:$PATH

	export AR=$NDK_PATH/llvm-ar
	export NM=$NDK_PATH/llvm-nm
	export RANLIB=$NDK_PATH/llvm-ranlib

	export CFLAGS="-no-integrated-as -g0 -O2 -fPIC $5"
	export CXXFLAGS="$CFLAGS"
	export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/cpufeatures"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib"
	unset PKG_CONFIG_PATH
	export PKG_CONFIG_LIBDIR=$PLATFORM_PREFIX/lib/pkgconfig
	export TARGET_HOST="$4"
	export CC="clang -target ${TARGET_HOST}${TARGET_API}"
	export CXX="clang++ -target ${TARGET_HOST}${TARGET_API}"
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $CC"
		export CXX="ccache $CXX"
	fi

	install_lib_zlib
	install_lib $LIBPNG_DIR $LIBPNG_ARGS
	install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=ON
	install_lib_cmake $HARFBUZZ_DIR $HARFBUZZ_ARGS
	install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=OFF
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
	install_lib_cmake $FLUIDSYNTH_DIR $FLUIDSYNTH_ARGS
	install_lib_meson $INIH_DIR $INIH_ARGS
	install_lib $LHASA_DIR $LHASA_ARGS
	install_lib_cmake $FMT_DIR $FMT_ARGS
	install_lib_icu_cross
	install_lib_sdl "$2"
	install_lib_liblcf
}

export SDK_ROOT=$WORKSPACE/android-sdk
export NDK_ROOT=$SDK_ROOT/ndk/21.4.7075529

export MAKEFLAGS="-j${nproc:-2}"

# Install host ICU
cd $WORKSPACE

install_lib_icu_native

# Setup PATH
NDK_PATH=$NDK_ROOT/toolchains/llvm/prebuilt/$NDK_ARCH/bin
PATH=$NDK_ROOT:$NDK_PATH:$SDK_ROOT/tools:$PATH

export OLD_PATH=$PATH

# Correctly detected mmap support in mpg123
export ac_cv_func_mmap_fixed_mapped=yes

# ARMeabi-v7a
build "ARMeabi-v7a" "armeabi-v7a" "arm" "armv7a-linux-androideabi" "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3"

# arm64-v8a
build "AArch64" "arm64-v8a" "arm64" "aarch64-linux-android" ""

# x86
build "x86" "x86" "x86" "i686-linux-android" ""

# x86_64
build "x86_64" "x86_64" "x86_64" "x86_64-linux-android" ""
