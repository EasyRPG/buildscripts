#!/bin/bash

# abort on error
set -e

export WORKSPACE=$PWD

export NDK_ROOT=$WORKSPACE/android-ndk-r10e
export SDK_ROOT=$WORKSPACE/android-sdk

# Number of CPU
NBPROC=$(getconf _NPROCESSORS_ONLN)

# Setup PATH
PATH=$PATH:$NDK_ROOT:$SDK_ROOT/tools

# Use ccache?
hash ccache >/dev/null 2>&1
if [ $? -eq 0 -a x$NO_CCACHE = x ]; then
	ENABLE_CCACHE=1
fi

if [ ! -f .patches-applied ]; then
	echo "patching libraries"

	# Patch cpufeatures, hangs in Android 4.0.3
	patch -Np0 < cpufeatures.patch

	# disable pixman examples and tests
	cd pixman-0.34.0
	sed -i.bak 's/SUBDIRS = pixman demos test/SUBDIRS = pixman/' Makefile.am
	autoreconf -fi
	cd ..

	# use android config
	cd SDL
	mv include/SDL_config_android.h include/SDL_config.h
	mkdir -p jni
	cd ..

	# enable jni config loading
	cd SDL_mixer
	patch -Np1 -d timidity < ../timidity-android.patch
	patch -Np0 < ../sdl-mixer-config.patch
	sh autogen.sh
	cd ..

	touch .patches-applied
fi

# generic autotools library installer
function install_lib {
	cd $1
	shift
	./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static $@
	make clean
	make -j$NBPROC
	make install
	cd ..
}

# Install mpg123
function install_lib_mpg123() {
	cd mpg123-1.23.6
	CPPFLAGS="$CPPFLAGS -DHAVE_MMAP" ./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX \
		--disable-shared --enable-static \
		--enable-fifo=no --enable-ipv6=no --enable-network=no --enable-int-quality=no \
		--with-cpu=generic --with-default-audio=dummy
	make clean
	make -j$NBPROC
	make install
	cd ..
}

