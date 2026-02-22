#!/bin/bash

# Downloads the Qt6 precompiled libraries
# These are the official ones from the Qt Project
# Compiling Qt6 is not feasible as it takes hours

curl -LO "https://github.com/miurahr/aqtinstall/releases/download/v3.3.0/aqt-macos"

chmod +x aqt-macos

./aqt-macos install-qt -O qt mac desktop 6.10.1 clang_64 -m all
