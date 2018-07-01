#!/bin/bash

# abort on errors
set -e

# Fill these variables:
KEYSTORE_PATH=
KEYSTORE_PASSWORD=
##############################

export WORKSPACE=$(pwd)
export EASYDEV_ANDROID=$(pwd)

# Number of CPU
NBPROC=$(getconf _NPROCESSORS_ONLN)

# Export NDK path
export NDK_ROOT=$WORKSPACE/android-ndk-r15c
export PATH=$PATH:$NDK_ROOT

# Export SDK path
export SDK_ROOT=$WORKSPACE/android-sdk
export ANDROID_HOME=$SDK_ROOT
export PATH=$PATH:$SDK_ROOT:$SDK_ROOT/build-tools/28.0.0/

# EasyRPG Player
if [ -d Player/.git ]; then
	git -C Player pull
else
	git clone https://github.com/EasyRPG/Player.git
fi

cd Player/builds/android
ANDROID_FOLDER=$(pwd)

# Timidity (midi player)
cd $ANDROID_FOLDER/app/src/main
if [ -d assets/timidity/.git ]; then
	git -C assets/timidity pull
else
	git clone https://github.com/Ghabry/timidity_gus.git assets/timidity
fi

# Build
ndk-build -j$NBPROC NDK_DEBUG=0 NDK_LIBS_OUT=./jniLibs
cd $ANDROID_FOLDER
./gradlew clean
./gradlew assembleRelease

# Sign the .apk
cd $ANDROID_FOLDER/app/build/outputs/apk
jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEYSTORE_PATH -storepass $KEYSTORE_PASSWORD app-release-unsigned.apk nightly
zipalign 4 app-release-unsigned.apk EasyRpgPlayerActivity.apk

cd $WORKSPACE
