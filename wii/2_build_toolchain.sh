#!/bin/bash

# abort on error
set -e

export WORKSPACE=$PWD

export DEVKITPRO=${WORKSPACE}/devkitPro
export DEVKITPPC=${DEVKITPRO}/devkitPPC
export PATH=$DEVKITPPC/bin:$PATH

export PLATFORM_PREFIX=$WORKSPACE
export TARGET_HOST=powerpc-eabi
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

	cp -rup icu icu-native
	# Fix ICU compilation problems on Wii
	patch -Np0 < icu-wii.patch
	# Emit correct bigendian icudata header
	patch -Np0 < icu-pkg_genc.patch

	# disable pixman examples and tests
	cd pixman-0.34.0
	perl -pi -e 's/SUBDIRS = pixman demos test/SUBDIRS = pixman/' Makefile.am
	autoreconf -fi
	cd ..

	# disable png utils
	cd libpng-1.6.24
	perl -pi -e 's/^bin_PROGRAMS/# $&/' Makefile.am
	autoreconf -fi
	cd ..

	# Fix mpg123 compilation
	patch -Np0 < mpg123.patch

	# Fix libsndfile compilation
	patch -Np0 < libsndfile.patch

	# Fix wildmidi linking
	patch -Np0 < wildmidi.patch

	# Patch SDL+SDL_mixer
	cd sdl-wii
	git reset --hard
	cd ..
	patch --binary -Np0 < sdl-wii.patch

	touch .patches-applied
fi

function set_build_flags {
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $TARGET_HOST-gcc"
		export CXX="ccache $TARGET_HOST-g++"
	else
		export CC="$TARGET_HOST-gcc"
		export CXX="$TARGET_HOST-g++"
	fi
	export CFLAGS="-I$WORKSPACE/include -g -O2 -DGEKKO"
	export CPPFLAGS="$CFLAGS"
	export LDFLAGS="-L$WORKSPACE/lib"
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
	./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX \
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
	CHOST=$TARGET_HOST ./configure --static --prefix=$PLATFORM_PREFIX
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

	# Compile native version
	unset CC
	unset CXX
	unset CFLAGS
	unset CPPFLAGS
	unset LDFLAGS

	cp icudt58l.dat icu/source/data/in/
	cp icudt58l.dat icu-native/source/data/in/
	cd icu-native/source
	perl -pi -e 's/SMALL_BUFFER_MAX_SIZE 512/SMALL_BUFFER_MAX_SIZE 2048/' tools/toolutil/pkg_genc.h
	# glibc 2.26 removed xlocale.h: https://ssl.icu-project.org/trac/ticket/13329
	perl -pi -e 's/xlocale/locale/' i18n/digitlst.cpp
	chmod u+x configure
	CPPFLAGS="-DBUILD_DATA_WITHOUT_ASSEMBLY -DU_DISABLE_OBJ_CODE" ./configure \
		--enable-static --enable-shared=no --enable-tests=no --enable-samples=no \
		--enable-dyload=no --enable-tools --enable-extras=no --enable-icuio=no \
		--with-data-packaging=static
	make
	export ICU_CROSS_BUILD=$PWD

	# Cross compile
	set_build_flags

	cd ../../icu/source

	cp config/mh-linux config/mh-unknown

	chmod u+x configure
	./configure --with-cross-build=$ICU_CROSS_BUILD --enable-strict=no \
		--enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no \
		--enable-tools=no --enable-extras=no --enable-icuio=no --host=$TARGET_HOST \
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

	cd wildmidi-wildmidi-0.4.0
	cmake . -DCMAKE_SYSTEM_NAME=Generic -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWANT_PLAYER=OFF
	make clean
	make
	cp -up include/wildmidi_lib.h $WORKSPACE/include
	cp -up libWildMidi.a $WORKSPACE/lib
	cd ..

	echo " -> done"
}

function install_lib_sdl() {
	echo ""
	echo "**** Building SDL ****"
	echo ""

	cd sdl-wii/SDL
	make clean
	make install INSTALL_HEADER_DIR="$WORKSPACE/include" INSTALL_LIB_DIR="$WORKSPACE/lib"
	cd ../..

	echo " -> done"
}

function install_lib_sdlmixer() {
	echo ""
	echo "**** Building SDL_mixer ****"
	echo ""

	cd sdl-wii/SDL_mixer
	make clean
	make install INSTALL_HEADER_DIR="$WORKSPACE/include" INSTALL_LIB_DIR="$WORKSPACE/lib"
	cd ../..

	echo " -> done"
}

# create needed directory structure
mkdir -p bin include lib share

set_build_flags
# Install libraries
install_lib_zlib
install_lib libpng-1.6.24
install_lib freetype-2.6.5 --with-harfbuzz=no --without-bzip2
install_lib pixman-0.34.0 --disable-vmx
install_lib expat-2.2.0
install_lib tremor-lowmem
install_lib_icu
install_lib mpg123-1.23.6 --enable-fifo=no --enable-ipv6=no --enable-network=no \
	--enable-int-quality=no --with-cpu=generic --with-default-audio=dummy
install_lib libsndfile-1.0.27
install_lib speexdsp-1.2rc3
install_lib_wildmidi
install_lib libxmp-lite-4.4.0
install_lib_sdl
install_lib_sdlmixer
