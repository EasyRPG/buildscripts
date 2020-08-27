#!/bin/bash

# abort on errors
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

# Cloning or pulling the liblcf repository
if [ -d liblcf/.git ]; then
	git -C liblcf pull
else
	git clone https://github.com/EasyRPG/liblcf.git
fi

# Number of CPU
nproc=$(nproc)

# Use ccache?
test_ccache

function build() {
	# $1: Toolchain Name
	# $2: Toolchain architecture
	# $3: host for configure
	# $4: additional C flags

	cd $WORKSPACE

	msg "Building liblcf for $1..."

	export PATH=$OLD_PATH
	export PLATFORM_PREFIX=$WORKSPACE/$2-toolchain
	export PATH=$PLATFORM_PREFIX/bin:$PATH

	export CFLAGS="-g0 -O2 $4"
	export CXXFLAGS="$CFLAGS -DHB_NO_MMAP"
	export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/cpufeatures"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib"
	unset PKG_CONFIG_PATH
	export PKG_CONFIG_LIBDIR=$PLATFORM_PREFIX/lib/pkgconfig
	export TARGET_HOST="$3"
	export CC="$TARGET_HOST-clang"
	export CXX="$TARGET_HOST-clang++"
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $CC"
		export CXX="ccache $CXX"
	fi

	install_lib liblcf
}

export NDK_ROOT=$WORKSPACE/android-ndk-r15c
export SDK_ROOT=$WORKSPACE/android-sdk

export MAKEFLAGS="-j${nproc:-2}"

# Setup PATH
PATH=$PATH:$NDK_ROOT:$SDK_ROOT/tools

export OLD_PATH=$PATH

# Prepare liblcf
cd liblcf

msg " Preparing Build System..."
autoreconf -fi
msg " -> done"

cd ..

# Compile liblcf
build "ARMeabi-v7a" "armeabi-v7a" "arm-linux-androideabi" "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3"
build "AArch64" "arm64-v8a" "aarch64-linux-android" ""
build "x86" "x86" "i686-linux-android" ""
build "x86_64" "x86_64" "x86_64-linux-android" ""

