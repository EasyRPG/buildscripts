#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

headermsg "Cleaning up library build folders and other stuff..."

cleanup

rm -f meson-cross.txt
rm -rf libvita2d/

echo " -> done"
