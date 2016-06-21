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

# Number of CPU
NBPROC=$(getconf _NPROCESSORS_ONLN)

if [ ! -f .patches-applied ]; then
	echo "patching libraries"

	cp -r icu icu-native

	# Fix ICU compilation problems on Wii
	patch -Np0 < icu-wii.patch

	# Byte swap to generate proper icudata
	patch -Np0 < icu-pkg_genc.patch

	# disable pixman examples and tests
	cd pixman-0.34.0
	sed -i.bak 's/SUBDIRS = pixman demos test/SUBDIRS = pixman/' Makefile.am
	autoreconf -fi
	cd ..

	# Fix broken load_abc.cpp
	patch -Np0 < libmodplug.patch

	# Fix mpg123 compilation
	patch -Np0 < mpg123.patch

	# Fix libsndfile compilation
	patch -Np0 < libsndfile.patch

	# Fix iconv compilation
	patch -Np0 < libiconv.patch

	# Patch SDL+SDL_mixer
	cd sdl-wii
	git reset --hard
	cd ..
	patch --binary -p0 -i sdl-wii.patch

	touch .patches-applied
fi

function set_build_flags {
	export CFLAGS="-I$WORKSPACE/include -g0 -O2 -DGEKKO"
	export CPPFLAGS="$CFLAGS"
	export LDFLAGS="-L$WORKSPACE/lib"
}

# Default lib installer
function install_lib {
	cd $1
	./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static $2
	make clean
	make -j$NBPRO
	make install
	cd ..
}

# Install zlib
function install_lib_zlib {
	cd zlib-1.2.8
	CHOST=$TARGET_HOST ./configure --static --prefix=$PLATFORM_PREFIX
	make clean
	make -j$NBPROC
	make install
	cd ..
}

# Install ICU
function install_lib_icu() {
	# Compile native version
        unset CFLAGS
        unset CPPFLAGS
        unset LDFLAGS

	cp icudt56l.dat icu/source/data/in/
	cp icudt56l.dat icu-native/source/data/in/
	cd icu-native/source
	sed -i.bak 's/SMALL_BUFFER_MAX_SIZE 512/SMALL_BUFFER_MAX_SIZE 2048/' tools/toolutil/pkg_genc.h
	chmod u+x configure
	./configure --enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools --enable-extras=no --enable-icuio=no --with-data-packaging=static
	make -j$NBPROC
	export ICU_CROSS_BUILD=$PWD

	# Cross compile
	set_build_flags

	cd ../../icu/source

	cp config/mh-linux config/mh-unknown

	chmod u+x configure
	./configure --with-cross-build=$ICU_CROSS_BUILD --enable-strict=no --enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --enable-extras=no --enable-icuio=no --host=$TARGET_HOST --with-data-packaging=static --prefix=$PLATFORM_PREFIX
	make clean
	make -j$NBPROC
	make install
	cd ../..
}

function install_lib_sdl() {
	cd sdl-wii/SDL
	make install INSTALL_HEADER_DIR="$WORKSPACE/include" INSTALL_LIB_DIR="$WORKSPACE/lib"
	cd ../..
}

function install_lib_sdlmixer() {
	cd sdl-wii/SDL_mixer
	make install INSTALL_HEADER_DIR="$WORKSPACE/include" INSTALL_LIB_DIR="$WORKSPACE/lib"
	cd ../..
}

set_build_flags
# Install libraries
install_lib_zlib
install_lib "libpng-1.6.23"
install_lib "freetype-2.6.3" "--with-harfbuzz=no"
install_lib "pixman-0.34.0" "--disable-vmx"
install_lib "tremor-lowmem"
install_lib "libogg-1.3.2"
install_lib "libmodplug-0.8.8.5"
install_lib_icu
install_lib "mpg123-1.23.3" "--enable-fifo=no --enable-ipv6=no --enable-network=no --enable-int-quality=no --with-cpu=generic --with-default-audio=dummy"
install_lib "libsndfile-1.0.27"
install_lib "speexdsp-1.2rc3"
install_lib "libiconv-1.14"
install_lib_sdl
install_lib_sdlmixer
