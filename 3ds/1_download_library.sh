#!/bin/bash

# abort on errors
set -e

# helper
function msg {
  echo ""
  echo $1
}

function download_and_extract {
	url=$1
	file=${url##*/}

	msg "Downloading and extracting $file..."

	wget -nv -N $url
	tar xf $file
}

function git_clone {
	url=$1
	file=${url##*/}
	msg "Cloning $file..."

	git clone $url
}

msg " [1] Installing devkitARM"

rm -rf $PWD/devkitPro
wget -nv https://sourceforge.net/projects/devkitpro/files/Automated%20Installer/devkitARMupdate.pl
perl devkitARMupdate.pl $PWD/devkitPro

msg " [2] Downloading generic libraries"

# zlib
rm -rf zlib-1.2.11
download_and_extract http://zlib.net/zlib-1.2.11.tar.gz

# libpng
rm -rf libpng-1.6.23/
download_and_extract http://prdownloads.sourceforge.net/libpng/libpng-1.6.23.tar.xz

# freetype
rm -rf freetype-2.6.3/
download_and_extract http://download.savannah.gnu.org/releases/freetype/freetype-2.6.3.tar.bz2

# harfbuzz
rm -rf harfbuzz-1.2.3/
download_and_extract http://www.freedesktop.org/software/harfbuzz/release/harfbuzz-1.2.3.tar.bz2

# pixman
rm -rf pixman-0.34.0/
download_and_extract http://cairographics.org/releases/pixman-0.34.0.tar.gz

# libogg
rm -rf libogg-1.3.2/
download_and_extract http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.xz

# libtremor
rm -rf tremor-lowmem/
download_and_extract http://downloads.sourceforge.net/sourceforge/devkitpro/tremor-lowmem-src.tar.bz2

# libmodplug
rm -rf libmodplug-0.8.8.5/
download_and_extract http://sourceforge.net/projects/modplug-xmms/files/libmodplug/0.8.8.5/libmodplug-0.8.8.5.tar.gz

# ICU
rm -rf icu
download_and_extract http://download.icu-project.org/files/icu4c/58.1/icu4c-58_1-src.tgz

# icudata
rm -f icudt*.dat
download_and_extract https://ci.easyrpg.org/job/icudata/lastSuccessfulBuild/artifact/icudata.tar.gz

# mpg123
rm -rf mpg123-1.23.3
download_and_extract http://www.mpg123.de/download/mpg123-1.23.3.tar.bz2

# libsndfile
rm -rf libsndfile-1.0.27
download_and_extract http://www.mega-nerd.com/libsndfile/files/libsndfile-1.0.27.tar.gz

# speexdsp
rm -rf speexdsp-1.2rc3
download_and_extract http://downloads.xiph.org/releases/speex/speexdsp-1.2rc3.tar.gz

# wildmidi
rm -rf wildmidi-wildmidi-0.3.11/
download_and_extract https://github.com/Mindwerks/wildmidi/archive/wildmidi-0.3.11.tar.gz

msg " [3] Downloading platform libraries"

# 3DS specific
rm -rf sf2dlib
git_clone https://github.com/xerpi/sf2dlib.git
