#!/bin/bash

# abort on errors
set -e

# Fill these variables:
KEYSTORE_PATH=
KEY_ALIAS=
KEY_PASSWORD=
##############################

export WORKSPACE=$(pwd)
export EASYRPG_TOOLCHAIN_DIR=$(pwd)

# Key signing settings
export ORG_GRADLE_PROJECT_RELEASE_STORE_FILE=$KEYSTORE_PATH
export ORG_GRADLE_PROJECT_RELEASE_KEY_ALIAS=$KEY_ALIAS
export ORG_GRADLE_PROJECT_RELEASE_KEY_PASSWORD=$KEY_PASSWORD
export ORG_GRADLE_PROJECT_RELEASE_STORE_PASSWORD=$KEY_PASSWORD

# Export SDK path
export SDK_ROOT=$WORKSPACE/android-sdk
export ANDROID_HOME=$SDK_ROOT

# EasyRPG Player
if [ ! -d Player/.git ]; then
	git clone https://github.com/EasyRPG/Player.git
fi

cd Player/builds/android
ANDROID_FOLDER=$(pwd)

# Build
./gradlew clean
./gradlew -PtoolchainDirs="${EASYRPG_TOOLCHAIN_DIR}" assembleRelease
./gradlew -PtoolchainDirs="${EASYRPG_TOOLCHAIN_DIR}" bundleRelease

cd $WORKSPACE

echo 'Done!'
echo 'The signed APK is in "Player/builds/android/app/build/outputs/apk/release/"'
echo 'The signed app bundle is in "Player/builds/android/app/build/outputs/bundle/release/"'
