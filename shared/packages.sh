#!/bin/bash

##### GENERATED FILE, DO NOT EDIT! ####
# edit packages.ini and run ini2sh.py #
#######################################


ZLIB_URL="https://zlib.net/fossils/zlib-1.3.1.tar.gz"
ZLIB_ARGS="-DZLIB_BUILD_EXAMPLES=OFF"
ZLIB_DIR="zlib-1.3.1"

LIBPNG_URL="https://download.sourceforge.net/libpng/libpng-1.6.39.tar.xz"
LIBPNG_ARGS="-DPNG_SHARED=OFF -DPNG_EXECUTABLES=OFF -DPNG_TESTS=OFF"
LIBPNG_DIR="libpng-1.6.39"

FREETYPE_URL="https://download.savannah.gnu.org/releases/freetype/freetype-2.13.3.tar.xz"
FREETYPE_ARGS="-DFT_DISABLE_BZIP2=ON -DFT_DISABLE_BROTLI=ON"
FREETYPE_DIR="freetype-2.13.3"

HARFBUZZ_URL="https://github.com/harfbuzz/harfbuzz/releases/download/10.4.0/harfbuzz-10.4.0.tar.xz"
HARFBUZZ_ARGS="-Dfreetype=enabled -Dicu=disabled -Dtests=disabled -Dutilities=disabled" # TODO disable subset
HARFBUZZ_DIR="harfbuzz-10.4.0"

PIXMAN_URL="https://cairographics.org/releases/pixman-0.44.2.tar.gz"
PIXMAN_ARGS="-Dtests=disabled -Ddemos=disabled -Dlibpng=disabled"
PIXMAN_DIR="pixman-0.44.2"

EXPAT_URL="https://github.com/libexpat/libexpat/releases/download/R_2_7_0/expat-2.7.0.tar.bz2"
EXPAT_ARGS="-DEXPAT_BUILD_TOOLS=OFF -DEXPAT_BUILD_EXAMPLES=OFF \
-DEXPAT_BUILD_TESTS=OFF -DEXPAT_BUILD_DOCS=OFF -DEXPAT_SHARED_LIBS=OFF"
EXPAT_DIR="expat-2.7.0"

LIBOGG_URL="https://downloads.xiph.org/releases/ogg/libogg-1.3.5.tar.xz"
LIBOGG_DIR="libogg-1.3.5"

LIBVORBIS_URL="https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.xz"
LIBVORBIS_DIR="libvorbis-1.3.7"

TREMOR_URL="https://gitlab.xiph.org/xiph/tremor/-/archive/7c30a66346199f3f09017a09567c6c8a3a0eedc8/tremor-7c30a66346199f3f09017a09567c6c8a3a0eedc8.tar.bz2"
TREMOR_DIR="tremor-7c30a66346199f3f09017a09567c6c8a3a0eedc8"

MPG123_URL="https://www.mpg123.de/download/mpg123-1.32.10.tar.bz2"
MPG123_ARGS="--with-cpu=generic --disable-fifo --disable-ipv6 --disable-network \
--disable-int-quality --with-default-audio=dummy --with-optimization=2 \
--disable-components --enable-libmpg123"
MPG123_DIR="mpg123-1.32.10"

LIBSNDFILE_URL="https://github.com/libsndfile/libsndfile/releases/download/1.2.2/libsndfile-1.2.2.tar.xz"
LIBSNDFILE_ARGS="--disable-alsa --disable-sqlite --disable-full-suite --disable-external-libs --disable-mpeg"
LIBSNDFILE_DIR="libsndfile-1.2.2"

LIBXMP_LITE_URL="https://github.com/libxmp/libxmp/releases/download/libxmp-4.6.2/libxmp-lite-4.6.2.tar.gz"
LIBXMP_LITE_ARGS="-DBUILD_STATIC=ON -DBUILD_SHARED=OFF"
LIBXMP_LITE_DIR="libxmp-lite-4.6.2"

