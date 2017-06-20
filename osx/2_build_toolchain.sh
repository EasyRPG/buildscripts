#!/bin/bash

if [ "$(uname)" != "Darwin" ]; then
	echo "This buildscript requires MacOSX"
	exit 1
fi

# abort on error
set -e

export WORKSPACE=$PWD

export PLATFORM_PREFIX=$WORKSPACE
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH

# Number of CPU
NBPROC=$(getconf _NPROCESSORS_ONLN)

# Use ccache?
if [ -z ${NO_CCACHE+x} ]; then
	if hash ccache >/dev/null 2>&1; then
		ENABLE_CCACHE=1
		echo "CCACHE enabled"
	fi
fi

if [ ! -f .patches-applied ]; then
	echo "patching libraries"

	# disable pixman examples and tests
	cd pixman-0.34.0
	perl -pi -e 's/SUBDIRS = pixman demos test/SUBDIRS = pixman/' Makefile.am
	autoreconf -fi
	cd ..

	# disable png utils
	cd libpng-1.6.29
	perl -pi -e 's/^bin_PROGRAMS/# $&/' Makefile.am
	autoreconf -fi
	cd ..

	# disable libsndfile examples and tests
	cd libsndfile-1.0.28
	perl -pi -e 's/ examples regtest tests programs//' Makefile.am
	autoreconf -fi
	cd ..

	# disable SDL2 mixer examples
	patch -Np0 < SDL2_mixer.patch
	cd SDL2_mixer-2.0.1
	autoreconf -fi
	cd ..

	# Fix expat 2.2.1 compilation on MacOSX
	patch -Np0 < expat-2.2.1-osx.patch

	# Fix libxmp-lite compilation
	patch -Np0 < libxmp-a0288352.patch

	touch .patches-applied
fi

function set_build_flags {
	CLANG=`xcodebuild -find clang`
	CLANGXX=`xcodebuild -find clang++`
	ARCH="-arch i386 -arch x86_64"
	SDKPATH=`xcrun -sdk macosx10.12 --show-sdk-path`

	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $CLANG $ARCH"
		export CXX="ccache $CLANGXX $ARCH"
	else
		export CC="$CLANG $ARCH"
		export CXX="$CLANGXX $ARCH"
	fi

	export CPP="$CLANG -arch i386 -E"
	export CXXCPP="$CLANGXX -arch i386 -E"

	export CFLAGS="-I$WORKSPACE/include -g -O2 -mmacosx-version-min=10.9 -isysroot $SDKPATH"
	export CPPFLAGS="$CFLAGS"
	export CXXFLAGS="$CFLAGS"
	export LDFLAGS="-L$WORKSPACE/lib $ARCH -mmacosx-version-min=10.9 -isysroot $SDKPATH"

	if [ "$NBPROC" ]; then
		export MAKEFLAGS="-j$NBPROC"
	fi
}

# Default lib installer
function install_lib {
	echo ""
	echo "**** Building ${1%-*} ****"
	echo ""

	cd $1
	shift
	./configure --prefix=$PLATFORM_PREFIX \
		--disable-shared --enable-static $@
	make clean
	make
	make install
	cd ..

	echo " -> done"
}

# Install zlib
function install_lib_zlib {
	echo ""
	echo "**** Building zlib ****"
	echo ""

	cd zlib-1.2.11
	./configure --static --prefix=$PLATFORM_PREFIX
	make clean
	make
	make install
	cd ..

	echo " -> done"
}

# Install ICU
function install_lib_icu() {
	echo ""
	echo "**** Building ICU ****"
	echo ""

	# No crosscompile needed. Runs native on this platform
	cp icudt59l.dat icu/source/data/in/
	cd icu/source
	perl -pi -e 's/SMALL_BUFFER_MAX_SIZE 512/SMALL_BUFFER_MAX_SIZE 2048/' tools/toolutil/pkg_genc.h
	chmod u+x configure
	./configure --enable-strict=no \
		--enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no \
		--enable-tools=yes --enable-extras=no --enable-icuio=no \
		--with-data-packaging=static --prefix=$PLATFORM_PREFIX

	make clean
	make
	make install
	cd ../..

	echo " -> done"
}

function install_lib_wildmidi() {
	echo ""
	echo "**** Building WildMidi ****"
	echo ""

	cd wildmidi-wildmidi-0.4.1
	cmake . -DCMAKE_SYSTEM_NAME=Generic -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWANT_PLAYER=OFF
	make clean
	make
	cp include/wildmidi_lib.h $WORKSPACE/include
	cp libWildMidi.a $WORKSPACE/lib
	cd ..

	echo " -> done"
}

# create needed directory structure
mkdir -p bin include lib share

set_build_flags
# Install libraries
install_lib_zlib
install_lib libpng-1.6.29
install_lib freetype-2.6.5 --with-harfbuzz=no --without-bzip2
install_lib harfbuzz-1.3.2
install_lib freetype-2.6.5 --with-harfbuzz=yes --without-bzip2
install_lib pixman-0.34.0
install_lib expat-2.2.1
install_lib libogg-1.3.2
install_lib libvorbis-1.3.5
install_lib_icu
install_lib mpg123-1.25.0 --enable-fifo=no --enable-ipv6=no --enable-network=no \
	--enable-int-quality=no --with-cpu=generic --with-default-audio=dummy
install_lib libsndfile-1.0.28
install_lib speexdsp-1.2rc3
install_lib_wildmidi
install_lib libxmp-lite-4.4.1
install_lib SDL2-2.0.5
install_lib SDL2_mixer-2.0.1 --disable-sdltest --disable-music-ogg --disable-music-flac \
	--disable-music-midi-fluidsynth --disable-music-midi-fluidsynth-shared \
	--disable-music-mod --disable-music-mp3

# Post build steps
# Allow detection of libxmp-lite as libxmp
mv $WORKSPACE/lib/pkgconfig/libxmp-lite.pc $WORKSPACE/lib/pkgconfig/libxmp.pc
