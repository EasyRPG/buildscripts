#!/bin/bash

function extract {
	file=$1
	shift

	[ $# -ne 0 ] && msg "Extracting $file..."

	tar xf $file $@
}

function download {
	url=$1
	shift

	[ $# -ne 0 ] && msg "Downloading $url..."

	wget -nv -N $url $@
}

function download_and_extract {
	url=$1

	file=${url##*/}

	msg "Downloading and extracting $file..."

	download $url
	extract $file
}

function git_clone {
	url=$1
	file=${url##*/}
	msg "Cloning $file..."

	git clone $url
}

function msg {
	echo ""
	echo $1
}

function test_ccache {
	if [ -z ${NO_CCACHE+x} ]; then
		if hash ccache >/dev/null 2>&1; then
			ENABLE_CCACHE=1
			echo "CCACHE enabled"
		fi
	fi
}

# generic autotools library installer
function install_lib {
	echo ""
	echo "**** Building ${1%-*} ****"
	echo ""

	pushd $1
	shift
	$CONFIGURE_WRAPPER ./configure --prefix=$PLATFORM_PREFIX --disable-shared --enable-static \
		--disable-dependency-tracking --enable-silent-rules \
		--host=$TARGET_HOST --cache-file="$PLATFORM_PREFIX/config.cache" $@
	make clean
	make
	make install
	popd

	echo " -> done"
}

# generic cmake library installer
function install_lib_cmake {
	echo ""
	echo "**** Building ${1%-*} ****"
	echo ""

	pushd $1
	shift
	rm -rf CMakeCache.txt CMakeFiles/
	$CMAKE_WRAPPER cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_SHARED_LIBS=OFF \
		-DCMAKE_C_FLAGS="$CFLAGS $CPPFLAGS" -DCMAKE_CXX_FLAGS="$CXXFLAGS $CPPFLAGS" \
		-DCMAKE_INSTALL_PREFIX=$PLATFORM_PREFIX -DCMAKE_SYSTEM_NAME=Generic $@
	make clean
	make
	make install
	popd

	echo " -> done"
}

function install_lib_zlib {
	echo ""
	echo "**** Building zlib ****"
	echo ""

	pushd $ZLIB_DIR
	CHOST=$TARGET_HOST $CONFIGURE_WRAPPER ./configure --static --prefix=$PLATFORM_PREFIX
	make clean
	make
	make install
	popd

	echo " -> done"
}

function install_lib_icu_native {
	# Compile native version
	unset CC
	unset CXX
	unset CFLAGS
	unset CPPFLAGS
	unset CXXFLAGS
	unset LDFLAGS

	pushd icu-native/source
	chmod u+x configure
	./configure --enable-static --enable-shared=no $ICU_ARGS
	make

	export ICU_CROSS_BUILD=$PWD

	popd
}

function install_lib_icu_native_without_assembly {
	# Compile native version
	unset CC
	unset CXX
	unset CFLAGS
	unset CPPFLAGS
	unset CXXFLAGS
	unset LDFLAGS

	pushd icu-native/source
	chmod u+x configure
	CPPFLAGS="-DBUILD_DATA_WITHOUT_ASSEMBLY -DU_DISABLE_OBJ_CODE" ./configure --enable-static --enable-shared=no $ICU_ARGS
	make

	export ICU_CROSS_BUILD=$PWD

	popd
}

function install_lib_icu_cross {
	# Cross compile
	export ICU_CROSS_BUILD=$PWD/icu-native/source

	pushd icu/source

	cp config/mh-linux config/mh-unknown

	chmod u+x configure
	$CONFIGURE_WRAPPER ./configure --enable-static --enable-shared=no --prefix=$PLATFORM_PREFIX \
		--host=$TARGET_HOST --with-cross-build=$ICU_CROSS_BUILD \
		--enable-tools=no $ICU_ARGS
	make clean
	make
	make install
	popd
}

function patches_common {
	_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

	# disable png utils
	cd $LIBPNG_DIR
	perl -pi -e 's/^check_PROGRAMS.*//' Makefile.am
	perl -pi -e 's/^bin_PROGRAMS.*//' Makefile.am
	autoreconf -fi
	cd ..

	# pixman: disable examples and tests
	cd $PIXMAN_DIR
	perl -pi -e 's/SUBDIRS = .*/SUBDIRS = pixman/' Makefile.am
	autoreconf -fi
	cd ..

	# disable harfbuzz tests
	if [ -d "$HARFBUZZ_DIR" ]; then
		cd $HARFBUZZ_DIR
		patch -Np1 < $_SCRIPT_DIR/harfbuzz.patch
		autoreconf -fi
		cd ..
	fi

	# disable unsupported compiler flags by clang in libvorbis
	perl -pi -e 's/-mno-ieee-fp//' $LIBVORBIS_DIR/configure

	# disable libsndfile examples and tests
	if [ -d "$LIBSNDFILE_DIR" ]; then
		cd $LIBSNDFILE_DIR
		perl -pi -e 's/ examples tests//' Makefile.am
		perl -pi -e 's/ examples regtest tests programs//' Makefile.am
		autoreconf -fi
		cd ..
	fi

	# libxmp-lite
	if [ -d "$LIBXMP_LITE_DIR" ]; then
		# compile fix
		cd $LIBXMP_LITE_DIR
		patch -Np1 < $_SCRIPT_DIR/libxmp-a0288352.patch

		# Use custom CMakeLists.txt
		cp $_SCRIPT_DIR/CMakeLists_xmplite.txt ./CMakeLists.txt
		cd ..
	fi

	# Wildmidi
	if [ -d "$WILDMIDI_DIR" ]; then
		# Support install for CMAKE_SYSTEM_NAME Generic
		cd $WILDMIDI_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/wildmidi-generic-install.patch

		# Disable libm
		perl -pi -e 's/FIND_LIBRARY\(M_LIBRARY m REQUIRED\)//' CMakeLists.txt
		cd ..
	fi

	# Tremor: Generate configure & Makefile, fix build
	if [ -d "$TREMOR_DIR" ]; then
		cd $TREMOR_DIR
		perl -pi -e 's/XIPH_PATH_OGG.*//' configure.in
		autoreconf -fi
		cd ..
	fi

	cp icudt*.dat $ICU_DIR/source/data/in
	cd $ICU_DIR/source
	chmod u+x configure
	perl -pi -e 's/SMALL_BUFFER_MAX_SIZE 512/SMALL_BUFFER_MAX_SIZE 2048/' tools/toolutil/pkg_genc.h
	# glibc 2.26 removed xlocale.h: https://ssl.icu-project.org/trac/ticket/13329
	# Patch is incompatible with MacOSX/iOS
	if [ "$(uname)" != "Darwin" ]; then
		perl -pi -e 's/xlocale/locale/' i18n/digitlst.cpp
	fi
	cd ../..
}

function cleanup {
	rm -rf zlib-*/ libpng-*/ freetype-*/ harfbuzz-*/ pixman-*/ expat-*/ libogg-*/ \
	libvorbis-*/ tremor-*/ mpg123-*/ libsndfile-*/ libxmp-lite-*/ speexdsp-*/ \
	libsamplerate-*/ wildmidi-*/ opus-*/ opusfile-*/ icu/ icu-native/ \
	SDL2-*/ SDL2_mixer-*/ SDL2_image-*/
	rm -f *.zip *.bz2 *.gz *.xz *.tgz icudt* *.pl .patches-applied config.cache
	rm -rf bin/ sbin/ share/
}
