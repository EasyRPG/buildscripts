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

SDK_VERSION="6858069_latest"
SDK_URL="https://dl.google.com/android/repository/commandlinetools-${SDK_PLATFORM}-${SDK_VERSION}.zip"
download $SDK_URL
unzip commandlinetools-${SDK_PLATFORM}-${SDK_VERSION}.zip

mkdir -p android-sdk/cmdline-tools/
mv cmdline-tools android-sdk/cmdline-tools/latest

PATH=$PATH:$WORKSPACE/android-sdk

msg " [2] Installing SDK and Platform-tools"

# Otherwise installed to the wrong directory
cd android-sdk

# Android SDK Build-tools, revision 26.0.1
echo "y" | ./cmdline-tools/latest/bin/sdkmanager --verbose "build-tools;28.0.0"
# Android SDK Platform-tools
echo "y" | ./cmdline-tools/latest/bin/sdkmanager --verbose "platform-tools"
# SDK Platform Android 10, API 29
echo "y" | ./cmdline-tools/latest/bin/sdkmanager --verbose "platforms;android-29"
# Android Support Library Repository
echo "y" | ./cmdline-tools/latest/bin/sdkmanager --verbose "extras;android;m2repository"
# Google Repository
echo "y" | ./cmdline-tools/latest/bin/sdkmanager --verbose "extras;google;m2repository"

msg " [3] Installing Android NDK"

echo "y" | ./cmdline-tools/latest/bin/sdkmanager --verbose "ndk;21.4.7075529"

cd ..

msg " [4] Preparing libraries"

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
