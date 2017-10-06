#!/bin/bash

# abort on errors
set -e

export WORKSPACE=$PWD

# helper
function msg {
	echo ""
	echo $1
	echo ""
}

# Number of CPU
NBPROC=$(getconf _NPROCESSORS_ONLN)

# Cloning or pulling the liblcf repository
if [ -d liblcf/.git ]; then
	git -C liblcf pull
else
	git clone https://github.com/EasyRPG/liblcf.git
fi
cd liblcf

msg " Preparing Build System..."
autoreconf -fi
msg " -> done"

# x86
msg " Building liblcf for X86..."
export PLATFORM_PREFIX=$WORKSPACE/x86-toolchain
export OLD_PATH=$PATH
export PATH=$PLATFORM_PREFIX/bin:$PATH
export CPPFLAGS="-I$PLATFORM_PREFIX/include "
export LDFLAGS="-L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
export TARGET_HOST="i686-linux-android"
export CC="$TARGET_HOST-clang"
export CXX="$TARGET_HOST-clang++"

./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make clean
make -j$NBPROC
make install
msg " -> done"

# armeabi
msg " Building liblcf for ARMEABI..."
export PLATFORM_PREFIX=$WORKSPACE/armeabi-toolchain
export PATH=$OLD_PATH
export PATH=$PLATFORM_PREFIX/bin:$PATH
export CPPFLAGS="-I$PLATFORM_PREFIX/include"
export LDFLAGS="-L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
export TARGET_HOST="arm-linux-androideabi"
export CC="$TARGET_HOST-clang"
export CXX="$TARGET_HOST-clang++"

./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make clean
make -j$NBPROC
make install
msg " -> done"

# armeabi-v7a
msg " Building liblcf for ARMEABI-V7A..."
export PLATFORM_PREFIX=$WORKSPACE/armeabi-v7a-toolchain
export CPPFLAGS="-I$PLATFORM_PREFIX/include -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3"
export LDFLAGS="-L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH

./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make clean
make -j$NBPROC
make install
msg " -> done"

# mips
msg " Building liblcf for MIPS..."
export PLATFORM_PREFIX=$WORKSPACE/mips-toolchain
export PATH=$OLD_PATH
export PATH=$PLATFORM_PREFIX/bin:$PATH
export CPPFLAGS="-I$PLATFORM_PREFIX/include"
export LDFLAGS="-L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
export TARGET_HOST="mipsel-linux-android"
export CC="$TARGET_HOST-clang"
export CXX="$TARGET_HOST-clang++"

./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make clean
make -j$NBPROC
make install
msg " -> done"

cd ..
