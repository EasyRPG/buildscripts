#!/bin/bash

# abort on errors
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import

# Override ICU version to 58.1
source $SCRIPT_DIR/packages

msg " [1] Installing devkitPPC"

rm -rf devkitPro/
download https://raw.githubusercontent.com/devkitPro/installer/master/perl/devkitPPCupdate.pl
perl devkitPPCupdate.pl $PWD/devkitPro

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

# tremor
rm -rf $TREMOR_DIR
download $TREMOR_URL -O $TREMOR_FILE
extract $TREMOR_FILE

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

msg " [3] Downloading platform libraries"

# SDL+SDL_mixer
rm -rf sdl-wii/
git_clone https://github.com/dborth/sdl-wii.git
