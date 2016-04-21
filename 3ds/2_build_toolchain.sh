#!/bin/bash

# abort on error
set -e

export WORKSPACE=$PWD

export DEVKITPRO=${WORKSPACE}/devkitPro
export DEVKITARM=${DEVKITPRO}/devkitARM
export PATH=$DEVKITARM/bin:$PATH

export PLATFORM_PREFIX=$WORKSPACE
export TARGET_HOST=arm-none-eabi
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig

# Number of CPU
NBPROC=$(getconf _NPROCESSORS_ONLN)

if [ ! -f .patches-applied ]; then
	echo "patching libraries"

	# Fix compilation problems on 3DS
	cp -r icu icu-native
	patch -Np0 < icu.patch

	# disable pixman examples and tests
	cd pixman-0.34.0
	sed -i.bak 's/SUBDIRS = pixman demos test/SUBDIRS = pixman/' Makefile.am
	autoreconf -fi
	cd ..

	# Fix broken load_abc.cpp
	patch -Np0 < libmodplug.patch

	# Give libkhax a proper makefile
	patch -Np0 < lpp_khax.patch

	# Fix mpg123 compilation
	patch -Np0 < mpg123.patch

	touch .patches-applied
fi

function set_build_flags {
	export CFLAGS="-I$WORKSPACE/include -g0 -O2 -mword-relocations -fomit-frame-pointer -ffast-math -march=armv6k -mtune=mpcore -mfloat-abi=hard"
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

function install_lib_ctru() {
	cd ctrulib/libctru/
	make clean
	make -j$NBPROC
	cp -r include/* ../../include/
	cp -r lib/* ../../lib/
	cd ../..
}

function install_lib_sf2d() {
	cd sf2dlib/libsf2d/
	make clean
	make
	cp -r include/* ../../include/
	cp -r lib/* ../../lib/
	cd ../..
}

function install_lib_khax() {
	cd lpp-3ds_libraries
	make clean
	make
	cp source_libkhax/*.h ../include/
	cp -r lib/* ../lib/
	cd ..
}

set_build_flags
# Install libraries

install_lib_zlib
# Installs important system headers but does not create include/lib dir (zlib does this)
install_lib_ctru
install_lib "libpng-1.6.21"
install_lib "freetype-2.6.3" "--with-harfbuzz=no"
install_lib "pixman-0.34.0" "--disable-arm-neon --disable-arm-simd"
install_lib "tremor-lowmem"
install_lib "libogg-1.3.2"
install_lib "libmodplug-0.8.8.5"
install_lib_icu
install_lib "mpg123-1.23.3" "--enable-fifo=no --enable-ipv6=no --enable-network=no --enable-int-quality=no --with-cpu=generic --with-default-audio=dummy"
install_lib_sf2d
install_lib_khax
