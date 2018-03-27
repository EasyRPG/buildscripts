#!/bin/bash

lib=zlib
ver=1.2.11
ZLIB_URL="https://zlib.net/$lib-$ver.tar.gz"
ZLIB_DIR="$lib-$ver"

lib=libpng
ver=1.6.34
LIBPNG_URL="https://ftp-osl.osuosl.org/pub/libpng/src/archive/xz/libpng16/$lib-$ver.tar.xz"
LIBPNG_DIR="$lib-$ver"

lib=freetype
ver=2.9
FREETYPE_URL="https://download.savannah.gnu.org/releases/freetype/$lib-$ver.tar.bz2"
FREETYPE_DIR="$lib-$ver"
FREETYPE_ARGS="--without-bzip2 --without-png --without-zlib"

lib=harfbuzz
ver=1.7.5
HARFBUZZ_URL="https://www.freedesktop.org/software/harfbuzz/release/$lib-$ver.tar.bz2"
HARFBUZZ_DIR="$lib-$ver"
HARFBUZZ_ARGS="--without-glib --without-gobject --without-cairo --without-fontconfig --without-icu"

lib=pixman
ver=0.34.0
PIXMAN_URL="https://cairographics.org/releases/$lib-$ver.tar.gz"
PIXMAN_DIR="$lib-$ver"
PIXMAN_ARGS="--disable-libpng --enable-dependency-tracking"

lib=expat
ver=2.2.5
EXPAT_URL="https://github.com/libexpat/libexpat/releases/download/R_${ver//./_}/$lib-$ver.tar.bz2"
EXPAT_DIR="$lib-$ver"
EXPAT_ARGS="-DBUILD_tools=OFF -DBUILD_examples=OFF -DBUILD_tests=OFF -DBUILD_doc=OFF -DBUILD_shared=OFF"

lib=libogg
ver=1.3.3
LIBOGG_URL="https://downloads.xiph.org/releases/ogg/$lib-$ver.tar.xz"
LIBOGG_DIR="$lib-$ver"

lib=libvorbis
ver=1.3.6
LIBVORBIS_URL="https://downloads.xiph.org/releases/vorbis/$lib-$ver.tar.xz"
LIBVORBIS_DIR="$lib-$ver"

lib=tremor
TREMOR_URL="https://git.xiph.org/?p=tremor.git;a=snapshot;h=b56ffce0c0773ec5ca04c466bc00b1bbcaf65aef;sf=tgz"
TREMOR_DIR="tremor-b56ffce"
TREMOR_FILE="$TREMOR_DIR.tar.gz"

lib=mpg123
ver=1.25.10
MPG123_URL=https://www.mpg123.de/download/$lib-$ver.tar.bz2
MPG123_DIR="$lib-$ver"
MPG123_ARGS="--with-cpu=generic --enable-fifo=no --enable-ipv6=no --enable-network=no \
	--enable-int-quality=no --with-default-audio=dummy --with-optimization=2"

lib=libsndfile
ver=1.0.28
LIBSNDFILE_URL=http://www.mega-nerd.com/libsndfile/files/$lib-$ver.tar.gz
LIBSNDFILE_DIR="$lib-$ver"

lib=libxmp-lite
ver=4.4.1
LIBXMP_LITE_URL="https://easyrpg.org/downloads/sources/$lib-$ver.tar.gz"
LIBXMP_LITE_DIR="$lib-$ver"

lib=speexdsp
ver=1.2rc3
SPEEXDSP_URL="https://downloads.xiph.org/releases/speex/$lib-$ver.tar.gz"
SPEEXDSP_DIR="$lib-$ver"
SPEEXDSP_ARGS="--disable-sse --disable-neon"

lib=libsamplerate
ver=0.1.9
LIBSAMPLERATE_URL="http://www.mega-nerd.com/SRC/$lib-$ver.tar.gz"
LIBSAMPLERATE_DIR="$lib-$ver"

lib=wildmidi
ver=0.4.2
WILDMIDI_URL="https://github.com/Mindwerks/wildmidi/archive/$lib-$ver.tar.gz"
WILDMIDI_DIR="$lib-$lib-$ver"
WILDMIDI_ARGS="-DWANT_PLAYER=OFF -DWANT_STATIC=ON"

lib=opus
ver=1.2.1
OPUS_URL="https://archive.mozilla.org/pub/opus/$lib-$ver.tar.gz"
OPUS_DIR="$lib-$ver"
OPUS_ARGS="--disable-intrinsics"

lib=opusfile
ver=0.10
OPUSFILE_URL="https://archive.mozilla.org/pub/opus/$lib-$ver.tar.gz"
OPUSFILE_DIR="$lib-$ver"
OPUSFILE_ARGS="--disable-http"

lib=ICU
ver=59.1
ICU_URL=http://download.icu-project.org/files/icu4c/$ver/icu4c-${ver//./_}-src.tgz
ICU_DIR="icu"
ICU_ARGS="--enable-strict=no --disable-tests --disable-samples \
	--disable-dyload --disable-extras --disable-icuio \
	--with-data-packaging=static --disable-layout --disable-layoutex"

lib=icudata
ICUDATA_URL=https://ci.easyrpg.org/job/icudata/lastSuccessfulBuild/artifact/icudata.tar.gz
ICUDATA_FILES=icudt*.dat

lib=SDL2
ver=2.0.7
SDL2_URL="https://libsdl.org/release/$lib-$ver.tar.gz"
SDL2_DIR="$lib-$ver"

lib=SDL2_mixer
ver=2.0.1
SDL2_MIXER_URL="https://www.libsdl.org/projects/SDL_mixer/release/$lib-$ver.tar.gz"
SDL2_MIXER_DIR="$lib-$ver"
SDL2_MIXER_ARGS="--with-sdl-prefix=$WORKSPACE --disable-music-ogg \
	--disable-music-midi-fluidsynth --disable-music-midi-fluidsynth-shared \
	--disable-music-mod --disable-music-mp3 --disable-music-flac --disable-sdltest"

# only needed for lmu2png tool
lib=SDL2_image
ver=2.0.1
SDL2_IMAGE_URL="https://www.libsdl.org/projects/SDL_image/release/$lib-$ver.tar.gz"
SDL2_IMAGE_DIR="$lib-$ver"
SDL2_IMAGE_ARGS="--disable-jpg --disable-png-shared --disable-tif --disable-webp"
