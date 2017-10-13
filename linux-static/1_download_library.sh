#!/bin/bash

# abort on errors
set -e

export WORKSPACE=$PWD

# helper
function msg {
	echo ""
	echo $1
}

function extract {
	file=$1
	shift

	[ $# -ne 0 ] && msg "Extracting $file..."

	tar xf $file $@
}

function download {
	url=$1
	shift

	[ $# -ne 0 ] && msg "Downloading $url..."

	wget -nv -N $url $@
}

function download_and_extract {
	url=$1
	file=${url##*/}

	msg "Downloading and extracting $file..."

	download $url
	extract $file
}

msg " [1] Preparing libraries"

# zlib
ver=1.2.11
rm -rf zlib-$ver/
download_and_extract https://prdownloads.sourceforge.net/libpng/zlib-$ver.tar.xz

# libpng
ver=1.6.34
rm -rf libpng-$ver/
download_and_extract https://prdownloads.sourceforge.net/libpng/libpng-$ver.tar.xz

# freetype
ver=2.8.1
rm -rf freetype-$ver/
download_and_extract https://download.savannah.gnu.org/releases/freetype/freetype-$ver.tar.bz2

# harfbuzz
ver=1.5.1
rm -rf harfbuzz-$ver/
download_and_extract https://freedesktop.org/software/harfbuzz/release/harfbuzz-$ver.tar.bz2

# pixman
ver=0.34.0
rm -rf pixman-$ver/
download_and_extract https://cairographics.org/releases/pixman-$ver.tar.gz

# expat
ver=2.2.4
rm -rf expat-$ver/
download_and_extract https://prdownloads.sourceforge.net/expat/expat-$ver.tar.bz2

# libogg
ver=1.3.2
rm -rf libogg-$ver/
download_and_extract https://downloads.xiph.org/releases/ogg/libogg-$ver.tar.xz

# libvorbis
ver=1.3.5
rm -rf libvorbis-$ver/
download_and_extract https://downloads.xiph.org/releases/vorbis/libvorbis-$ver.tar.xz

# mpg123
ver=1.25.7
rm -rf mpg123-$ver
download_and_extract https://mpg123.de/download/mpg123-$ver.tar.bz2

# libsndfile
ver=1.0.28
rm -rf libsndfile-$ver
download_and_extract http://mega-nerd.com/libsndfile/files/libsndfile-$ver.tar.gz

# libxmp-lite
ver=4.4.1
rm -rf libxmp-lite-$ver
download_and_extract https://prdownloads.sourceforge.net/xmp/libxmp-lite-$ver.tar.gz

# speexdsp
ver=1.2rc3
rm -rf speexdsp-$ver
download_and_extract https://downloads.xiph.org/releases/speex/speexdsp-$ver.tar.gz

# wildmidi
ver=0.4.1
rm -rf wildmidi-wildmidi-$ver
download_and_extract https://github.com/Mindwerks/wildmidi/archive/wildmidi-$ver.tar.gz

# opus
ver=1.2.1
rm -rf opus-$ver
download_and_extract https://archive.mozilla.org/pub/opus/opus-$ver.tar.gz

# opusfile
ver=0.9
rm -rf opusfile-$ver
download_and_extract https://archive.mozilla.org/pub/opus/opusfile-$ver.tar.gz

# SDL2
ver=2.0.6
rm -rf SDL2-$ver/
download_and_extract https://libsdl.org/release/SDL2-$ver.tar.gz

# SDL2_mixer
ver=2.0.1
rm -rf SDL2_mixer-$ver/
download_and_extract https://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-$ver.tar.gz

# SDL2_image (only needed for lmu2png tool!)
ver=2.0.1
rm -rf SDL2_image-$ver/
download_and_extract https://www.libsdl.org/projects/SDL_image/release/SDL2_image-$ver.tar.gz

# ICU
ver=59.1
rm -rf icu
download_and_extract http://download.icu-project.org/files/icu4c/$ver/icu4c-${ver/./_}-src.tgz

# icudata
rm -f icudt*.dat
download_and_extract https://ci.easyrpg.org/job/icudata/lastSuccessfulBuild/artifact/icudata.tar.gz
