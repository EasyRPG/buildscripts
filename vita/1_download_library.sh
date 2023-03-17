#!/bin/bash

# abort on errors
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

msg " [1] Installing local Vita SDK"

export VITASDK=$PWD/vitasdk
VERSION=master-linux-v2.481/vitasdk-x86_64-linux-gnu-2023-03-17_05-46-17.tar.bz2
export URL="https://github.com/vitasdk/autobuilds/releases/download/$VERSION"

mkdir -p vitasdk
curl -sSLR -o vitasdk-nightly.tar.bz2 "$URL"
tar xf "vitasdk-nightly.tar.bz2" -C $VITASDK --strip-components=1

msg " [2] Downloading generic libraries"

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

# FluidLite
rm -rf $FLUIDLITE_DIR
download_and_extract $FLUIDLITE_URL

# fmt
rm -rf $FMT_DIR
download_and_extract $FMT_URL

# ICU
rm -rf $ICU_DIR
download_and_extract $ICU_URL

# icudata
rm -f $ICUDATA_FILES
download_and_extract $ICUDATA_URL

msg " [3] Downloading platform libraries"

# libvita2d
git_clone https://github.com/xerpi/libvita2d.git

# liblcf
rm -rf liblcf
download_liblcf
