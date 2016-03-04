#!/bin/bash
export WORKSPACE=$PWD
export NDK_ROOT=$WORKSPACE/android-ndk-r10e

git clone https://github.com/EasyRPG/liblcf.git

cd liblcf

# x86
export PLATFORM_PREFIX=$WORKSPACE/x86-toolchain
export OLD_PATH=$PATH
export PATH=$PLATFORM_PREFIX/bin:$PATH
export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/support/include"
export LDFLAGS="-L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export TARGET_HOST="i686-linux-android"

autoreconf -i
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static --disable-xml
make -j2
make install

# armeabi
export PLATFORM_PREFIX=$WORKSPACE/armeabi-toolchain
export PATH=$OLD_PATH
export PATH=$PLATFORM_PREFIX/bin:$PATH
export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/support/include"
export LDFLAGS="-L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export TARGET_HOST="arm-linux-androideabi"

./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static --disable-xml
make clean
make -j2
make install

# armeabi-v7a
export PLATFORM_PREFIX_ARM=$WORKSPACE/armeabi-toolchain
export PLATFORM_PREFIX=$WORKSPACE/armeabi-v7a-toolchain
export CPPFLAGS="-I$PLATFORM_PREFIX_ARM/include -I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/support/include -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3"
export LDFLAGS="-L$PLATFORM_PREFIX_ARM/lib -L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static --disable-xml
make clean
make -j2
make install

# mips
export PLATFORM_PREFIX=$WORKSPACE/mips-toolchain
export PATH=$OLD_PATH
export PATH=$PLATFORM_PREFIX/bin:$PATH
export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/support/include"
export LDFLAGS="-L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export TARGET_HOST="mipsel-linux-android"

./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static --disable-xml
make clean
make -j2
make install


cd ..