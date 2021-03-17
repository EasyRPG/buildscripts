#!/bin/bash

# abort on errors
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

# Cloning the liblcf repository
if [ ! -d liblcf/.git ]; then
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

	export CFLAGS="-no-integrated-as -g0 -O2 -fPIC $5"
	export CXXFLAGS="$CFLAGS -DHB_NO_MMAP"
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

	install_lib liblcf --disable-tools
}

export SDK_ROOT=$WORKSPACE/android-sdk
export NDK_ROOT=$SDK_ROOT/ndk/21.4.7075529

export MAKEFLAGS="-j${nproc:-2}"

# Setup PATH
PATH=$NDK_ROOT:$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$SDK_ROOT/tools:$PATH

export OLD_PATH=$PATH

# Prepare liblcf
cd liblcf

msg " Preparing Build System..."
autoreconf -fi
msg " -> done"

cd ..

# Compile liblcf
build "ARMeabi-v7a" "armeabi-v7a" "arm" "armv7a-linux-androideabi" "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3"

build "AArch64" "arm64-v8a" "arm64" "aarch64-linux-android" ""

build "x86" "x86" "x86" "i686-linux-android" ""

build "x86_64" "x86_64" "x86_64" "x86_64-linux-android" ""
