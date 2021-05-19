#!/bin/sh

./1_download_library.sh \
	&& ./2_build_toolchain.sh \
	&& ./3_cleanup.sh

echo
echo "To use the local vita sdk set \"VITASDK=$PWD/vitasdk\"."
echo
