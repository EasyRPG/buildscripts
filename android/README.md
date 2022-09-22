# EasyRPG buildscripts

## Android Toolchain and libraries

Specific building requirements for Linux/OS X:

 - a Java (>=11) SDK

Local build process:

 1. To build liblcf set environment variable `BUILD_LIBLCF` to `1`
 2. Edit `4_build_android_port` and set `KEYSTORE_PATH`, `KEY_ALIAS` and `KEY_PASSWORD`
    to the value of your keystore’s path and password
 3. Run `0_build_everything.sh` in a terminal
 4. Open the `Player/builds/android` folder with Android Studio
