#!/bin/bash

echo
echo "Cleaning up library build folders and other stuff..."

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

cleanup

rm -rf vdpm/ vita2dlib/ vitashaders/ vita-headers/

echo " -> done"
