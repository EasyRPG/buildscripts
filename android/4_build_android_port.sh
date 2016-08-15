#!/bin/bash

#	<!> Fill thoses variables :
KEYSTORE_PATH=
KEYSTORE_PASSWORD=
##############################

export WORKSPACE=$(pwd)
export EASYDEV_ANDROID=$(pwd)

# Number of CPU
NBPROC=$(getconf _NPROCESSORS_ONLN)

# Export NDK path
export NDK_ROOT=$WORKSPACE/android-ndk-r10e
export PATH=$PATH:$NDK_ROOT

# Export SDK path
export SDK_ROOT=$WORKSPACE/android-sdk
export ANDROID_HOME=$WORKSPACE/android-sdk
export PATH=$PATH:$SDK_ROOT/tools:$SDK_ROOT/build-tools/23.0.2/

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

# The target 1 should be API 12 if the user followed the script number 1 :
android update project --path "." --target 1

# Build
ndk-build -j$NBPROC NDK_LIBS_OUT=./jniLibs
cd $ANDROID_FOLDER
./gradlew clean
./gradlew assembleRelease

# Sign the .apk
cd $ANDROID_FOLDER/app/build/outputs/apk
jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEYSTORE_PATH -storepass $KEYSTORE_PASSWORD app-release-unsigned.apk nightly
zipalign 4 app-release-unsigned.apk EasyRpgPlayerActivity.apk

cd $WORKSPACE
