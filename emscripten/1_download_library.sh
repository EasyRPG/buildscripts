#!/bin/bash

# abort on errors
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import
source $SCRIPT_DIR/packages

msg " [1] Preparing Emscripten SDK"

# Number of CPU
nproc=$(nproc)
export MAKEFLAGS="-j${nproc:-2}"

download_and_extract https://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-portable.tar.gz
cd emsdk-portable

# Fetch the latest registry of available tools.
./emsdk update

# Download and install the latest SDK tools and set up the compiler configuration to point to it.
./emsdk install sdk-master-64bit
./emsdk activate sdk-master-64bit

# Set the current Emscripten path
# The following line fails to run in jenkins jobs. Running inner called scripts instead works.
#. ./emsdk_env.sh
./emsdk construct_env
. ./emsdk_set_env.sh

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
rm -rf $WILDMIDI_DIR
download_and_extract $WILDMIDI_URL

# opus
rm -rf $OPUS_DIR
download_and_extract $OPUS_URL

# opusfile
rm -rf $OPUSFILE_DIR
download_and_extract $OPUSFILE_URL

# ICU
rm -rf $ICU_DIR
download_and_extract $ICU_URL

# icudata
rm -f $ICUDATA_FILES
download_and_extract $ICUDATA_URL

# icudata
rm -f icudt*.dat
download_and_extract https://ci.easyrpg.org/job/icudata/lastSuccessfulBuild/artifact/icudata.tar.gz

msg " [2] Preparing platform libraries"

# SDL2
rm -rf SDL2/
git clone --depth=1 https://github.com/emscripten-ports/SDL2.git
