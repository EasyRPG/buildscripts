#!/bin/bash

##### GENERATED FILE, DO NOT EDIT! ####
# edit packages.ini and run ini2sh.py #
#######################################


ZLIB_URL="https://zlib.net/fossils/zlib-1.3.2.tar.gz"
ZLIB_ARGS="-DZLIB_BUILD_EXAMPLES=OFF"
ZLIB_DIR="zlib-1.3.2"

LIBPNG_URL="https://download.sourceforge.net/libpng/libpng-1.6.55.tar.xz"
LIBPNG_ARGS="-DPNG_SHARED=OFF -DPNG_TOOLS=OFF -DPNG_TESTS=OFF"
LIBPNG_DIR="libpng-1.6.55"

FREETYPE_URL="https://download.savannah.gnu.org/releases/freetype/freetype-2.14.1.tar.xz"
FREETYPE_ARGS="-DFT_DISABLE_BZIP2=ON -DFT_DISABLE_BROTLI=ON"
FREETYPE_DIR="freetype-2.14.1"

HARFBUZZ_URL="https://github.com/harfbuzz/harfbuzz/releases/download/12.3.2/harfbuzz-12.3.2.tar.xz"
HARFBUZZ_ARGS="-Dfreetype=enabled -Dicu=disabled -Dtests=disabled -Dutilities=disabled" # TODO disable subset
HARFBUZZ_DIR="harfbuzz-12.3.2"

PIXMAN_URL="https://cairographics.org/releases/pixman-0.46.4.tar.gz"
PIXMAN_ARGS="-Dtests=disabled -Ddemos=disabled -Dlibpng=disabled"
PIXMAN_DIR="pixman-0.46.4"

EXPAT_URL="https://github.com/libexpat/libexpat/releases/download/R_2_7_4/expat-2.7.4.tar.bz2"
EXPAT_ARGS="-DEXPAT_BUILD_TOOLS=OFF -DEXPAT_BUILD_EXAMPLES=OFF \
-DEXPAT_BUILD_TESTS=OFF -DEXPAT_BUILD_DOCS=OFF -DEXPAT_SHARED_LIBS=OFF"
EXPAT_DIR="expat-2.7.4"

LIBOGG_URL="https://downloads.xiph.org/releases/ogg/libogg-1.3.6.tar.xz"
LIBOGG_DIR="libogg-1.3.6"

LIBVORBIS_URL="https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.xz"
LIBVORBIS_DIR="libvorbis-1.3.7"

TREMOR_URL="https://gitlab.xiph.org/xiph/tremor/-/archive/820fb3237ea81af44c9cc468c8b4e20128e3e5ad/tremor-820fb3237ea81af44c9cc468c8b4e20128e3e5ad.tar.bz2"
TREMOR_DIR="tremor-820fb3237ea81af44c9cc468c8b4e20128e3e5ad"

MPG123_URL="https://www.mpg123.de/download/mpg123-1.33.4.tar.bz2"
MPG123_ARGS="--with-cpu=generic --disable-fifo --disable-ipv6 --disable-network \
--disable-int-quality --with-default-audio=dummy --with-optimization=2 \
--disable-components --enable-libmpg123"
MPG123_DIR="mpg123-1.33.4"

LIBSNDFILE_URL="https://github.com/libsndfile/libsndfile/releases/download/1.2.2/libsndfile-1.2.2.tar.xz"
LIBSNDFILE_ARGS="--disable-alsa --disable-sqlite --disable-full-suite --disable-external-libs --disable-mpeg"
LIBSNDFILE_DIR="libsndfile-1.2.2"

LIBXMP_LITE_URL="https://github.com/libxmp/libxmp/releases/download/libxmp-4.6.3/libxmp-lite-4.6.3.tar.gz"
LIBXMP_LITE_ARGS="-DBUILD_STATIC=ON -DBUILD_SHARED=OFF"
LIBXMP_LITE_DIR="libxmp-lite-4.6.3"

SPEEXDSP_URL="https://downloads.xiph.org/releases/speex/speexdsp-1.2.1.tar.gz"
SPEEXDSP_ARGS="--disable-sse --disable-neon"
SPEEXDSP_DIR="speexdsp-1.2.1"

LIBSAMPLERATE_URL="https://github.com/libsndfile/libsamplerate/releases/download/0.2.2/libsamplerate-0.2.2.tar.xz"
LIBSAMPLERATE_ARGS="-DLIBSAMPLERATE_EXAMPLES=OFF -DBUILD_TESTING=OFF"
LIBSAMPLERATE_DIR="libsamplerate-0.2.2"

