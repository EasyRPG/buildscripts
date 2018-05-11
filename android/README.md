# EasyRPG buildscripts

## Android Toolchain and libraries

Specific building requirements for Linux/OS X:

 - a Java (>=6) SDK

Local build process:

 1. Edit `4_build_android_port` and set `KEYSTORE_PATH` and `KEYSTORE_PASSWORD`
    to the value of your keystore’s path and password
 2. Run `0_build_everything.sh` in a terminal
 3. Open the `Player/builds/android` folder with Eclipse
