#!/bin/bash

# abort on error
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

# Number of CPU
os=`uname`
if [ $os = "Darwin" ] ; then
	nproc=$(getconf _NPROCESSORS_ONLN)
else
	nproc=$(nproc)
fi

# no ccache support currently with em* wrappers

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	# Fix libsndfile
	(cd $LIBSNDFILE_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/libsndfile.patch
		autoreconf -fi
	)

	# Make wasm32-unknown-emscripten available
	(cd $LIBOGG_DIR
		autoreconf -fi
	)

	(cd $LIBVORBIS_DIR
		autoreconf -fi
	)

	# disable unsupported compiler flags by emcc clang in libogg
	perl -pi -e 's/-O20/-g0 -O2/g' $LIBOGG_DIR/configure

	# hack to not use hidden funtion
	# (see https://groups.google.com/forum/#!topic/emscripten-discuss/YM3jC_qQoPk)
	perl -pi -e 's/HAVE_ARC4RANDOM\)/NO_ARC4RANDOM\)/' $EXPAT_DIR/ConfigureChecks.cmake

	if [ "$USE_WASM_SIMD" == "1" ]; then
		(cd $PIXMAN_DIR
			patch -Np2 < ../pixman-wasm.patch
		)
	fi

	touch .patches-applied
fi

if [ "$USE_WASM_SIMD" == "1" ]; then
	CFLAGS_SIMD="-msimd128"
	# Enable SSE2 fast paths for pixman, customize as needed
	PIXMAN_EXTRA_ARGS="-Dsse2=enabled"
fi

export PLATFORM_PREFIX=$WORKSPACE
export CONFIGURE_WRAPPER=emconfigure
export CMAKE_WRAPPER=emcmake
export MESON_WRAPPER=emconfigure
export MAKEFLAGS="-j${nproc:-2}"

function set_build_flags {
	export PATH="$PATH:$PLATFORM_PREFIX/bin" # for icu-config
	export CFLAGS="-O2 -g0 -sUSE_SDL=0 $CFLAGS_SIMD"
	export CXXFLAGS="$CFLAGS"
	export CPPFLAGS="-I$PLATFORM_PREFIX/include"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib -sEXPORT_ALL=1"
	export EM_CFLAGS="-Wno-warn-absolute-paths"
	export EMCC_CFLAGS="$EM_CFLAGS"
	export EM_PKG_CONFIG_PATH="$PLATFORM_PREFIX/lib/pkgconfig"
	export CMAKE_EXTRA_ARGS="-DCMAKE_FIND_ROOT_PATH=$PLATFORM_PREFIX"

	export TARGET_HOST="wasm32-unknown-emscripten"

	# force mmap support in mpg123 (actually unused, but needed for building)
	export ac_cv_func_mmap_fixed_mapped=yes

	emconfigure $SCRIPT_DIR/../shared/mk-meson-cross.sh asmjs > meson-cross.txt
}

install_lib_icu_native

echo "Preparing toolchain"

if ! hash emcc >/dev/null 2>&1; then
	# Set the current Emscripten path
	cd emsdk-portable
	source ./emsdk_env.sh
fi

cd $WORKSPACE

# Install libraries
set_build_flags

install_lib_cmake $ZLIB_DIR $ZLIB_ARGS
install_lib_cmake $LIBPNG_DIR $LIBPNG_ARGS
install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=ON
install_lib_meson $HARFBUZZ_DIR $HARFBUZZ_ARGS
install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=OFF -DCMAKE_FIND_ROOT_PATH=$PLATFORM_PREFIX
install_lib_meson $PIXMAN_DIR $PIXMAN_ARGS $PIXMAN_EXTRA_ARGS
install_lib_cmake $EXPAT_DIR $EXPAT_ARGS
install_lib $LIBOGG_DIR $LIBOGG_ARGS
install_lib $LIBVORBIS_DIR $LIBVORBIS_ARGS
install_lib $MPG123_DIR $MPG123_ARGS
install_lib $LIBSNDFILE_DIR $LIBSNDFILE_ARGS
install_lib_cmake $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS
#install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS
install_lib_cmake $OPUS_DIR $OPUS_ARGS -DOPUS_STACK_PROTECTOR=OFF
install_lib $OPUSFILE_DIR $OPUSFILE_ARGS
install_lib_cmake $FLUIDSYNTH_DIR $FLUIDSYNTH_ARGS -Dosal=embedded
install_lib_cmake $NLOHMANNJSON_DIR $NLOHMANNJSON_ARGS
install_lib_meson $INIH_DIR $INIH_ARGS
#install_lib $LHASA_DIR $LHASA_ARGS
install_lib_cmake $FMT_DIR $FMT_ARGS
install_lib $SDL2_DIR $SDL2_ARGS --disable-assembly --disable-threads --disable-cpuinfo

install_lib_icu_cross
icu_force_data_install

install_lib_liblcf
