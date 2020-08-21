#!/bin/bash

# abort on errors
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

function download_and_extract_shaders {
	mkdir vitashaders
	cd vitashaders
	download_and_extract https://github.com/frangarcj/vita-shader-collection/releases/download/gtu-0.1-v74/vita-shader-collection.tar.gz
	cd ..
}

msg " [1] Installing Vita SDK"

export VITASDK=$PWD/vitasdk
export URL="https://github.com/vitasdk/autobuilds/releases/download/master-linux-v1100/vitasdk-x86_64-linux-gnu-2020-03-07_21-07-07.tar.bz2"

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

# libvitashaders
rm -rf vitashaders
download_and_extract_shaders

git_clone https://github.com/vitasdk/vdpm

git_clone https://github.com/vitasdk/vita-headers

git_clone https://github.com/frangarcj/vita2dlib
