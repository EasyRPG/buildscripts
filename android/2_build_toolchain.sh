#!/bin/bash

# abort on error
set -e

export WORKSPACE=$PWD

export NDK_ROOT=$WORKSPACE/android-ndk-r15c
export SDK_ROOT=$WORKSPACE/android-sdk

# Number of CPU
NBPROC=$(getconf _NPROCESSORS_ONLN)

# Setup PATH
PATH=$PATH:$NDK_ROOT:$SDK_ROOT/tools

# Use ccache?
if [ -z ${NO_CCACHE+x} ]; then
	if hash ccache >/dev/null 2>&1; then
		ENABLE_CCACHE=1
		echo "CCACHE enabled"
	fi
fi

if [ ! -f .patches-applied ]; then
	echo "patching libraries"

	# Accept api9 for make_standalone_toolchain
	perl -pi -e 's/min_api = 14/min_api = 9/' ./android-ndk-r15c/build/tools/make_standalone_toolchain.py

	# Patch cpufeatures, hangs in Android 4.0.3
	patch -Np0 < cpufeatures.patch

	# disable pixman examples and tests
	cd pixman-0.34.0
	perl -pi -e 's/SUBDIRS = pixman demos test/SUBDIRS = pixman/' Makefile.am
	autoreconf -fi
	cd ..

	# disable unsupported compiler flags by clang in libvorbis
	cd libvorbis-1.3.5
	perl -pi -e 's/-mno-ieee-fp//' configure
	cd ..

	# update autoconf stuff and preprocessor macro to recognize android
	cd libxmp-lite-4.4.1
	patch -Np1 < ../libxmp-a0288352.patch
	cd ..

	# disable libsndfile examples and tests
	cd libsndfile-1.0.28
	perl -pi -e 's/ examples regtest tests programs//' Makefile.am
	autoreconf -fi
	cd ..

	# Wildmidi: Disable libm
	cd wildmidi-wildmidi-0.4.2
	perl -pi -e 's/FIND_LIBRARY\(M_LIBRARY m REQUIRED\)//' CMakeLists.txt
	cd ..

	# use android config
	cd SDL2-2.0.6
	mv include/SDL_config_android.h include/SDL_config.h
	mkdir -p jni
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

# generic cmake library installer
function install_lib_cmake {
	cd $1
	shift
	rm -rf CMakeCache.txt CMakeFiles/
	cmake . -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=$PLATFORM_PREFIX $@
	make clean
	make -j$NBPROC
	make install
	cd ..
}

# Install mpg123
function install_lib_mpg123 {
	export CPPFLAGSOLD=$CPPFLAGS
	export CPPFLAGS="$CPPFLAGS -DHAVE_MMAP"
	install_lib mpg123-1.25.8 --enable-fifo=no --enable-ipv6=no --enable-network=no \
		--enable-int-quality=no --with-cpu=generic --with-default-audio=dummy
	export CPPFLAGS=$CPPFLAGSOLD
}

# Install SDL2
function install_lib_sdl {
	# $1 => platform (armeabi armeabi-v7a x86 mips)

	cd SDL2-2.0.6
	echo "APP_ABI := $1" >> "jni/Application.mk"
	ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android.mk APP_PLATFORM=android-9
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

	export PATH=$OLD_PATH
	export PLATFORM_PREFIX=$WORKSPACE/$2-toolchain
	$NDK_ROOT/build/tools/make_standalone_toolchain.py --api=9 \
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

	install_lib libpng-1.6.34
	install_lib freetype-2.8.1 --with-harfbuzz=no --without-bzip2
	install_lib pixman-0.34.0
	install_lib_cmake expat-2.2.5 -DBUILD_tools=OFF -DBUILD_examples=OFF \
		-DBUILD_tests=OFF -DBUILD_doc=OFF -DBUILD_shared=OFF
	install_lib libogg-1.3.3
	install_lib libvorbis-1.3.5
	install_lib libsndfile-1.0.28
	install_lib speexdsp-1.2rc3 --disable-sse --disable-neon
	install_lib_mpg123
	install_lib libxmp-lite-4.4.1
	install_lib opus-1.2.1
	install_lib opusfile-0.10
	install_lib_cmake wildmidi-wildmidi-0.4.2 -DWANT_PLAYER=OFF -DWANT_STATIC=ON
	install_lib_sdl "$2"

	# Cross compile ICU
	cd icu/source

	./configure --with-cross-build=$ICU_CROSS_BUILD --enable-strict=no --enable-static --enable-shared=no \
		--enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --enable-extras=no \
		--enable-icuio=no --host=$TARGET_HOST --with-data-packaging=static --prefix=$PLATFORM_PREFIX
	make clean
	make -j$NBPROC
	make install
}

export OLD_PATH=$PATH

# Install host ICU
cd $WORKSPACE

echo "preparing ICU host build"

chmod u+x icu/source/configure
cp -r icu icu-native
cp icudt59l.dat icu/source/data/in/
cp icudt59l.dat icu-native/source/data/in/
cd icu-native/source
perl -pi -e 's/SMALL_BUFFER_MAX_SIZE 512/SMALL_BUFFER_MAX_SIZE 2048/' tools/toolutil/pkg_genc.h
# glibc 2.26 removed xlocale.h: https://ssl.icu-project.org/trac/ticket/13329
perl -pi -e 's/xlocale/locale/' i18n/digitlst.cpp
./configure --enable-static --enable-shared=no --enable-tests=no --enable-samples=no \
	--enable-dyload=no --enable-tools --enable-extras=no --enable-icuio=no \
	--with-data-packaging=static
make -j$NBPROC
export ICU_CROSS_BUILD=$PWD

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
# Install standalone toolchain MIPS

build "MIPS" "mips" "mips" "mipsel-linux-android" ""
