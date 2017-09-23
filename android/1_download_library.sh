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

# Linux
if [ $os = $linux ]; then
	SDK_PLATFORM=linux
# MacOS
elif [ $os = $darwin ]; then
	SDK_PLATFORM=darwin
else
	msg "Only Linux and MacOS are supported for the moment :(."
	exit 1
fi

SDK_URL="https://dl.google.com/android/repository/sdk-tools-${SDK_PLATFORM}-3859397.zip"
download $SDK_URL
unzip sdk-tools-${SDK_PLATFORM}-3859397.zip
mv tools android-sdk

PATH=$PATH:$WORKSPACE/android-sdk

msg " [2] Installing SDK and Platform-tools"

# Otherwise installed to the wrong directory
cd android-sdk

# Android SDK Build-tools, revision 26.0.1
echo "y" | bin/sdkmanager --verbose "build-tools;26.0.1" --sdk_root=$PWD
# Android SDK Platform-tools
echo "y" | bin/sdkmanager --verbose "platform-tools" --sdk_root=$PWD
# SDK Platform Android 3.1, API 12
echo "y" | bin/sdkmanager --verbose "platforms;android-12" --sdk_root=$PWD
# SDK Platform Android 6.0, API 23
echo "y" | bin/sdkmanager --verbose "platforms;android-23" --sdk_root=$PWD
# Android Support Library Repository
echo "y" | bin/sdkmanager --verbose "extras;android;m2repository" --sdk_root=$PWD
# Google Repository
echo "y" | bin/sdkmanager --verbose "extras;google;m2repository" --sdk_root=$PWD

cd ..

msg " [3] Installing Android NDK"
rm -rf android-ndk-r15c/
# Linux
if [ $os = $linux ] ; then
	wget -nv -N https://dl.google.com/android/repository/android-ndk-r15c-linux-x86_64.zip
	unzip android-ndk-r15c-linux-x86_64.zip
# Mac
elif [ $os = $darwin ] ; then
	wget -nv -N http://dl.google.com/android/repository/android-ndk-r15c-darwin-x86_64.bin
	chmod u+x android-ndk-r15c-darwin-x86_64.bin
	./android-ndk-r15c-darwin-x86_64.bin
fi

msg " [4] Preparing libraries"

# libpng
rm -rf libpng-1.6.32/
download_and_extract http://prdownloads.sourceforge.net/libpng/libpng-1.6.32.tar.xz

# freetype
rm -rf freetype-2.8/
download_and_extract http://download.savannah.gnu.org/releases/freetype/freetype-2.8.tar.bz2

# harfbuzz
rm -rf harfbuzz-1.5.1/
download_and_extract http://www.freedesktop.org/software/harfbuzz/release/harfbuzz-1.5.1.tar.bz2

# pixman
rm -rf pixman-0.34.0/
download_and_extract http://cairographics.org/releases/pixman-0.34.0.tar.gz

# expat
rm -rf expat-2.2.4/
download_and_extract http://sourceforge.net/projects/expat/files/expat/2.2.4/expat-2.2.4.tar.bz2

# libogg
rm -rf libogg-1.3.2/
download_and_extract http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.xz

# libvorbis
rm -rf libvorbis-1.3.5/
download_and_extract http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.5.tar.xz

# mpg123
rm -rf mpg123-1.25.6
download_and_extract http://www.mpg123.de/download/mpg123-1.25.6.tar.bz2

# libsndfile
rm -rf libsndfile-1.0.28
download_and_extract http://www.mega-nerd.com/libsndfile/files/libsndfile-1.0.28.tar.gz

# libxmp-lite
rm -rf libxmp-lite-4.4.1
download_and_extract http://sourceforge.net/projects/xmp/files/libxmp/4.4.1/libxmp-lite-4.4.1.tar.gz

# speexdsp
rm -rf speexdsp-1.2rc3
download_and_extract http://downloads.xiph.org/releases/speex/speexdsp-1.2rc3.tar.gz

# wildmidi
rm -rf wildmidi-wildmidi-0.4.1
download_and_extract https://github.com/Mindwerks/wildmidi/archive/wildmidi-0.4.1.tar.gz

# opus
rm -rf opus-1.2.1
download_and_extract https://archive.mozilla.org/pub/opus/opus-1.2.1.tar.gz

# opusfile
rm -rf opusfile-0.9
download_and_extract https://archive.mozilla.org/pub/opus/opusfile-0.9.tar.gz

# SDL2
rm -rf SDL2-2.0.6/
download_and_extract http://libsdl.org/release/SDL2-2.0.6.tar.gz

# ICU
rm -rf icu
download_and_extract http://download.icu-project.org/files/icu4c/59.1/icu4c-59_1-src.tgz

# icudata
rm -f icudt*.dat
download_and_extract https://ci.easyrpg.org/job/icudata/lastSuccessfulBuild/artifact/icudata.tar.gz
