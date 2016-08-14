#!/bin/bash

# abort on errors
set -e

./1_download_library.sh
./2_build_toolchain.sh
./3_build_liblcf.sh
./4_build_android_port.sh
