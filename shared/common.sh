#!/bin/bash

function extract {
	file=$1
	shift

	[ $# -ne 0 ] && msg "Extracting $file..."

	if [ ${file: -4} == ".zip" ]; then
		unzip -q $file $@
	else
		tar xf $file $@
	fi
}

function download {
	url=$1
	shift

	[ $# -ne 0 ] && msg "Downloading $url..."

	# Fallback to easyrpg.org when <100KB/s for >3s
	if [ "x$USE_EASYRPG_MIRROR" == "x1" ] || \
		! curl -sSLOR -y3 -Y102400 --connect-timeout 3 $url; then
		curl -sSLOR https://easyrpg.org/downloads/sources/$(basename $url)
	fi
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
	path=$2
	file=${url##*/}
	msg "Cloning $file..."

	git clone $url $path
}

function download_liblcf {
	if [ "$BUILD_LIBLCF" == "1" ]; then
		git_clone "https://github.com/easyrpg/liblcf"
		(cd liblcf
			autoreconf -fi
		)
	fi
}

function msg {
	echo ""
	echo "$1"
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
	msg "**** Building ${1%-*} ****"

	(cd $1
		shift

		$CONFIGURE_WRAPPER ./configure --prefix=$PLATFORM_PREFIX --disable-shared --enable-static \
			--disable-dependency-tracking --enable-silent-rules \
			--host=$TARGET_HOST --cache-file="$PLATFORM_PREFIX/config.cache" $@
		make clean
		make
		make install
	)
}

# generic cmake library installer
function install_lib_cmake {
	msg "**** Building ${1%-*} ****"

	(cd $1
		shift

		rm -rf build

		if [ -n "$AR" ]; then
			export CMAKE_AR="-DCMAKE_AR=$AR"
		else
			CMAKE_AR=
		fi

		if [ -n "$NM" ]; then
			export CMAKE_NM="-DCMAKE_NM=$NM"
		else
			CMAKE_NM=
		fi

		if [ -n "$RANLIB" ]; then
			export CMAKE_RANLIB="-DCMAKE_RANLIB=$RANLIB"
		else
			CMAKE_RANLIB=
		fi

		$CMAKE_WRAPPER cmake . -GNinja -Bbuild -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_SHARED_LIBS=OFF \
			-DCMAKE_C_FLAGS="$CFLAGS $CPPFLAGS" -DCMAKE_CXX_FLAGS="$CXXFLAGS $CPPFLAGS" \
			-DCMAKE_INSTALL_LIBDIR=lib $CMAKE_AR $CMAKE_NM $CMAKE_RANLIB \
			-DCMAKE_INSTALL_PREFIX=$PLATFORM_PREFIX -DCMAKE_SYSTEM_NAME=$CMAKE_SYSTEM_NAME \
			-DCMAKE_PREFIX_PATH=$PLATFORM_PREFIX $@
		cmake --build build --target clean
		cmake --build build --target install
	)
}

function install_lib_zlib {
	msg "**** Building zlib ****"

	(cd $ZLIB_DIR
		CHOST=$TARGET_HOST $CONFIGURE_WRAPPER ./configure --static --prefix=$PLATFORM_PREFIX
		make clean
		# only build static library, no tests/examples
		make libz.a
		make install
	)
}

function install_lib_mpg123 {
	msg "**** Building libmpg123 ****"

	(cd $MPG123_DIR
		$CONFIGURE_WRAPPER ./configure --prefix=$PLATFORM_PREFIX --disable-shared --enable-static \
			--disable-dependency-tracking --enable-silent-rules \
			--host=$TARGET_HOST --cache-file="$PLATFORM_PREFIX/config.cache" \
			--with-cpu=generic --disable-fifo --disable-ipv6 --disable-network \
			--disable-int-quality --with-default-audio=dummy --with-optimization=2 $@
		make clean
		# only build libmpg123
		make src/libmpg123/libmpg123.la
		# custom installation
		mkdir -p $PLATFORM_PREFIX/include $PLATFORM_PREFIX/lib/pkgconfig
		install -m644 src/libmpg123/{fmt,mpg}123.h $PLATFORM_PREFIX/include
		install -m644 libmpg123.pc $PLATFORM_PREFIX/lib/pkgconfig
		./libtool --mode=install install src/libmpg123/libmpg123.la $PLATFORM_PREFIX/lib
	)
}

function install_lib_liblcf {
	if [ "$BUILD_LIBLCF" == "1" ]; then
		install_lib liblcf --disable-update-mimedb --disable-tools
	fi
}

function install_lib_icu_native {
	msg "**** Building ICU (native) ****"

	(cd icu-native/source
		unset CC
		unset CXX
		unset CFLAGS
		unset CPPFLAGS
		unset CXXFLAGS
		unset LDFLAGS

		chmod u+x configure
		./configure --enable-static --enable-shared=no $ICU_ARGS
		make
	)
}

# Only needed for a mixed endian compile, on other platforms use
# install_lib_icu_native
function install_lib_icu_native_without_assembly {
	msg "**** Building ICU (native without ASM) ****"

	(cd icu-native/source
		unset CC
		unset CXX
		unset CFLAGS
		unset CPPFLAGS
		unset CXXFLAGS
		unset LDFLAGS

		chmod u+x configure
		CPPFLAGS="-DBUILD_DATA_WITHOUT_ASSEMBLY -DU_DISABLE_OBJ_CODE" ./configure --enable-static --enable-shared=no $ICU_ARGS
		make
	)
}

function install_lib_icu_cross {
	msg "**** Building ICU (cross) ****"

	export ICU_CROSS_BUILD=$PWD/icu-native/source

	(cd icu/source
		cp config/mh-linux config/mh-unknown

		chmod u+x configure
		$CONFIGURE_WRAPPER ./configure --enable-static --enable-shared=no --prefix=$PLATFORM_PREFIX \
			--host=$TARGET_HOST --with-cross-build=$ICU_CROSS_BUILD \
			--enable-tools=no $ICU_ARGS
		make clean
		make
		make install
	)
}

# Use this when crosscompiling but configure assumes we are building native
# (required by emscripten)
function icu_force_data_install {
	msg "**** Force install ICU data file ****"

	# Disable assembly
	export PKGDATA_OPTS="-w -v -O $PWD/icu/source/config/pkgdata.inc"

	(cd icu/source/data
		make clean
		make

		cp ../lib/libicudata.a "$WORKSPACE/lib/"
	)
}

function patches_common {
	_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

	# disable png utils
	(cd $LIBPNG_DIR
		perl -pi -e 's/^check_PROGRAMS.*//' Makefile.am
		perl -pi -e 's/^bin_PROGRAMS.*//' Makefile.am
		autoreconf -fi
	)

	# pixman: disable examples and tests
	(cd $PIXMAN_DIR
		perl -pi -e 's/SUBDIRS = .*/SUBDIRS = pixman/' Makefile.am
		autoreconf -fi
	)

	# disable unsupported compiler flags by clang in libvorbis
	if [ -d "$LIBVORBIS_DIR" ]; then
		perl -pi -e 's/-mno-ieee-fp//' $LIBVORBIS_DIR/configure
	fi

	# disable libsndfile examples and tests
	if [ -d "$LIBSNDFILE_DIR" ]; then
		(cd $LIBSNDFILE_DIR
			perl -pi -e 's/ examples tests//' Makefile.am
			perl -pi -e 's/ examples regtest tests programs//' Makefile.am
			autoreconf -fi
		)
	fi

	# libxmp-lite
	if [ -d "$LIBXMP_LITE_DIR" ]; then
		# compile fix
		(cd $LIBXMP_LITE_DIR
			# Use custom CMakeLists.txt
			cp $_SCRIPT_DIR/CMakeLists_xmplite.txt ./CMakeLists.txt
		)
	fi

	# Tremor: Generate configure & Makefile, fix build
	if [ -d "$TREMOR_DIR" ]; then
		(cd $TREMOR_DIR
			perl -pi -e 's/XIPH_PATH_OGG.*//' configure.in
			autoreconf -fi
		)
	fi

	# libsamplerate: disable examples
	if [ -d "$LIBSAMPLERATE_DIR" ]; then
		(cd $LIBSAMPLERATE_DIR
			patch -Np1 < $_SCRIPT_DIR/libsamplerate-no-examples.patch
			autoreconf -fi
		)
	fi

	# Expat: Disable error when high entropy randomness is unavailable
	if [ -d "$EXPAT_DIR" ]; then
		(cd $EXPAT_DIR
			perl -pi -e 's/#  error/#warning/' lib/xmlparse.c
		)
	fi

	# FluidSynth: Shim glib and disable all optional features
	if [ -d "$FLUIDSYNTH_DIR" ]; then
		(cd $FLUIDSYNTH_DIR
			patch -Np1 < $_SCRIPT_DIR/fluidsynth-no-glib.patch
			patch -Np1 < $_SCRIPT_DIR/fluidsynth-no-deps.patch
		)
	fi

	# nlohmann json: Install pkgconfig/cmake into lib (share is deleted by us)
	if [ -d "$NLOHMANNJSON_DIR" ]; then
		(cd $NLOHMANNJSON_DIR
			perl -pi -e 's/CMAKE_INSTALL_DATADIR/CMAKE_INSTALL_LIBDIR/' CMakeLists.txt
		)
	fi

	cp icudt*.dat $ICU_DIR/source/data/in
	(cd $ICU_DIR/source
		chmod u+x configure
		perl -pi -e 's/SMALL_BUFFER_MAX_SIZE 512/SMALL_BUFFER_MAX_SIZE 2048/' tools/toolutil/pkg_genc.h
	)
}

function cleanup {
	rm -rf zlib-*/ libpng-*/ freetype-*/ harfbuzz-*/ pixman-*/ expat-*/ libogg-*/ \
	libvorbis-*/ tremor-*/ mpg123-*/ libsndfile-*/ libxmp-lite-*/ speexdsp-*/ \
	libsamplerate-*/ wildmidi-*/ opus-*/ opusfile-*/ icu/ icu-native/ \
	SDL2-*/ SDL2_image-*/ fmt-*/ FluidLite-*/ fluidsynth-*/ json-*/ \
	liblcf/
	rm -f *.zip *.bz2 *.gz *.xz *.tgz icudt* *.pl .patches-applied config.cache
	rm -rf sbin/ share/
}
