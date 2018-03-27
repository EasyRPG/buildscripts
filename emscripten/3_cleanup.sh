#!/bin/sh

echo
echo "Cleaning up library build folders and other stuff..."

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

cleanup

rm -rf SDL2/

echo " -> done"
