#!/bin/bash

_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $_SCRIPT_DIR/common.sh
source $_SCRIPT_DIR/packages.sh

if [ -f "$SCRIPT_DIR/packages.sh" ]; then
	source $SCRIPT_DIR/packages.sh
fi
