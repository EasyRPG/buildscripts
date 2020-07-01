#!/bin/bash

# abort on errors
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh
# Override ICU version to 60.2
source $SCRIPT_DIR/packages.sh

# Installation directory
set_workspace

msg " [1] Preparing Emscripten SDK"

# Number of CPU
nproc=$(nproc)
export MAKEFLAGS="-j${nproc:-2}"

rm -rf emsdk-portable
git_clone https://github.com/emscripten-core/emsdk.git emsdk-portable
cd emsdk-portable

# This empty config file is populated by "emsdk activate".
# Prevents usage of the global config file in the home directory.
touch .emscripten

# Fetch the latest registry of available tools.
./emsdk update-tags

# Download and install the latest SDK tools and set up the compiler configuration to point to it.
./emsdk install 1.39.5
./emsdk activate 1.39.5

# Set the current Emscripten path
source ./emsdk_env.sh

cd "$WORKSPACE"

msg " [2] Preparing libraries"

# zlib
rm -rf $ZLIB_DIR
download_and_extract $ZLIB_URL

# libpng
rm -rf $LIBPNG_DIR
download_and_extract $LIBPNG_URL

# freetype
#rm -rf $FREETYPE_DIR
#download_and_extract $FREETYPE_URL

# harfbuzz
#rm -rf $HARFBUZZ_DIR
#download_and_extract $HARFBUZZ_URL

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

# fmt
rm -rf $FMT_DIR
download_and_extract $FMT_URL

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
