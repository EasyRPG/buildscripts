#!/bin/bash

# abort on errors
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import

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
