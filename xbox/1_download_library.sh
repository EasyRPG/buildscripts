#!/bin/bash

# abort on errors
set -e

export WORKSPACE=$PWD

# Called NXDK_DEVKIT_DIR because NXDK_DIR is used by NXDK, sorry about the redundancy
export NXDK_DEVKIT_DIR="nxdk"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

NXDK_URL="https://github.com/VannevarXbox/nxdk-EasyRPG/releases/download/0.1/nxdk-easyRPG.zip"
SDL3_URL="https://github.com/VannevarXbox/nxdk-sdl3/releases/download/0.1a/nxdk-sdl3.zip"

msg " [1] Preparing libraries"

# nxdk (New Xbox Development Kit)
rm -rf $NXDK_DEVKIT_DIR
download_and_extract $NXDK_URL

# ALSO INCLUDED WITH NXDK
# zlib
rm -rf $ZLIB_DIR
download_and_extract $ZLIB_URL

# ALSO INCLUDED WITH NXDK
# libpng
rm -rf $LIBPNG_DIR
download_and_extract $LIBPNG_URL

# freetype
rm -rf $FREETYPE_DIR
download_and_extract $FREETYPE_URL

# lhasa
rm -rf $LHASA_DIR
download_and_extract $LHASA_URL

# libxmp-lite
rm -rf $LIBXMP_LITE_DIR
download_and_extract $LIBXMP_LITE_URL

# libsndfile
rm -rf $LIBSNDFILE_DIR
download_and_extract $LIBSNDFILE_URL

# opus
rm -rf $OPUS_DIR
download_and_extract $OPUS_URL

# # opusfile
rm -rf $OPUSFILE_DIR
download_and_extract $OPUSFILE_URL

# libogg
rm -rf $LIBOGG_DIR
download_and_extract $LIBOGG_URL

# libvorbis
rm -rf $LIBVORBIS_DIR
download_and_extract $LIBVORBIS_URL

# nlohmann-json
rm -rf $NLOHMANNJSON_DIR
download_and_extract $NLOHMANNJSON_URL

# # expat
rm -rf $EXPAT_DIR
download_and_extract $EXPAT_URL

# speexdsp
rm -rf $SPEEXDSP_DIR
download_and_extract $SPEEXDSP_URL

# SDL3 (NXDK VERSION)
rm -rf $SDL3_DIR
download_and_extract $SDL3_URL

# ICU
rm -rf $ICU_DIR
download_and_extract $ICU_URL

# # icudata
rm -f $ICUDATA_FILES
download_and_extract $ICUDATA_URL

# FluidLite
rm -rf $FLUIDLITE_DIR
download_and_extract $FLUIDLITE_URL

# fmt
rm -rf $FMT_DIR
download_and_extract $FMT_URL

# inih
rm -rf $INIH_DIR
download_and_extract $INIH_URL

# mpg123
rm -rf $MPG123_DIR
download_and_extract $MPG123_URL

# pixman
rm -rf $PIXMAN_DIR
download_and_extract $PIXMAN_URL

# wildmidi
rm -rf $WILDMIDI_DIR
download_and_extract $WILDMIDI_URL

# liblcf
rm -rf liblcf
download_liblcf


################## NO ######################

# Too heavy for original Xbox
# harfbuzz
# rm -rf $HARFBUZZ_DIR
# download_and_extract $HARFBUZZ_URL




