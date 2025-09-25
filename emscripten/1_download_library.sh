#!/bin/bash

# abort on errors
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

os=`uname`
if [ $os = "Darwin" ] ; then
	echo "#############################################################"
	echo "#"
	echo "# macOS / Darwin detected. Please make sure the needed"
	echo "# tools are installed. See the README.md file for reference."
	echo "#"
	echo "#############################################################"
fi

msg " [1] Checking Emscripten"

if hash emcc >/dev/null 2>&1; then
	echo "Using pre-installed version"
else
	echo "Preparing portable SDK"

	rm -rf emsdk-portable
	git_clone https://github.com/emscripten-core/emsdk.git emsdk-portable

	cd emsdk-portable

	# This empty config file is populated by "emsdk activate".
	# Prevents usage of the global config file in the home directory.
	touch .emscripten

	# Download and install the latest SDK tools and set up the compiler configuration to point to it.
	./emsdk install 4.0.5
	./emsdk activate 4.0.5

	# Set the current Emscripten path
	source ./emsdk_env.sh
fi

cd "$WORKSPACE"

msg " [2] Preparing libraries"

# zlib
rm -rf $ZLIB_DIR
download_and_extract $ZLIB_URL

# libpng
rm -rf $LIBPNG_DIR
download_and_extract $LIBPNG_URL

# freetype
rm -rf $FREETYPE_DIR
download_and_extract $FREETYPE_URL

# harfbuzz
rm -rf $HARFBUZZ_DIR
download_and_extract $HARFBUZZ_URL

# pixman
rm -rf $PIXMAN_DIR
download_and_extract $PIXMAN_URL

# expat
rm -rf $EXPAT_DIR
download_and_extract $EXPAT_URL

# libogg
rm -rf $LIBOGG_DIR
download_and_extract $LIBOGG_URL

# libvorbis
rm -rf $LIBVORBIS_DIR
download_and_extract $LIBVORBIS_URL

# mpg123
rm -rf $MPG123_DIR
download_and_extract $MPG123_URL

# libsndfile
rm -rf $LIBSNDFILE_DIR
download_and_extract $LIBSNDFILE_URL

# libxmp-lite
rm -rf $LIBXMP_LITE_DIR
download_and_extract $LIBXMP_LITE_URL

# speexdsp
rm -rf $SPEEXDSP_DIR
download_and_extract $SPEEXDSP_URL

# wildmidi
#rm -rf $WILDMIDI_DIR
#download_and_extract $WILDMIDI_URL

# opus
rm -rf $OPUS_DIR
download_and_extract $OPUS_URL

# opusfile
rm -rf $OPUSFILE_DIR
download_and_extract $OPUSFILE_URL

# FluidSynth
rm -rf $FLUIDSYNTH_DIR
download_and_extract $FLUIDSYNTH_URL

# nlohmann-json
rm -rf $NLOHMANNJSON_DIR
download_and_extract $NLOHMANNJSON_URL

# inih
rm -rf $INIH_DIR
download_and_extract $INIH_URL

# lhasa
rm -rf $LHASA_DIR
download_and_extract $LHASA_URL

# fmt
rm -rf $FMT_DIR
download_and_extract $FMT_URL

# ICU
rm -rf $ICU_DIR
download_and_extract $ICU_URL

# icudata
rm -f $ICUDATA_FILES
download_and_extract $ICUDATA_URL

# SDL2
rm -rf $SDL2_DIR
download_and_extract $SDL2_URL

# liblcf
rm -rf liblcf
download_liblcf
