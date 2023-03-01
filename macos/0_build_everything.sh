#!/bin/sh

if [ "$(uname)" != "Darwin" ]; then
	echo "This buildscript requires macOS!"
	exit 1
fi

./1_download_library.sh \
	&& ./2_build_toolchain.sh \
	&& ./3_cleanup.sh
