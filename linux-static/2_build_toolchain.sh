#!/bin/bash

# abort on error
set -e

export WORKSPACE=$PWD

# Number of CPU
nproc=$(nproc)

# Use ccache?
if [ -z ${NO_CCACHE+x} ]; then
	if hash ccache >/dev/null 2>&1; then
		ENABLE_CCACHE=1
		echo "CCACHE enabled"
	fi
fi

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	# disable pixman examples and tests
	cd pixman-0.34.0
	perl -pi -e 's/SUBDIRS = .*/SUBDIRS = pixman/' Makefile.am
	autoreconf -fi
	cd ..

	# disable png utils
	cd libpng-1.6.34
	perl -pi -e 's/^bin_PROGRAMS.*//' Makefile.am
	autoreconf -fi
	cd ..

	# disable harfbuzz utils and tests
	cd harfbuzz-1.5.1
	perl -pi -e 's/SUBDIRS = .*/SUBDIRS = src/' Makefile.am
	autoreconf -fi
	cd ..

	# disable unsupported compiler flags by clang in libvorbis
	perl -pi -e 's/-mno-ieee-fp//' libvorbis-1.3.5/configure

	# fix building
	patch -Np1 -d libxmp-lite-4.4.1 < libxmp-a0288352.patch

	# disable libsndfile examples and tests
	cd libsndfile-1.0.28
	perl -pi -e 's/ examples regtest tests programs//' Makefile.am
	autoreconf -fi
	cd ..

	# Wildmidi: Disable libm
	perl -pi -e 's/FIND_LIBRARY\(M_LIBRARY m REQUIRED\)//' wildmidi-wildmidi-0.4.1/CMakeLists.txt

	# ICU
	cp icudt59l.dat icu/source/data/in
	cd icu/source
	chmod u+x configure
	perl -pi -e 's/SMALL_BUFFER_MAX_SIZE 512/SMALL_BUFFER_MAX_SIZE 2048/' tools/toolutil/pkg_genc.h
	# glibc 2.26 removed xlocale.h: https://ssl.icu-project.org/trac/ticket/13329
	perl -pi -e 's/xlocale/locale/' i18n/digitlst.cpp
	cd ../..

	touch .patches-applied
fi

# generic autotools library installer
function install_lib {
	echo ""
	echo "**** Building ${1%-*} ****"
	echo ""

	cd $1
	shift
	./configure --prefix=$WORKSPACE --disable-shared --enable-static \
		--disable-dependency-tracking --enable-silent-rules \
		--cache-file="$WORKSPACE/config.cache" $@
	make clean
	make
	make install
	cd ..

	echo " -> done"
}

# generic cmake library installer
function install_lib_cmake {
	echo ""
	echo "**** Building ${1%-*} ****"
	echo ""

	cd $1
	shift
	rm -rf CMakeCache.txt CMakeFiles/
	cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_SHARED_LIBS=OFF \
		-DCMAKE_INSTALL_PREFIX=$WORKSPACE $@
	make clean
	make
	make install
	cd ..

	echo " -> done"
}

function install_lib_zlib {
	echo ""
	echo "**** Building zlib ****"
	echo ""

	cd zlib-1.2.11
	./configure --static --prefix=$WORKSPACE
	make clean
	make
	make install
	cd ..

	echo " -> done"
}

cd $WORKSPACE

echo "Preparing toolchain"

export CFLAGS="-Os -g0 -ffunction-sections -fdata-sections"
export CXXFLAGS=$CFLAGS
export MAKEFLAGS="-j${nproc:-2}"
export PKG_CONFIG_PATH=$WORKSPACE/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH
if [ "$ENABLE_CCACHE" ]; then
	export CC="ccache gcc"
	export CXX="ccache g++"
fi

install_lib_zlib
install_lib libpng-1.6.34
install_lib freetype-2.8.1 --without-harfbuzz --without-bzip2 --without-png --without-zlib
install_lib harfbuzz-1.5.1 --without-glib --without-gobject --without-cairo --without-fontconfig --without-icu
install_lib freetype-2.8.1 --with-harfbuzz --without-bzip2 --without-png --without-zlib
install_lib pixman-0.34.0 --disable-libpng
install_lib_cmake expat-2.2.4 -DBUILD_tools=OFF -DBUILD_examples=OFF \
	-DBUILD_tests=OFF -DBUILD_doc=OFF -DBUILD_shared=OFF
install_lib libogg-1.3.2
install_lib libvorbis-1.3.5
install_lib libsndfile-1.0.28
install_lib speexdsp-1.2rc3 --disable-sse --disable-neon
install_lib mpg123-1.25.7 --with-cpu=generic --enable-fifo=no --enable-ipv6=no --enable-network=no \
	--enable-int-quality=no --with-default-audio=dummy --with-optimization=2
install_lib libxmp-lite-4.4.1
# this allows our minimal Player build with the lite version, while using the full version otherwise
mv $WORKSPACE/lib/pkgconfig/libxmp-lite.pc $WORKSPACE/lib/pkgconfig/libxmp.pc
install_lib opus-1.2.1 --disable-intrinsics
install_lib opusfile-0.9 --disable-http
install_lib_cmake wildmidi-wildmidi-0.4.1 -DWANT_PLAYER=OFF -DWANT_STATIC=ON
install_lib SDL2-2.0.6
install_lib SDL2_mixer-2.0.1 --with-sdl-prefix=$WORKSPACE --disable-music-ogg \
	--disable-music-midi-fluidsynth --disable-music-midi-fluidsynth-shared \
	--disable-music-mod --disable-music-mp3 --disable-music-flac --disable-sdltest
install_lib SDL2_image-2.0.1 --disable-jpg --disable-png-shared --disable-tif --disable-webp
install_lib icu/source --enable-strict=no --disable-tests --disable-samples \
	--disable-dyload --enable-tools --disable-extras --disable-icuio \
	--with-data-packaging=static --disable-layout --disable-layoutex
