#!/bin/bash

# abort on error
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

# Override ICU version to 58.1, custom SDL
source $SCRIPT_DIR/packages.sh

# Number of CPU
nproc=$(nproc)

# Use ccache?
test_ccache

# Toolchain available?
if [[ -z $DEVKITPRO || -z $DEVKITPPC ]]; then
	echo "Setup devkitPPC properly. \$DEVKITPRO and \$DEVKITPPC need to be set."
	exit 1
fi

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	# Fix mpg123
	(cd $MPG123_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/mpg123.patch
		autoreconf -fi
	)

	# Fix libsndfile
	(cd $LIBSNDFILE_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/libsndfile.patch
		# do not fortify source
		perl -pi -e 's/AX_ADD_FORTIFY_SOURCE//' configure.ac
		autoreconf -fi
	)

	# Fix opus
	(cd $OPUS_DIR
		# do not fortify source
		perl -pi -e 's/AX_ADD_FORTIFY_SOURCE//' configure.ac
		autoreconf -fi
	)

	# Fix harfbuzz
	(cd $HARFBUZZ_DIR
		patch -Np1 < $SCRIPT_DIR/../shared/extra/harfbuzz-climits.patch
	)

	cp -rup icu icu-native
	# Fix ICU compilation problems on Wii
	patch -Np0 < icu-wii.patch
	# Emit correct bigendian icudata header
	patch -Np0 < icu-pkg_genc.patch

	# Patch SDL+SDL_mixer
	patch -d $SDL_DIR --binary -Np1 < $SCRIPT_DIR/sdl-wii.patch
	# newlib fix until resolved upstream
	patch -d $SDL_DIR --binary -Np1 < $SCRIPT_DIR/sdl-wii-fix-build.patch

	touch .patches-applied
fi

cd $WORKSPACE

echo "Preparing toolchain"

export PATH=$DEVKITPPC/bin:$PATH

export PLATFORM_PREFIX=$WORKSPACE
export TARGET_HOST=powerpc-eabi
unset PKG_CONFIG_PATH
export PKG_CONFIG_LIBDIR=$PLATFORM_PREFIX/lib/pkgconfig
export MAKEFLAGS="-j${nproc:-2}"

function set_build_flags {
	export CC="$TARGET_HOST-gcc"
	export CXX="$TARGET_HOST-g++"
	if [ "$ENABLE_CCACHE" ]; then
		export CC="ccache $CC"
		export CXX="ccache $CXX"
	fi
	export CFLAGS="-g0 -O2 -mcpu=750 -meabi -mhard-float -ffunction-sections -fdata-sections"
	export CXXFLAGS=$CFLAGS
	export CPPFLAGS="-I$PLATFORM_PREFIX/include -DGEKKO"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib"
}

function install_lib_sdl() {
	msg "Building SDL"

	(cd $SDL_DIR/SDL
		make clean
		make install INSTALL_HEADER_DIR="$WORKSPACE/include" INSTALL_LIB_DIR="$WORKSPACE/lib"
	)
}

function install_lib_sdlmixer() {
	msg "Building SDL_mixer"

	(cd $SDL_DIR/SDL_mixer
		make clean
		make install INSTALL_HEADER_DIR="$WORKSPACE/include" INSTALL_LIB_DIR="$WORKSPACE/lib"
	)
}

install_lib_icu_native_without_assembly

set_build_flags

install_lib_zlib
install_lib $LIBPNG_DIR $LIBPNG_ARGS
install_lib $FREETYPE_DIR $FREETYPE_ARGS --without-harfbuzz
install_lib $HARFBUZZ_DIR $HARFBUZZ_ARGS
install_lib $FREETYPE_DIR $FREETYPE_ARGS --with-harfbuzz
install_lib $PIXMAN_DIR $PIXMAN_ARGS --disable-vmx
install_lib_cmake $EXPAT_DIR $EXPAT_ARGS
install_lib $LIBOGG_DIR $LIBOGG_ARGS
install_lib $TREMOR_DIR $TREMOR_ARGS
install_lib_mpg123
install_lib $LIBSNDFILE_DIR $LIBSNDFILE_ARGS
install_lib_cmake $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS
install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS
install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS
install_lib_cmake $FLUIDLITE_DIR $FLUIDLITE_ARGS
install_lib $OPUS_DIR $OPUS_ARGS
install_lib $OPUSFILE_DIR $OPUSFILE_ARGS
install_lib_cmake $FMT_DIR $FMT_ARGS
install_lib_icu_cross

install_lib_sdl
install_lib_sdlmixer
