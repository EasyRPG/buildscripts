#!/bin/bash

# abort on errors
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

# Supported os : "darwin" or "linux"
os=`uname`
if [ $os = "Darwin" ] ; then
	echo "#############################################################"
	echo "#"
	echo "# macOS / Darwin detected. Please make sure the needed"
	echo "# tools are installed. See the README.md file for reference."
	echo "#"
	echo "#############################################################"
fi

export WORKSPACE=$PWD

# Prepare toolchain

# Download Android SDK
msg " [1] Installing Android SDK"
rm -rf android-sdk/

# Linux
if [ $os = "Linux" ]; then
	SDK_PLATFORM=linux
# MacOS
elif [ $os = "Darwin" ]; then
	SDK_PLATFORM=mac
else
	msg "Only Linux and macOS are supported currently. Sorry! :("
	exit 1
fi

SDK_VERSION="6200805_latest"
SDK_URL="https://dl.google.com/android/repository/commandlinetools-${SDK_PLATFORM}-${SDK_VERSION}.zip"
download $SDK_URL
unzip commandlinetools-${SDK_PLATFORM}-${SDK_VERSION}.zip
mv tools android-sdk

PATH=$PATH:$WORKSPACE/android-sdk

msg " [2] Installing SDK and Platform-tools"

# Otherwise installed to the wrong directory
cd android-sdk

# Android SDK Build-tools, revision 26.0.1
echo "y" | bin/sdkmanager --verbose "build-tools;28.0.0" --sdk_root=$PWD
# Android SDK Platform-tools
echo "y" | bin/sdkmanager --verbose "platform-tools" --sdk_root=$PWD
# SDK Platform Android 3.1, API 12
echo "y" | bin/sdkmanager --verbose "platforms;android-12" --sdk_root=$PWD
# SDK Platform Android 8.0, API 28
echo "y" | bin/sdkmanager --verbose "platforms;android-28" --sdk_root=$PWD
# Android Support Library Repository
echo "y" | bin/sdkmanager --verbose "extras;android;m2repository" --sdk_root=$PWD
# Google Repository
echo "y" | bin/sdkmanager --verbose "extras;google;m2repository" --sdk_root=$PWD

cd ..

msg " [3] Installing Android NDK"
rm -rf android-ndk-r15c/
# Linux
if [ $os = "Linux" ] ; then
	curl -sSLOR https://dl.google.com/android/repository/android-ndk-r15c-linux-x86_64.zip
	unzip android-ndk-r15c-linux-x86_64.zip
# Mac
elif [ $os = "Darwin" ] ; then
	curl -sSLOR http://dl.google.com/android/repository/android-ndk-r15c-darwin-x86_64.bin
	chmod u+x android-ndk-r15c-darwin-x86_64.bin
	./android-ndk-r15c-darwin-x86_64.bin
fi

msg " [4] Preparing libraries"

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

# FluidLite
rm -rf $FLUIDLITE_DIR
download_and_extract $FLUIDLITE_URL

# fmt
rm -rf $FMT_DIR
download_and_extract $FMT_URL

# ICU
rm -rf $ICU_DIR
download_and_extract $ICU_URL

# icudata
rm -f $ICUDATA_FILES
download_and_extract $ICUDATA_URL

# SDL2
rm -rf $SDL2_DIR
download_and_extract $SDL2_URL