# Install SDL2
function install_lib_sdl {
	# $1 => platform (armeabi armeabi-v7a x86 mips)

	cd SDL
	echo "APP_STL := gnustl_static" > "jni/Application.mk"
	echo "APP_ABI := $1" >> "jni/Application.mk"
	ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android.mk APP_PLATFORM=android-9
	mkdir -p $PLATFORM_PREFIX/lib
	mkdir -p $PLATFORM_PREFIX/include/SDL2
	cp libs/$1/* $PLATFORM_PREFIX/lib/
	cp include/* $PLATFORM_PREFIX/include/SDL2/
	cd ..
}

# Install SDL2_mixer
function install_lib_mixer() {
	cd SDL_mixer
	SDL_CFLAGS="-I $PLATFORM_PREFIX/include/SDL2" SDL_LIBS="-lSDL2" \
		./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static \
		--disable-sdltest --disable-music-mp3
	make clean
	make -j$NBPROC
	make install
	cd ..
}

export OLD_PATH=$PATH

# Install host ICU
cd $WORKSPACE

echo "preparing ICU host build"

chmod u+x icu/source/configure
cp -r icu icu-native
cp icudt56l.dat icu/source/data/in/
cp icudt56l.dat icu-native/source/data/in/
cd icu-native/source
sed -i 's/SMALL_BUFFER_MAX_SIZE 512/SMALL_BUFFER_MAX_SIZE 2048/' tools/toolutil/pkg_genc.h
./configure --enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools --enable-extras=no --enable-icuio=no --with-data-packaging=static
make -j$NBPROC
export ICU_CROSS_BUILD=$PWD

####################################################
# Install standalone toolchain x86
cd $WORKSPACE

echo "preparing x86 toolchain"

export PLATFORM_PREFIX=$WORKSPACE/x86-toolchain
$NDK_ROOT/build/tools/make-standalone-toolchain.sh --platform=android-9 --ndk-dir=$NDK_ROOT --toolchain=x86-4.9 --install-dir=$PLATFORM_PREFIX --stl=gnustl

export PATH=$PLATFORM_PREFIX/bin:$PATH

export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/support/include"
export LDFLAGS="-L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
export TARGET_HOST="i686-linux-android"
if [ x$ENABLE_CCACHE = x1 ]; then
	export CC="ccache $TARGET_HOST-gcc"
	export CXX="ccache $TARGET_HOST-g++"
fi

install_lib libpng-1.6.24
install_lib freetype-2.6.5 --with-harfbuzz=no --without-bzip2
install_lib pixman-0.34.0
install_lib libogg-1.3.2
install_lib libvorbis-1.3.5
install_lib libmodplug-0.8.8.5
install_lib libsndfile-1.0.27
install_lib speexdsp-1.2rc3 --enable-sse --disable-neon
install_lib_mpg123
install_lib_sdl "x86"
install_lib_mixer

# Cross compile ICU
cd icu/source

export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/cxx-stl/stlport/stlport -O3 -fno-short-wchar -DU_USING_ICU_NAMESPACE=0 -DU_GNUC_UTF16_STRING=0 -fno-short-enums -nostdlib"
export LDFLAGS="-lc -Wl,-rpath-link=$PLATFORM_PREFIX/lib -L$PLATFORM_PREFIX/lib/"

./configure --with-cross-build=$ICU_CROSS_BUILD --enable-strict=no --enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --enable-extras=no --enable-icuio=no --host=$TARGET_HOST --with-data-packaging=static --prefix=$PLATFORM_PREFIX
make clean
make -j$NBPROC
make install

################################################################
# Install standalone toolchain ARMeabi

cd $WORKSPACE

echo "preparing ARMeabi toolchain"

export PATH=$OLD_PATH
export PLATFORM_PREFIX=$WORKSPACE/armeabi-toolchain
$NDK_ROOT/build/tools/make-standalone-toolchain.sh --platform=android-9 --ndk-dir=$NDK_ROOT --toolchain=arm-linux-androideabi-4.9 --install-dir=$PLATFORM_PREFIX  --stl=gnustl
export PATH=$PLATFORM_PREFIX/bin:$PATH

export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/support/include -I$NDK_ROOT/sources/android/cpufeatures"
export LDFLAGS="-L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
export TARGET_HOST="arm-linux-androideabi"
if [ x$ENABLE_CCACHE = x1 ]; then
	export CC="ccache $TARGET_HOST-gcc"
	export CXX="ccache $TARGET_HOST-g++"
fi

install_lib libpng-1.6.24
install_lib freetype-2.6.5 --with-harfbuzz=no --without-bzip2
install_lib pixman-0.34.0
install_lib libogg-1.3.2
install_lib libvorbis-1.3.5
install_lib libmodplug-0.8.8.5
install_lib libsndfile-1.0.27
install_lib speexdsp-1.2rc3 --disable-sse --disable-neon
install_lib_mpg123
install_lib_sdl "armeabi"
install_lib_mixer

# Cross compile ICU
cd icu/source

export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/cxx-stl/stlport/stlport -O3 -fno-short-wchar -DU_USING_ICU_NAMESPACE=0 -DU_GNUC_UTF16_STRING=0 -fno-short-enums -nostdlib"
export LDFLAGS="-lc -Wl,-rpath-link=$PLATFORM_PREFIX/lib -L$PLATFORM_PREFIX/lib/"

./configure --with-cross-build=$ICU_CROSS_BUILD --enable-strict=no --enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --enable-extras=no --enable-icuio=no --host=$TARGET_HOST --with-data-packaging=static --prefix=$PLATFORM_PREFIX
make clean
make -j$NBPROC
make install

################################################################
# Install standalone toolchain ARMeabi-v7a
cd $WORKSPACE

echo "preparing ARMeabi-v7a toolchain"

# Setting up new toolchain not required, only difference is CPPFLAGS

export PLATFORM_PREFIX_ARM=$WORKSPACE/armeabi-toolchain
export PLATFORM_PREFIX=$WORKSPACE/armeabi-v7a-toolchain

export CPPFLAGS="-I$PLATFORM_PREFIX_ARM/include -I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/support/include -I$NDK_ROOT/sources/android/cpufeatures -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3"
export LDFLAGS="-L$PLATFORM_PREFIX_ARM/lib -L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
export TARGET_HOST="arm-linux-androideabi"
if [ x$ENABLE_CCACHE = x1 ]; then
	export CC="ccache $TARGET_HOST-gcc"
	export CXX="ccache $TARGET_HOST-g++"
fi

install_lib libpng-1.6.24
install_lib freetype-2.6.5 --with-harfbuzz=no --without-bzip2
install_lib pixman-0.34.0
install_lib libogg-1.3.2
install_lib libvorbis-1.3.5
install_lib libmodplug-0.8.8.5
install_lib libsndfile-1.0.27
install_lib speexdsp-1.2rc3 --disable-sse --enable-neon
install_lib_mpg123
install_lib_sdl "armeabi-v7a"
install_lib_mixer

# Cross compile ICU
cd icu/source

export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/cxx-stl/stlport/stlport -O3 -fno-short-wchar -DU_USING_ICU_NAMESPACE=0 -DU_GNUC_UTF16_STRING=0 -fno-short-enums -nostdlib -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3"
export LDFLAGS="-lc -Wl,-rpath-link=$PLATFORM_PREFIX/lib -L$PLATFORM_PREFIX/lib/"

./configure --with-cross-build=$ICU_CROSS_BUILD --enable-strict=no --enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --enable-extras=no --enable-icuio=no --host=$TARGET_HOST --with-data-packaging=static --prefix=$PLATFORM_PREFIX
make clean
make -j$NBPROC
make install

################################################################
# Install standalone toolchain MIPS
cd $WORKSPACE

echo "preparing MIPS toolchain"

export PATH=$OLD_PATH
export PLATFORM_PREFIX=$WORKSPACE/mips-toolchain
$NDK_ROOT/build/tools/make-standalone-toolchain.sh --platform=android-9 --ndk-dir=$NDK_ROOT --toolchain=mipsel-linux-android-4.9 --install-dir=$PLATFORM_PREFIX  --stl=gnustl
export PATH=$PLATFORM_PREFIX/bin:$PATH

export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/support/include -I$NDK_ROOT/sources/android/cpufeatures"
export LDFLAGS="-L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
export TARGET_HOST="mipsel-linux-android"
if [ x$ENABLE_CCACHE = x1 ]; then
	export CC="ccache $TARGET_HOST-gcc"
	export CXX="ccache $TARGET_HOST-g++"
fi

install_lib libpng-1.6.24
install_lib freetype-2.6.5 --with-harfbuzz=no --without-bzip2
install_lib pixman-0.34.0
install_lib libogg-1.3.2
install_lib libvorbis-1.3.5
install_lib libmodplug-0.8.8.5
install_lib libsndfile-1.0.27
install_lib speexdsp-1.2rc3 --disable-sse --disable-neon
install_lib_mpg123
install_lib_sdl "mips"
install_lib_mixer

# Cross compile ICU
cd icu/source

export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/cxx-stl/stlport/stlport -O3 -fno-short-wchar -DU_USING_ICU_NAMESPACE=0 -DU_GNUC_UTF16_STRING=0 -fno-short-enums -nostdlib"
export LDFLAGS="-lc -Wl,-rpath-link=$PLATFORM_PREFIX/lib -L$PLATFORM_PREFIX/lib/"

./configure --with-cross-build=$ICU_CROSS_BUILD --enable-strict=no --enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --enable-extras=no --enable-icuio=no --host=$TARGET_HOST --with-data-packaging=static --prefix=$PLATFORM_PREFIX
make clean
make -j$NBPROC
make install

################################################################
# Cleanup library build folders and other stuff

cd $WORKSPACE
rm -rf freetype-*/ harfbuzz-*/ icu/ icu-native/ libmodplug-*/ libogg-*/ libpng-*/ libvorbis-*/ pixman-*/ mpg123-*/ libsndfile-*/ speexdsp-*/ SDL/ SDL_mixer/ .patches-applied
rm -f *.bz2 *.gz *.xz *.tgz *.bin icudt*
