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
	CP_ARGS="-r"
else
	nproc=$(nproc)
	CP_ARGS="-rup"
fi

# Use ccache?
test_ccache

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	# Fix libsndfile
	(cd $LIBSNDFILE_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/libsndfile.patch
		autoreconf -fi
	)

	# disable unsupported compiler flags by emcc clang in libogg
	perl -pi -e 's/-O20/-g0 -O2/g' $LIBOGG_DIR/configure

	# hack to not use hidden funtion
	# (see https://groups.google.com/forum/#!topic/emscripten-discuss/YM3jC_qQoPk)
	perl -pi -e 's/HAVE_ARC4RANDOM\)/NO_ARC4RANDOM\)/' $EXPAT_DIR/ConfigureChecks.cmake

	# Fix libxmp-lite
	(cd $LIBXMP_LITE_DIR
		patch -Np1 < ../xmp-emscripten.patch
	)

	if [ "$USE_WASM_SIMD" == "1" ]; then
		(cd $PIXMAN_DIR
			patch -Np2 < ../pixman-wasm.patch
		)
	fi

	cp $CP_ARGS icu icu-native

	touch .patches-applied
fi

if [ "$USE_WASM_SIMD" == "1" ]; then
	CFLAGS_SIMD="-msimd128"
fi

export PLATFORM_PREFIX=$WORKSPACE
export CONFIGURE_WRAPPER=emconfigure
export CMAKE_WRAPPER=emcmake
export MAKEFLAGS="-j${nproc:-2}"

function set_build_flags {
	export PATH="$PATH:$PLATFORM_PREFIX/bin" # for icu-config
	export CFLAGS="-O2 -g0 -sUSE_SDL=0 $CFLAGS_SIMD"
	export CXXFLAGS="$CFLAGS"
	export CPPFLAGS="-I$PLATFORM_PREFIX/include"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib"
	export EM_CFLAGS="-Wno-warn-absolute-paths"
	export EMCC_CFLAGS="$EM_CFLAGS"
	export EM_PKG_CONFIG_PATH="$PLATFORM_PREFIX/lib/pkgconfig"
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache gcc"
		export CXX="ccache g++"
	fi

	# force mmap support in mpg123 (actually unused, but needed for building)
	export ac_cv_func_mmap_fixed_mapped=yes
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

if [ $os = "Darwin" ] ; then
	# Workaround wrong libtool being detected
	# Do not use this on Linux, fails with autoconf 2.69
	export TARGET_HOST="asmjs-unknown-emscripten"
fi

install_lib_zlib
install_lib $LIBPNG_DIR $LIBPNG_ARGS
install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS_CMAKE -DFT_DISABLE_HARFBUZZ=ON
install_lib_cmake $HARFBUZZ_DIR $HARFBUZZ_ARGS -DCMAKE_FIND_ROOT_PATH=$PLATFORM_PREFIX
install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS_CMAKE -DFT_DISABLE_HARFBUZZ=OFF -DCMAKE_FIND_ROOT_PATH=$PLATFORM_PREFIX
install_lib $PIXMAN_DIR $PIXMAN_ARGS
install_lib_cmake $EXPAT_DIR $EXPAT_ARGS
install_lib $LIBOGG_DIR $LIBOGG_ARGS
install_lib $LIBVORBIS_DIR $LIBVORBIS_ARGS
install_lib_mpg123
install_lib $LIBSNDFILE_DIR $LIBSNDFILE_ARGS
install_lib_cmake $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS
#install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS
install_lib $OPUS_DIR $OPUS_ARGS --disable-stack-protector
install_lib $OPUSFILE_DIR $OPUSFILE_ARGS
install_lib_cmake $FLUIDSYNTH_DIR $FLUIDSYNTH_ARGS
install_lib_cmake $NLOHMANNJSON_DIR $NLOHMANNJSON_ARGS
install_lib_cmake $FMT_DIR $FMT_ARGS

# emscripten TARGET_HOST does not work for all libraries but SDL2 requires it
export TARGET_HOST="asmjs-unknown-emscripten"
rm -f config.cache
install_lib $SDL2_DIR $SDL2_ARGS --disable-assembly --disable-threads --disable-cpuinfo
rm -f config.cache
unset TARGET_HOST

install_lib_icu_cross
icu_force_data_install

install_lib_liblcf
