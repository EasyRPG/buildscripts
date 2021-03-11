#!/bin/bash

# abort on errors
set -e

# Fill these variables:
KEYSTORE_PATH=
KEYSTORE_PASSWORD=
KEYSTORE_NAME=
##############################

export WORKSPACE=$(pwd)
export EASYRPG_TOOLCHAIN_DIR=$(pwd)

# Number of CPU
NBPROC=$(getconf _NPROCESSORS_ONLN)

# Export SDK path
export SDK_ROOT=$WORKSPACE/android-sdk
export ANDROID_HOME=$SDK_ROOT
export PATH=$PATH:$SDK_ROOT:$SDK_ROOT/build-tools/28.0.0/

# Export NDK path
export NDK_ROOT=$SDK_ROOT/ndk/21.4.7075529
export PATH=$PATH:$NDK_ROOT

# EasyRPG Player
if [ ! -d Player/.git ]; then
	git clone https://github.com/EasyRPG/Player.git
fi

cd Player/builds/android
ANDROID_FOLDER=$(pwd)

# Timidity (midi player)
cd $ANDROID_FOLDER/app/src/main
if [ ! -d assets/timidity/.git ]; then
	git clone https://github.com/Ghabry/timidity_gus.git assets/timidity
fi

# Build
cd $ANDROID_FOLDER
./gradlew clean
./gradlew -PtoolchainDirs="${EASYRPG_TOOLCHAIN_DIR}" assembleRelease

# Sign the .apk
cd $ANDROID_FOLDER/app/build/outputs/apk
jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEYSTORE_PATH -storepass $KEYSTORE_PASSWORD app-release-unsigned.apk $KEYSTORE_NAME
zipalign 4 app-release-unsigned.apk EasyRpgPlayerActivity.apk

cd $WORKSPACE
