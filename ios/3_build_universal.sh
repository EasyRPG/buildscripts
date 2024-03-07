#!/bin/bash

if [ "$(uname)" != "Darwin" ]; then
	echo "This buildscript requires macOS!"
	exit 1
fi

# abort on error
set -e

echo "Creating universal libraries"

# Prepare
rm -rf universal
mkdir -p universal

# Copy files needed by CMake
cp -R armv7/bin armv7/include armv7/lib universal

# Merge the libraries with lipo
for armv7_file in $(find armv7/lib -type f -name "*.a")
do
	filename=$(basename $armv7_file)
	arm64_file="arm64/lib/$filename"
	universal_file="universal/lib/$filename"
	echo "Merging $filename"
	lipo -create "$armv7_file" "$arm64_file" -output "$universal_file"
done
