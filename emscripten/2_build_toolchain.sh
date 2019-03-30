#!/bin/bash

# abort on error
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh
# Override ICU version to 60.2
source $SCRIPT_DIR/packages.sh

# Number of CPU
nproc=$(nproc)

# Use ccache?
test_ccache

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	# Fix libsndfile
	pushd $LIBSNDFILE_DIR
	patch -Np1 < $SCRIPT_DIR/../shared/extra/libsndfile.patch
	autoreconf -fi
	popd

	# disable unsupported compiler flags by emcc clang in libogg
	perl -pi -e 's/-O20/-g0 -O2/g' $LIBOGG_DIR/configure

	# hack to not use hidden funtion
	# (see https://groups.google.com/forum/#!topic/emscripten-discuss/YM3jC_qQoPk)
	perl -pi -e 's/HAVE_ARC4RANDOM\)/NO_ARC4RANDOM\)/' $EXPAT_DIR/ConfigureChecks.cmake

	cp -rup icu icu-native

	touch .patches-applied
fi

export PLATFORM_PREFIX=$WORKSPACE
export CONFIGURE_WRAPPER=emconfigure
export CMAKE_WRAPPER=emconfigure
export MAKEFLAGS="-j${nproc:-2}"

function set_build_flags {
	export CFLAGS="-O2 -g0"
	export CXXFLAGS=$CFLAGS
	export CPPFLAGS="-I$PLATFORM_PREFIX/include"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib"
	export EM_CFLAGS="-Wno-warn-absolute-paths"
	export EMMAKEN_CFLAGS="$EM_CFLAGS"
	export EM_PKG_CONFIG_PATH="$PLATFORM_PREFIX/lib/pkgconfig"
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache gcc"
		export CXX="ccache g++"
	fi
}

function install_lib_sdl2 {
	msg "Building SDL2"

	(cd SDL2
		emconfigure ./configure --prefix=$WORKSPACE --host=asmjs-unknown-emscripten \
			--disable-shared --enable-static --disable-assembly --disable-threads --disable-cpuinfo
		make clean
		make install
	)
}

install_lib_icu_native_without_assembly

echo "Preparing toolchain"

cd emsdk-portable
./emsdk construct_env
source ./emsdk_set_env.sh

cd $WORKSPACE

# Install libraries
set_build_flags

install_lib_zlib
install_lib $LIBPNG_DIR $LIBPNG_ARGS
#install_lib $FREETYPE_DIR $FREETYPE_ARGS --without-harfbuzz
#install_lib $HARFBUZZ_DIR $HARFBUZZ_ARGS
#install_lib $FREETYPE_DIR $FREETYPE_ARGS --with-harfbuzz
install_lib $PIXMAN_DIR $PIXMAN_ARGS
install_lib_cmake $EXPAT_DIR $EXPAT_ARGS
install_lib $LIBOGG_DIR $LIBOGG_ARGS
install_lib $LIBVORBIS_DIR $LIBVORBIS_ARGS
install_lib $MPG123_DIR $MPG123_ARGS
install_lib $LIBSNDFILE_DIR $LIBSNDFILE_ARGS
install_lib_cmake $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS
#install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS
install_lib $OPUS_DIR $OPUS_ARGS
install_lib $OPUSFILE_DIR $OPUSFILE_ARGS

install_lib_sdl2
install_lib_icu_cross

#### additional stuff

# for freetype, build apinames apart with gcc:
#gcc src/tools/apinames.c -o objs/apinames
