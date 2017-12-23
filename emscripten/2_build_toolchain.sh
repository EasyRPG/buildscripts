#!/bin/bash

# abort on error
set -e

export WORKSPACE=$PWD

# Number of CPU
nproc=$(nproc)

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

	# disable unsupported compiler flags by clang in libvorbis
	perl -pi -e 's/-mno-ieee-fp//' libvorbis-1.3.5/configure

	# disable unsupported compiler flags by clang in libogg
	perl -pi -e 's/-O20/-g0 -O2/g' libogg-1.3.2/configure

	# fix libxmp building
	patch -Np1 -d libxmp-lite-4.4.1 < libxmp-a0288352.patch

	# disable libsndfile examples and tests and fix building
	cd libsndfile-1.0.28
	patch -Np1 < ../libsndfile.patch
	autoreconf -fi
	cd ..

	# hack to not use hidden funtion
	# (see https://groups.google.com/forum/#!topic/emscripten-discuss/YM3jC_qQoPk)
	perl -pi -e 's/HAVE_ARC4RANDOM\)/NO_ARC4RANDOM\)/' expat-2.2.5/ConfigureChecks.cmake

	cp -rup icu icu-native

	# disable harfbuzz utils and tests
	#cd harfbuzz-1.5.1
	#perl -pi -e 's/SUBDIRS = .*/SUBDIRS = src/' Makefile.am
	#autoreconf -fi
	#cd ..

	touch .patches-applied
fi

function set_build_flags {
	export CFLAGS="-O2 -g0"
	export CPPFLAGS="-I$WORKSPACE/include"
	export LDFLAGS="-L$WORKSPACE/lib"
	export CXXFLAGS=$CFLAGS
	export MAKEFLAGS="-j${nproc:-2}"
	export EM_CFLAGS="-Wno-warn-absolute-paths"
	export EMMAKEN_CFLAGS="$EM_CFLAGS"
	export EM_PKG_CONFIG_PATH="$WORKSPACE/lib/pkgconfig"
}

# generic autotools library installer
function install_lib {
	echo ""
	echo "**** Building ${1%-*} ****"
	echo ""

	cd $1
	shift
	emconfigure ./configure --prefix=$WORKSPACE --disable-shared --enable-static \
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
	emconfigure cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_SHARED_LIBS=OFF \
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
	emconfigure ./configure --static --prefix=$WORKSPACE
	make clean
	make
	make install
	cd ..

	echo " -> done"
}

function install_lib_sdl2 {
	echo ""
	echo "**** Building SDL2 ****"
	echo ""

	cd SDL2
	emconfigure ./configure --prefix=$WORKSPACE --host=asmjs-unknown-emscripten \
		--disable-shared --enable-static --disable-assembly --disable-threads --disable-cpuinfo
	make clean
	make install
	cd ..

	echo " -> done"
}

# Install ICU
function install_lib_icu {
	echo ""
	echo "**** Building ICU ****"
	echo ""

	# Compile native version
	unset CFLAGS
	unset CXXFLAGS
	unset CPPFLAGS
	unset LDFLAGS

	cp icudt60l.dat icu/source/data/in/
	cp icudt60l.dat icu-native/source/data/in/
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

	chmod u+x configure
	emconfigure ./configure CPPFLAGS="-DBUILD_DATA_WITHOUT_ASSEMBLY -DGENCCODE_ASSEMBLY" \
		--prefix=$WORKSPACE --with-cross-build=$ICU_CROSS_BUILD --enable-strict=no \
		--disable-shared --enable-static --with-data-packaging=static --disable-dyload \
		--disable-extras --disable-icuio --disable-layout --disable-tests --disable-samples
	make clean
	make
	make install

	# Tricky workaround to regenerate icudata library without assembly,
	# see also http://bugs.icu-project.org/trac/ticket/11752
	cd data
	mkdir -p out/build/icudt60l
	LD_LIBRARY_PATH=$ICU_CROSS_BUILD/stubdata:$ICU_CROSS_BUILD/tools/ctestfw:$ICU_CROSS_BUILD/lib:$LD_LIBRARY_PATH \
		$ICU_CROSS_BUILD/bin/pkgdata --without-assembly -O icupkg.inc -q -c -s out/build/icudt60l -d ../lib -e icudt60 \
		-T ./out/tmp -p icudt60l -m static -r 60.2 -L icudata ./out/tmp/icudata.lst
	cp -up ../lib/libicudata.a "$WORKSPACE/lib/"

	cd ../..

	echo " -> done"
}

echo "Preparing toolchain"

cd emsdk-portable
./emsdk construct_env
source ./emsdk_set_env.sh

cd $WORKSPACE

set_build_flags
install_lib_zlib
install_lib libpng-1.6.34
install_lib pixman-0.34.0 --disable-libpng
install_lib_cmake expat-2.2.5 -DBUILD_tools=OFF -DBUILD_examples=OFF \
	-DBUILD_tests=OFF -DBUILD_doc=OFF -DBUILD_shared=OFF
install_lib libogg-1.3.2
install_lib libvorbis-1.3.5
install_lib libsndfile-1.0.28 --disable-full-suite
install_lib speexdsp-1.2rc3
install_lib mpg123-1.25.8 --with-cpu=generic --enable-fifo=no --enable-ipv6=no --enable-network=no \
	--enable-int-quality=no --with-default-audio=dummy --with-optimization=2
install_lib libxmp-lite-4.4.1
# this allows us to build our minimal build with the lite version and the use the full version otherwise
mv "$WORKSPACE/lib/pkgconfig/libxmp-lite.pc" "$WORKSPACE/lib/pkgconfig/libxmp.pc"
install_lib opus-1.2.1 --disable-intrinsics
install_lib opusfile-0.9 --disable-http
install_lib_sdl2
install_lib_icu

#### additional stuff

#install_lib freetype-2.8.1 --without-harfbuzz --without-bzip2 --without-png --without-zlib
#install_lib harfbuzz-1.5.1 --without-glib --without-gobject --without-cairo --without-fontconfig --without-icu
#install_lib freetype-2.8.1 --with-harfbuzz --without-bzip2 --without-png --without-zlib

# for freetype, build apinames apart with gcc:
#gcc src/tools/apinames.c -o objs/apinames
