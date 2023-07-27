#!/bin/bash
set -e

echo "REMOVE THIS LINE";exit 1

# Edit these variables
# Remove _cmake when the lib uses autotools for building
NAME=lhasa
LIBVAR=LHASA
TOOLCHAIN_DIRS=(linux-static macos android emscripten 3ds switch vita wii ios)
CMAKE=

#-------

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

repA="# $NAME\nrm -rf \$${LIBVAR}_DIR\ndownload_and_extract \$${LIBVAR}_URL\n"

repB="install_lib${CMAKE} \$${LIBVAR}_DIR \$${LIBVAR}_ARGS"

for n in "${TOOLCHAIN_DIRS[@]}"
do
	echo "Updating $n"
	sed -i "/# fmt/i\\$repA" $SCRIPT_DIR/../$n/1_*.sh

	if [ $n == "android" ] || [ $n == "macos" ]; then
		OFFSET="\t"
	else
		OFFSET=""
	fi

	sed -i "/install_lib_cmake \$FMT_DIR/i\\${OFFSET}$repB" $SCRIPT_DIR/../$n/2_*.sh

done
