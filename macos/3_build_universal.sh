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

# copy files needed by CMake, doesn't matter if x64 or arm
cp -R x86_64/bin x86_64/include x86_64/lib universal

# merge the libraries with lipo
for x64_file in $(find x86_64/lib -type f -name "*.a")
do
	filename=$(basename $x64_file)
	arm_file="arm64/lib/$filename"
	uni_file="universal/lib/$filename"

	echo "Merging $filename"

	lipo -create "$x64_file" "$arm_file" -output "$uni_file"
done
