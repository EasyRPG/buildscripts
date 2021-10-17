#!/bin/bash

lib=zlib
ver=1.2.11
ZLIB_URL="https://zlib.net/$lib-$ver.tar.gz"
ZLIB_DIR="$lib-$ver"

lib=libpng
ver=1.6.37
LIBPNG_URL="https://download.sourceforge.net/libpng/$lib-$ver.tar.xz"
LIBPNG_DIR="$lib-$ver"

lib=freetype
ver=2.11.0
FREETYPE_URL="https://download.savannah.gnu.org/releases/$lib/$lib-$ver.tar.xz"
FREETYPE_DIR="$lib-$ver"
FREETYPE_ARGS="--without-bzip2 --without-png --without-zlib"

lib=harfbuzz
ver=3.0.0
HARFBUZZ_URL="https://github.com/harfbuzz/harfbuzz/releases/download/$ver/$lib-$ver.tar.xz"
HARFBUZZ_DIR="$lib-$ver"
HARFBUZZ_ARGS="--without-glib --without-gobject --without-cairo --without-fontconfig --without-icu"

lib=pixman
ver=0.40.0
PIXMAN_URL="https://cairographics.org/releases/$lib-$ver.tar.gz"
PIXMAN_DIR="$lib-$ver"
PIXMAN_ARGS="--disable-libpng --enable-dependency-tracking"

lib=expat
ver=2.4.1
EXPAT_URL="https://github.com/libexpat/libexpat/releases/download/R_${ver//./_}/$lib-$ver.tar.bz2"
EXPAT_DIR="$lib-$ver"
EXPAT_ARGS="-DEXPAT_BUILD_TOOLS=OFF -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_TESTS=OFF -DEXPAT_BUILD_DOCS=OFF -DEXPAT_SHARED_LIBS=OFF"

lib=libogg
ver=1.3.5
LIBOGG_URL="https://downloads.xiph.org/releases/ogg/$lib-$ver.tar.xz"
LIBOGG_DIR="$lib-$ver"

lib=libvorbis
ver=1.3.7
LIBVORBIS_URL="https://downloads.xiph.org/releases/vorbis/$lib-$ver.tar.xz"
LIBVORBIS_DIR="$lib-$ver"

lib=tremor
ver=7c30a66346199f3f09017a09567c6c8a3a0eedc8
TREMOR_URL="https://gitlab.xiph.org/xiph/$lib/-/archive/$ver/$lib-$ver.tar.bz2"
TREMOR_DIR="$lib-$ver"

lib=mpg123
ver=1.29.0
MPG123_URL=https://www.mpg123.de/download/$lib-$ver.tar.bz2
MPG123_DIR="$lib-$ver"

lib=libsndfile
ver=1.0.31
LIBSNDFILE_URL=https://github.com/libsndfile/libsndfile/releases/download/$ver/$lib-$ver.tar.bz2
LIBSNDFILE_DIR="$lib-$ver"
LIBSNDFILE_ARGS="--disable-alsa --disable-sqlite --disable-full-suite --disable-external-libs"

lib=libxmp-lite
ver=4.5.0
LIBXMP_LITE_URL="https://github.com/libxmp/libxmp/releases/download/libxmp-$ver/$lib-$ver.tar.gz"
LIBXMP_LITE_DIR="$lib-$ver"

lib=speexdsp
ver=1.2.0
SPEEXDSP_URL="https://downloads.xiph.org/releases/speex/$lib-$ver.tar.gz"
SPEEXDSP_DIR="$lib-$ver"
SPEEXDSP_ARGS="--disable-sse --disable-neon"

lib=libsamplerate
ver=0.2.2
LIBSAMPLERATE_URL="https://github.com/libsndfile/libsamplerate/releases/download/$ver/$lib-$ver.tar.xz"
LIBSAMPLERATE_DIR="$lib-$ver"

lib=wildmidi
ver=0.4.4
WILDMIDI_URL="https://github.com/Mindwerks/wildmidi/archive/$lib-$ver.tar.gz"
WILDMIDI_DIR="$lib-$lib-$ver"
WILDMIDI_ARGS="-DWANT_PLAYER=OFF -DWANT_STATIC=ON"

lib=opus
ver=1.3.1
OPUS_URL="https://archive.mozilla.org/pub/opus/$lib-$ver.tar.gz"
OPUS_DIR="$lib-$ver"
OPUS_ARGS="--disable-intrinsics --disable-extra-programs"

lib=opusfile
ver=0.12
OPUSFILE_URL="https://github.com/xiph/opusfile/releases/download/v$ver/$lib-$ver.tar.gz"
OPUSFILE_DIR="$lib-$ver"
OPUSFILE_ARGS="--disable-http --disable-examples"

lib=fluidsynth
ver=2.2.3
FLUIDSYNTH_URL="https://github.com/FluidSynth/fluidsynth/archive/refs/tags/v$ver.tar.gz"
FLUIDSYNTH_DIR="$lib-$ver"
FLUIDSYNTH_ARGS="-DLIB_SUFFIX=''"

lib=FluidLite
ver=57a0e74e708f699b13d7c85b28a4e1ff5b71887c
FLUIDLITE_URL="https://github.com/divideconcept/$lib/archive/$ver.zip"
FLUIDLITE_DIR="$lib-$ver"
FLUIDLITE_ARGS="-DFLUIDLITE_BUILD_STATIC=ON -DFLUIDLITE_BUILD_SHARED=OFF"

lib=json
ver=3.10.4
NLOHMANNJSON_URL="https://github.com/nlohmann/$lib/archive/v$ver.tar.gz"
NLOHMANNJSON_DIR=$lib-$ver
NLOHMANNJSON_ARGS="-DJSON_BuildTests=OFF"

lib=fmt
ver=8.0.1
FMT_URL="https://github.com/fmtlib/fmt/releases/download/$ver/$lib-$ver.zip"
FMT_DIR="$lib-$ver"
FMT_ARGS="-DFMT_DOC=OFF -DFMT_TEST=OFF"

lib=ICU
ver=69.1
ICU_URL=https://github.com/unicode-org/icu/releases/download/release-${ver//./-}/icu4c-${ver//./_}-src.tgz
ICU_DIR="icu"
ICU_ARGS="--enable-strict=no --disable-tests --disable-samples \
	--disable-dyload --disable-extras --disable-icuio \
	--with-data-packaging=static --disable-layout --disable-layoutex"

lib=icudata
ICUDATA_URL=https://ci.easyrpg.org/job/icudata/lastSuccessfulBuild/artifact/icudata.tar.gz
ICUDATA_FILES=icudt*.dat

lib=SDL2
ver=2.0.16
SDL2_URL="https://libsdl.org/release/$lib-$ver.tar.gz"
SDL2_DIR="$lib-$ver"

# only needed for lmu2png tool
lib=SDL2_image
ver=2.0.5
SDL2_IMAGE_URL="https://www.libsdl.org/projects/SDL_image/release/$lib-$ver.tar.gz"
SDL2_IMAGE_DIR="$lib-$ver"
SDL2_IMAGE_ARGS="--disable-jpg --disable-png-shared --disable-tif --disable-webp"
