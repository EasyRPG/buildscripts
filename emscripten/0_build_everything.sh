#!/bin/sh

./1_download_library.sh \
	&& ./2_build_toolchain.sh \
	&& ./3_cleanup.sh
