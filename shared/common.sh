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

function test_ccache {
	if [ -z ${NO_CCACHE+x} ]; then
		if hash ccache >/dev/null 2>&1; then
			ENABLE_CCACHE=1
			echo "CCACHE enabled"
		fi
	fi
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
	headermsg "**** Building ${1%-*} ****"

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
			-DCMAKE_PREFIX_PATH=$PLATFORM_PREFIX $CMAKE_EXTRA_ARGS $@
		cmake --build build --target clean
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
			-Ddefault_library=static $MESON_CROSS $@
		meson compile -C build
		meson install -C build
	)
}

function install_lib_zlib {
	headermsg "**** Building zlib ****"

	(cd $ZLIB_DIR
		CHOST=$TARGET_HOST $CONFIGURE_WRAPPER ./configure --static --prefix=$PLATFORM_PREFIX
		make clean
		# only build static library, no tests/examples
		make libz.a
		make install
	)
}

function install_lib_liblcf {
	if [ "$BUILD_LIBLCF" == "1" ]; then
		install_lib liblcf --disable-update-mimedb --disable-tools
	fi
}

function install_lib_icu_native {
	headermsg "**** Building ICU (native) ****"

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
	headermsg "**** Building ICU (native without ASM) ****"

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
	headermsg "**** Building ICU (cross) ****"

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
	headermsg "**** Force install ICU data file ****"

	# Disable assembly
	export PKGDATA_OPTS="-w -v -O $PWD/icu/source/config/pkgdata.inc"

	(cd icu/source/data
		make clean
		make

		cp ../lib/libicudata.a "$PLATFORM_PREFIX/lib/"
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

	# disable unsupported compiler flags by clang in libvorbis
	if [ -d "$LIBVORBIS_DIR" ]; then
		perl -pi -e 's/-mno-ieee-fp//' $LIBVORBIS_DIR/configure
		# Invalid since macOS Sonoma
		perl -pi -e 's/-force_cpusubtype_ALL//' $LIBVORBIS_DIR/configure
	fi

	# disable libsndfile examples and tests
	if [ -d "$LIBSNDFILE_DIR" ]; then
		(cd $LIBSNDFILE_DIR
			perl -pi -e 's/ examples tests//' Makefile.am
			perl -pi -e 's/ examples regtest tests programs//' Makefile.am
			autoreconf -fi
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

	# lhasa: disable binary and tests
	(cd $LHASA_DIR
		perl -pi -e 's/ src test//' Makefile.am
		autoreconf -fi
	)

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
	SDL2-*/ SDL2_image-*/ fmt-*/ FluidLite-*/ fluidsynth-*/ json-*/ inih-*/ \
	lhasa-*/ liblcf/
	rm -f *.zip *.bz2 *.gz *.xz *.tgz icudt* *.pl .patches-applied config.cache
	rm -rf sbin/ share/
}
