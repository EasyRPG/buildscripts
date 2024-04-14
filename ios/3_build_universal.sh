#!/bin/bash

if [ "$(uname)" != "Darwin" ]; then
	echo "This buildscript requires macOS!"
	exit 1
fi

# abort on error
set -e

echo "Creating universal libraries"

# prepare
rm -rf universal
mkdir -p universal

# copy files needed by CMake, doesn't matter if armv7 or arm64
cp -R armv7/bin armv7/include armv7/lib universal

# merge the libraries with lipo
for armv7_file in $(find armv7/lib -type f -name "*.a")
do
	filename=$(basename $armv7_file)
	arm64_file="arm64/lib/$filename"
	uni_file="universal/lib/$filename"

	echo "Merging $filename"

	lipo -create "$armv7_file" "$arm64_file" -output "$uni_file"
done