SPEEXDSP_URL="https://downloads.xiph.org/releases/speex/speexdsp-1.2.1.tar.gz"
SPEEXDSP_ARGS="--disable-sse --disable-neon"
SPEEXDSP_DIR="speexdsp-1.2.1"

LIBSAMPLERATE_URL="https://github.com/libsndfile/libsamplerate/releases/download/0.2.2/libsamplerate-0.2.2.tar.xz"
LIBSAMPLERATE_DIR="libsamplerate-0.2.2"

WILDMIDI_URL="https://github.com/Mindwerks/wildmidi/archive/wildmidi-0.4.6.tar.gz"
WILDMIDI_DIR="wildmidi-wildmidi-0.4.6"
WILDMIDI_ARGS="-DWANT_PLAYER=OFF -DWANT_STATIC=ON"

OPUS_URL="https://downloads.xiph.org/releases/opus/opus-1.5.2.tar.gz"
OPUS_ARGS="--disable-intrinsics --disable-extra-programs"
OPUS_DIR="opus-1.5.2"

OPUSFILE_URL="https://github.com/xiph/opusfile/releases/download/v0.12/opusfile-0.12.tar.gz"
OPUSFILE_ARGS="--disable-http --disable-examples"
OPUSFILE_DIR="opusfile-0.12"

FLUIDSYNTH_URL="https://github.com/FluidSynth/fluidsynth/archive/refs/tags/v2.4.4.tar.gz"
FLUIDSYNTH_ARGS="-DLIB_SUFFIX=''"
FLUIDSYNTH_DIR="fluidsynth-2.4.4"

FLUIDLITE_URL="https://github.com/divideconcept/FluidLite/archive/57a0e74e708f699b13d7c85b28a4e1ff5b71887c.zip"
FLUIDLITE_ARGS="-DFLUIDLITE_BUILD_STATIC=ON -DFLUIDLITE_BUILD_SHARED=OFF"
FLUIDLITE_DIR="FluidLite-57a0e74e708f699b13d7c85b28a4e1ff5b71887c"

NLOHMANNJSON_URL="https://github.com/nlohmann/json/archive/v3.11.3.tar.gz"
NLOHMANNJSON_DIR="json-3.11.3"
NLOHMANNJSON_ARGS="-DJSON_BuildTests=OFF"

FMT_URL="https://github.com/fmtlib/fmt/releases/download/11.1.4/fmt-11.1.4.zip"
FMT_ARGS="-DFMT_DOC=OFF -DFMT_TEST=OFF"
FMT_DIR="fmt-11.1.4"

INIH_URL="https://github.com/benhoyt/inih/archive/refs/tags/r58.tar.gz"
INIH_DIR="inih-r58"

LHASA_URL="https://github.com/fragglet/lhasa/releases/download/v0.4.0/lhasa-0.4.0.tar.gz"
LHASA_DIR="lhasa-0.4.0"

ICU_URL="https://github.com/unicode-org/icu/releases/download/release-77-1/icu4c-77_1-src.tgz"
ICU_DIR="icu"
ICU_ARGS="--enable-strict=no --disable-tests --disable-samples \
--disable-dyload --disable-extras --disable-icuio \
--with-data-packaging=static --disable-layout --disable-layoutex \
--enable-draft=no"

ICUDATA_URL=https://ci.easyrpg.org/job/icudata/lastSuccessfulBuild/artifact/icudata77_all.tar.gz
ICUDATA_FILES="icudt*.dat"

SDL2_URL="https://libsdl.org/release/SDL2-2.32.2.tar.gz"
SDL2_DIR="SDL2-2.32.2"

# 3.18.0, only needed for lmu2png tool
FREEIMAGE_URL="https://github.com/carstene1ns/freeimage-easyrpg/archive/d82954e4adcb6c1b223bd3cb2e953b6bbf54dfcd.zip"
FREEIMAGE_DIR="freeimage-easyrpg-d82954e4adcb6c1b223bd3cb2e953b6bbf54dfcd"

