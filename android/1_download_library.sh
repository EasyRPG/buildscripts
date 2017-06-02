#!/bin/bash

# abort on errors
set -e

# Supported os : "darwin" or "linux"
os=`uname`
darwin="Darwin"
linux="Linux"

if [ $os = $darwin ] ; then
	echo "#############################################################"
	echo "#"
	echo "# Mac OSX / Darwin detected. Please make sure the needed"
	echo "# tools are installed. See the README.md file for reference."
	echo "#"
	echo "#############################################################"
fi

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

# Prepare toolchain

# Download Android SDK
msg " [1] Installing Android SDK"
rm -rf android-sdk/

SDK_URL=http://dl.google.com/android/android-sdk_r24.4.1
# Linux
if [ $os = $linux ]; then
	download_and_extract ${SDK_URL}-linux.tgz
	mv android-sdk-linux android-sdk
# MacOS
elif [ $os = $darwin ]; then
	download_and_extract ${SDK_URL}-macosx.zip
	mv android-sdk-macosx android-sdk
else
	msg "Only Linux and MacOS are supported for the moment :(."
	exit 1
fi

PATH=$PATH:$WORKSPACE/android-sdk/tools

msg " [2] Installing SDK and Platform-tools"
# Android SDK Build-tools, revision 23.0.2
echo "y" | android update sdk -u -a -t build-tools-23.0.2
# Android SDK Platform-tools
echo "y" | android update sdk -u -a -t platform-tools
# SDK Platform Android 3.1, API 12
echo "y" | android update sdk -u -a -t android-12
# SDK Platform Android 6.0, API 23
echo "y" | android update sdk -u -a -t android-23
# Android Support Library
echo "y" | android update sdk -u -a -t extra-android-support
# Android Support Library Repository
echo "y" | android update sdk -u -a -t extra-android-m2repository
# Google Repository
echo "y" | android update sdk -u -a -t extra-google-m2repository


msg " [3] Android NDK"
rm -rf android-ndk-r10e/
# Linux
if [ $os = $linux ] ; then
	wget -nv -N http://dl.google.com/android/ndk/android-ndk-r10e-linux-x86_64.bin
	chmod u+x android-ndk-r10e-linux-x86_64.bin
	./android-ndk-r10e-linux-x86_64.bin
# Mac
elif [ $os = $darwin ] ; then
	wget -nv -N http://dl.google.com/android/ndk/android-ndk-r10e-darwin-x86_64.bin
	chmod u+x android-ndk-r10e-darwin-x86_64.bin
	./android-ndk-r10e-darwin-x86_64.bin
fi

msg " [4] preparing libraries"

# libpng
rm -rf libpng-1.6.24/
download_and_extract http://prdownloads.sourceforge.net/libpng/libpng-1.6.24.tar.xz

# freetype
rm -rf freetype-2.6.5/
download_and_extract http://download.savannah.gnu.org/releases/freetype/freetype-2.6.5.tar.bz2

# harfbuzz
rm -rf harfbuzz-1.2.3/
download_and_extract http://www.freedesktop.org/software/harfbuzz/release/harfbuzz-1.2.3.tar.bz2

# pixman
rm -rf pixman-0.34.0/
download_and_extract http://cairographics.org/releases/pixman-0.34.0.tar.gz

# expat
rm -rf expat-2.2.0/
download_and_extract http://sourceforge.net/projects/expat/files/expat/2.2.0/expat-2.2.0.tar.bz2

# libogg
rm -rf libogg-1.3.2/
download_and_extract http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.xz

# libvorbis
rm -rf libvorbis-1.3.5/
download_and_extract http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.5.tar.xz

# mpg123
rm -rf mpg123-1.23.6
download_and_extract http://www.mpg123.de/download/mpg123-1.23.6.tar.bz2

# libsndfile
rm -rf libsndfile-1.0.27
download_and_extract http://www.mega-nerd.com/libsndfile/files/libsndfile-1.0.27.tar.gz

# libxmp-lite
rm -rf libxmp-lite-4.4.0/
download_and_extract http://sourceforge.net/projects/xmp/files/libxmp/4.4.0/libxmp-lite-4.4.0.tar.gz

# speexdsp
rm -rf speexdsp-1.2rc3
download_and_extract http://downloads.xiph.org/releases/speex/speexdsp-1.2rc3.tar.gz

# SDL2
rm -rf SDL2-2.0.4/
download_and_extract http://libsdl.org/release/SDL2-2.0.4.tar.gz

# SDL_mixer
rm -rf SDL2_mixer-2.0.1/
download_and_extract http://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.0.1.tar.gz

# SDL2 (hg)
#rm -rf SDL/
#download https://hg.libsdl.org/SDL/archive/tip.tar.gz -O SDL.tar.gz --no-timestamping
#mkdir -p SDL
#extract SDL.tar.gz --strip-components=1 -C SDL

# SDL_mixer (hg)
#rm -rf SDL_mixer/
#download https://hg.libsdl.org/SDL_mixer/archive/tip.tar.gz -O SDL_mixer.tar.gz --no-timestamping
#mkdir -p SDL_mixer
#extract SDL_mixer.tar.gz --strip-components=1 -C SDL_mixer

# ICU
rm -rf icu
download_and_extract http://download.icu-project.org/files/icu4c/56.1/icu4c-56_1-src.tgz

# icudata
rm -f icudt*.dat
download_and_extract https://easyrpg.org/downloads/tmp/icudata56.tar.gz
