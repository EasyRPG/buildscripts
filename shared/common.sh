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

	file=${url##*/}

	# Try cache folder first
	if [ "x$EASYRPG_PATH_DOWNLOADCACHE" != "x" ]; then
		if [ -e $EASYRPG_PATH_DOWNLOADCACHE/$file ]; then
			cp -rup $EASYRPG_PATH_DOWNLOADCACHE/$file $file
			echo "[copied from cache]"
			return
		fi
	fi

	# Fallback to easyrpg.org when <100KB/s for >3s
	if [ "x$USE_EASYRPG_MIRROR" == "x1" ] || \
		! curl -sSLOR -y3 -Y102400 --connect-timeout 3 $url; then
		curl -sSLOR https://easyrpg.org/downloads/sources/$file
	fi
	[ $? -eq 0 ] && echo "done."
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

# color check
HAVE_COLORS=0
if [ -t 1 ] ; then
	HAVE_COLORS=1	
fi

function colormsg {
	if [ $HAVE_COLORS -eq 1 ]; then
		printf "\033[$2$1\033[0m\n"
	else
		echo "$1"
	fi
}

function headermsg {
	echo ""
	colormsg "$1" "34;1m"
}

function errormsg {
	echo ""
	colormsg "$1" "31m"

	exit 1
}

function msg {
	colormsg "$1" "32m"
}

function verbosemsg {
	colormsg "$1" "33m"
}

function test_tool {
	hash $1 >/dev/null 2>&1
}

function require_tool {
	if ! test_tool $1; then
		errormsg "The required tool $1 is missing!"
	fi
}

ENABLE_CCACHE=0
function test_ccache {
	if [ -z ${NO_CCACHE+x} ]; then
		if test_tool ccache; then
			ENABLE_CCACHE=1
			echo "CCACHE enabled"
		fi
	fi
}

function ccachify_compiler {
	if [ $ENABLE_CCACHE -eq 1 ]; then
		if [ -n "$CC" ]; then
			saved_CC=$CC
			export CC="ccache $CC"
		fi

		if [ -n "$CXX" ]; then
			saved_CXX=$CXX
			export CXX="ccache $CXX"
		fi
	fi
}

function unccachify_compiler {
	if [ $ENABLE_CCACHE -eq 1 ]; then
		[ -n "$saved_CC" ] && export CC=$saved_CC
		[ -n "$saved_CXX" ] && export CXX=$saved_CXX
	fi
}

function make_meson_cross {
	ccachify_compiler
	$SCRIPT_DIR/../shared/mk-meson-cross.sh $@
	unccachify_compiler
}

function test_dkp {
	platform=$1
	envvar=${platform^^}

	if [ -z "$DEVKITPRO" ] || [ -z "${!envvar}" ]; then
		errormsg "Setup ${platform} properly. \$DEVKITPRO and \$${envvar} need to be set."
	fi
}

# generic autotools library installer
function install_lib {
	headermsg "**** Building ${1%-*} ****"

	ccachify_compiler

	(cd $1
		shift

		$CONFIGURE_WRAPPER ./configure --prefix=$PLATFORM_PREFIX --disable-shared --enable-static \
			--disable-dependency-tracking --enable-silent-rules \
			--host=$TARGET_HOST --cache-file="$PLATFORM_PREFIX/config.cache" $@
		make clean
		make
		make install
	)

	unccachify_compiler
}

# generic cmake library installer
function install_lib_cmake {
	headermsg "**** Building ${1%-*} ****"

	(cd $1
		shift

		rm -rf build

		# cmake 3.17+, but this only reports unused options on older versions,
		# so users unwilling to update cmake will not get ccache acceleration
		CMAKE_CCACHE=
		if [ $ENABLE_CCACHE -eq 1 ]; then
			CMAKE_CCACHE="-DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache"
		fi

		CMAKE_AR=
		if [ -n "$AR" ]; then
			CMAKE_AR="-DCMAKE_AR=$AR"
		fi

		CMAKE_NM=
		if [ -n "$NM" ]; then
			CMAKE_NM="-DCMAKE_NM=$NM"
		fi

		CMAKE_RANLIB=
		if [ -n "$RANLIB" ]; then
			CMAKE_RANLIB="-DCMAKE_RANLIB=$RANLIB"
		fi

		$CMAKE_WRAPPER cmake . -Bbuild -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_SHARED_LIBS=OFF \
			-DCMAKE_C_FLAGS="$CFLAGS $CPPFLAGS" -DCMAKE_CXX_FLAGS="$CXXFLAGS $CPPFLAGS" \
			-DCMAKE_INSTALL_LIBDIR=lib $CMAKE_AR $CMAKE_NM $CMAKE_RANLIB $CMAKE_CCACHE \
			-DCMAKE_INSTALL_PREFIX=$PLATFORM_PREFIX -DCMAKE_SYSTEM_NAME=$CMAKE_SYSTEM_NAME \
			-DCMAKE_PREFIX_PATH=$PLATFORM_PREFIX $CMAKE_EXTRA_ARGS $@
		cmake --build build --target clean
		cmake --build build
		cmake --build build --target install
	)
}

# generic meson library installer
function install_lib_meson {
	headermsg "**** Building ${1%-*} ****"

	MESON_CROSS=""
	if [ -f "$PLATFORM_PREFIX/meson-cross.txt" ]; then
		MESON_CROSS="--cross-file $PLATFORM_PREFIX/meson-cross.txt"
	fi

	(cd $1
		shift

		rm -rf build

		$MESON_WRAPPER meson setup build --prefix $PLATFORM_PREFIX --buildtype=plain \
			-Ddefault_library=static --libdir=lib $MESON_CROSS $@
		meson compile -C build
		meson install -C build
	)
}

function install_lib_liblcf {
	if [ "$BUILD_LIBLCF" == "1" ]; then
		install_lib liblcf --disable-update-mimedb --disable-tools
	fi
}

function install_lib_icu_native {
	headermsg "**** Building ICU (native) ****"

	# do not use cross environment
	unset CC
	unset CXX
	unset CFLAGS
	unset CPPFLAGS
	unset CXXFLAGS
	unset LDFLAGS

	# ICU's configure will always check clang and then gcc first. Since they
	# are used on many of our platforms, we can accelerate with ccache
	if test_tool clang && test_tool clang++; then
		export CC=clang
		export CXX=clang++
	elif test_tool gcc && test_tool g++; then
		export CC=gcc
		export CXX=g++
	fi
	if [ $ENABLE_CCACHE -eq 1 ]; then
		export CC="ccache $CC"
		export CXX="ccache $CXX"
	fi

	mkdir -p icu-native
	(cd icu-native
		../icu/source/configure --enable-static --disable-shared $ICU_ARGS
		make clean
		make
	)

	# reset
	unset CC
	unset CXX
}

function install_lib_icu_cross {
	headermsg "**** Building ICU (cross) ****"

	ICU_CROSS_BUILD=$PWD/icu-native

	ccachify_compiler

	mkdir -p icu-cross
	(cd icu-cross
		$CONFIGURE_WRAPPER ../icu/source/configure \
			--enable-static --disable-shared --prefix=$PLATFORM_PREFIX \
			--host=$TARGET_HOST --with-cross-build=$ICU_CROSS_BUILD \
			--disable-tools $ICU_ARGS
		make clean
		make
		make install
	)

	unccachify_compiler
}

# Use this when crosscompiling but configure assumes we are building native
# (required by emscripten)
function icu_force_data_install {
	headermsg "**** Force install ICU data file ****"

	# Disable assembly
	export PKGDATA_OPTS="-w -v -O $PWD/icu-cross/config/pkgdata.inc"

	(cd icu-cross/data
		make clean
		make

		cp ../lib/libicudata.a "$PLATFORM_PREFIX/lib/"
	)
}

function patches_common {
	_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

	# zlib: Install pkgconfig into lib (share is deleted by us)
	if [ -d "$ZLIB_DIR" ]; then
		verbosemsg "zlib"

		(cd $ZLIB_DIR
			perl -pi -e 's#/share/pkgconfig#/lib/pkgconfig#' CMakeLists.txt
		)
	fi

	# png: move cmake configuration, fix using compiler with arguments
	if [ -d "$LIBPNG_DIR" ]; then
		verbosemsg "libpng"

		(cd $LIBPNG_DIR
			perl -pi -e 's#DESTINATION lib/libpng#DESTINATION lib/cmake/libpng#' CMakeLists.txt
			patch -Np1 < $_SCRIPT_DIR/libpng-custom-cc.patch
		)
	fi

	# disable unsupported compiler flags by clang in libvorbis
	if [ -d "$LIBVORBIS_DIR" ]; then
		verbosemsg "libvorbis"

		perl -pi -e 's/-mno-ieee-fp//' $LIBVORBIS_DIR/configure
		# Invalid since macOS Sonoma
		perl -pi -e 's/-force_cpusubtype_ALL//' $LIBVORBIS_DIR/configure
	fi

	# disable libsndfile examples and tests
	if [ -d "$LIBSNDFILE_DIR" ]; then
		verbosemsg "libsndfile"

		(cd $LIBSNDFILE_DIR
			perl -pi -e 's/ examples tests//' Makefile.am
			perl -pi -e 's/ examples regtest tests programs//' Makefile.am
			autoreconf -fi
		)
	fi

	# Tremor: Generate configure & Makefile, fix build
	if [ -d "$TREMOR_DIR" ]; then
		verbosemsg "tremor"

		(cd $TREMOR_DIR
			perl -pi -e 's/XIPH_PATH_OGG.*//' configure.in
			autoreconf -fi
		)
	fi

	# libsamplerate: disable examples
	if [ -d "$LIBSAMPLERATE_DIR" ]; then
		verbosemsg "libsamplerate"

		(cd $LIBSAMPLERATE_DIR
			patch -Np1 < $_SCRIPT_DIR/libsamplerate-no-examples.patch
			autoreconf -fi
		)
	fi

	# Expat: Disable error when high entropy randomness is unavailable
	if [ -d "$EXPAT_DIR" ]; then
		verbosemsg "expat"

		(cd $EXPAT_DIR
			perl -pi -e 's/#  error/#warning/' lib/xmlparse.c
		)
	fi

	# FluidSynth: Shim glib and disable all optional features
	if [ -d "$FLUIDSYNTH_DIR" ]; then
		verbosemsg "fluidsynth"

		(cd $FLUIDSYNTH_DIR
			patch -Np1 < $_SCRIPT_DIR/fluidsynth-no-glib.patch
			patch -Np1 < $_SCRIPT_DIR/fluidsynth-no-deps.patch
		)
	fi

	# nlohmann json: Install pkgconfig/cmake into lib (share is deleted by us)
	if [ -d "$NLOHMANNJSON_DIR" ]; then
		verbosemsg "nlohmann_json"

		(cd $NLOHMANNJSON_DIR
			perl -pi -e 's/CMAKE_INSTALL_DATADIR/CMAKE_INSTALL_LIBDIR/' CMakeLists.txt
		)
	fi

	# lhasa: disable binary and tests
	if [ -d "$LHASA_DIR" ]; then
		verbosemsg "lhasa"

		(cd $LHASA_DIR
			perl -pi -e 's/ src test//' Makefile.am
			autoreconf -fi
		)
	fi

	verbosemsg "ICU"
	cp icudt*.dat $ICU_DIR/source/data/in
	(cd $ICU_DIR/source
		chmod u+x configure
		cp config/mh-linux config/mh-unknown
		perl -pi -e 's/SMALL_BUFFER_MAX_SIZE 512/SMALL_BUFFER_MAX_SIZE 2048/' tools/toolutil/pkg_genc.h
	)
}

function cleanup {
	rm -rf zlib-*/ libpng-*/ freetype-*/ harfbuzz-*/ pixman-*/ expat-*/ libogg-*/ \
	libvorbis-*/ tremor-*/ mpg123-*/ libsndfile-*/ libxmp-lite-*/ speexdsp-*/ \
	libsamplerate-*/ wildmidi-*/ opus-*/ opusfile-*/ icu/ icu-native/ icu-cross/ \
	SDL2-*/ SDL2_image-*/ fmt-*/ FluidLite-*/ fluidsynth-*/ json-*/ inih-*/ \
	lhasa-*/ liblcf/
	rm -f *.zip *.bz2 *.gz *.xz *.tgz icudt* .patches-applied config.cache meson-cross.txt
	rm -rf sbin/ share/
	rm -f lib/*.la
}
