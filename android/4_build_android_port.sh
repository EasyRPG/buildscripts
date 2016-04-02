#!/bin/bash

#	Please complete :
KEYSTORE_PATH=
KEYSTORE_PASSWORD=

export WORKSPACE=$(pwd)
export EASYDEV_ANDROID=$(pwd)
#Number of CPU
NBPROC=$(getconf _NPROCESSORS_ONLN)

#export ndk path
export NDK_ROOT=$WORKSPACE/android-ndk-r10e
export PATH=$PATH:$NDK_ROOT

#export sdk path
export SDK_ROOT=$WORKSPACE/android-sdk
export ANDROID_HOME=$WORKSPACE/android-sdk
export PATH=$PATH:$SDK_ROOT/tools:$SDK_ROOT/build-tools/23.0.2/

git clone https://github.com/EasyRPG/Player.git

cd Player/builds/android
ANDROID_FOLDER=$(pwd)

# Update the Player
git pull https://github.com/EasyRPG/Player.git

# Obtain timidity (for midi player)
cd $ANDROID_FOLDER/app/src/main
git clone https://github.com/Ghabry/timidity_gus.git assets/timidity

#The target 1 should be API 12 if the user followed the script number 1 :
android update project --path "." --target 1

# Build
ndk-build -j$NBPROC NDK_LIBS_OUT=./jniLibs
cd $ANDROID_FOLDER
./gradlew clean
./gradlew assembleRelease

#Sign the apk
cd $ANDROID_FOLDER/app/build/outputs/apk
jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEYSTORE_PATH -storepass $KEYSTORE_PASSWORD app-release-unsigned.apk nightly
zipalign 4 app-release-unsigned.apk EasyRpgPlayerActivity.apk

cd $WORKSPACE
