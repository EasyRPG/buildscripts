#!/bin/bash

# abort on errors
set -e

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import

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

# ICU
rm -rf $ICU_DIR
download_and_extract $ICU_URL

# icudata
rm -f $ICUDATA_FILES
download_and_extract $ICUDATA_URL

# SDL2
rm -rf $SDL2_DIR
download_and_extract $SDL2_URL
