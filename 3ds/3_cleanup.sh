#!/bin/bash

echo
echo "Cleaning up library build folders and other stuff..."

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import

cleanup

rm -rf sf2dlib/

echo " -> done"