WILDMIDI_URL="https://github.com/Mindwerks/wildmidi/archive/wildmidi-0.4.6.tar.gz"
WILDMIDI_DIR="wildmidi-wildmidi-0.4.6"
WILDMIDI_ARGS="-DWANT_PLAYER=OFF -DWANT_STATIC=ON"

OPUS_URL="https://downloads.xiph.org/releases/opus/opus-1.6.1.tar.gz"
OPUS_ARGS="-DOPUS_DISABLE_INTRINSICS=ON"
OPUS_DIR="opus-1.6.1"

OPUSFILE_URL="https://github.com/xiph/opusfile/releases/download/v0.12/opusfile-0.12.tar.gz"
OPUSFILE_ARGS="--disable-http --disable-examples"
OPUSFILE_DIR="opusfile-0.12"

FLUIDSYNTH_URL="https://github.com/FluidSynth/fluidsynth/archive/refs/tags/v2.5.2.tar.gz"
FLUIDSYNTH_ARGS="-DLIB_SUFFIX='' -Denable-alsa=OFF -Denable-aufile=OFF -Denable-dbus=OFF -Denable-ipv6=OFF -Denable-jack=OFF -Denable-ladspa=OFF -Denable-libinstpatch=OFF -Denable-libsndfile=OFF -Denable-midishare=OFF -Denable-network=OFF -Denable-oss=OFF -Denable-dsound=OFF -Denable-wasapi=OFF -Denable-waveout=OFF -Denable-winmidi=OFF -Denable-sdl3=OFF -Denable-pulseaudio=OFF -Denable-pipewire=OFF -Denable-readline=OFF -Denable-threads=OFF -Denable-openmp=OFF -Denable-unicode=OFF -Denable-native-dls=OFF"
FLUIDSYNTH_DIR="fluidsynth-2.5.2"

FLUIDLITE_URL="https://github.com/divideconcept/FluidLite/archive/4a01cf1c67419e71da971d209f2855bbf4f3bab8.zip"
FLUIDLITE_ARGS="-DFLUIDLITE_BUILD_STATIC=ON -DFLUIDLITE_BUILD_SHARED=OFF"
FLUIDLITE_DIR="FluidLite-4a01cf1c67419e71da971d209f2855bbf4f3bab8"

NLOHMANNJSON_URL="https://github.com/nlohmann/json/archive/v3.12.0.tar.gz"
NLOHMANNJSON_DIR="json-3.12.0"
NLOHMANNJSON_ARGS="-DJSON_BuildTests=OFF"

FMT_URL="https://github.com/fmtlib/fmt/releases/download/12.1.0/fmt-12.1.0.zip"
FMT_ARGS="-DFMT_DOC=OFF -DFMT_TEST=OFF"
FMT_DIR="fmt-12.1.0"

INIH_URL="https://github.com/benhoyt/inih/archive/refs/tags/r62.tar.gz"
INIH_DIR="inih-r62"

LHASA_URL="https://github.com/fragglet/lhasa/releases/download/v0.5.0/lhasa-0.5.0.tar.gz"
LHASA_DIR="lhasa-0.5.0"

ICU_URL="https://github.com/unicode-org/icu/releases/download/release-78.2/icu4c-78.2-sources.tgz"
ICU_DIR="icu"
ICU_ARGS="--enable-strict=no --disable-tests --disable-samples \
--disable-dyload --disable-extras --disable-icuio \
--with-data-packaging=static --disable-layout --disable-layoutex \
--enable-draft=no"

ICUDATA_URL=https://ci.easyrpg.org/job/icudata/lastSuccessfulBuild/artifact/icudata78_all.tar.gz
ICUDATA_FILES="icudt*.dat"

SDL2_URL="https://libsdl.org/release/SDL2-2.32.10.tar.gz"
SDL2_DIR="SDL2-2.32.10"

# 3.18.0, only needed for lmu2png tool
FREEIMAGE_URL="https://github.com/carstene1ns/freeimage-easyrpg/archive/d82954e4adcb6c1b223bd3cb2e953b6bbf54dfcd.zip"
FREEIMAGE_DIR="freeimage-easyrpg-d82954e4adcb6c1b223bd3cb2e953b6bbf54dfcd"

