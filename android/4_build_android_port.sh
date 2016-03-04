#	Please complete :
KEYSTORE_PATH=
KEYSTORE_PASSWORD=

#	Tip : desactivate mips compilation (which can cause problem)
#	in Player/builds/android/jni/Application.mk
#	in the APP_ABI variable

#!/bin/bash
export WORKSPACE=$(pwd)

export EASYDEV_ANDROID=$(pwd)

#export ndk path
export NDK_ROOT=$WORKSPACE/android-ndk-r10e
export PATH=$PATH:$NDK_ROOT

#export sdk path 
export SDK_ROOT=$WORKSPACE/android-sdk
export PATH=$PATH:$SDK_ROOT/tools:$SDK_ROOT/build-tools/23.0.2/	

git clone https://github.com/EasyRPG/Player.git

cd Player/builds/android

# Update the Player
git pull https://github.com/EasyRPG/Player.git

# Obtain timidity (for midi player)
git clone https://github.com/Ghabry/timidity_gus.git assets/timidity

#Pour connaitre les targets : 
#The target 1 should be API 12 if the user followed the script number 1
android update project --path "." --target 1

ndk-build -j2
ant clean
ant release

cd bin
jarsigner -sigalg MD5withRSA -digestalg SHA1 -keystore $KEYSTORE_PATH -storepass $KEYSTORE_PASSWORD SDLActivity-release-unsigned.apk nightly
zipalign 4 SDLActivity-release-unsigned.apk EasyRpgPlayerActivity.apk

cd $WORKSPACE