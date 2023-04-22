#!/bin/bash

set -e

git clone -b no-glib https://github.com/ghabry/fluidsynth --depth=3

pushd fluidsynth

git format-patch -2 HEAD

sed -i 's/From: Ghabry.*/From: Ghabry/' 000*.patch

cp 0001-Shim-glib.patch ../fluidsynth-no-glib.patch
cp 0002-Disable-most-features.patch ../fluidsynth-no-deps.patch

cp 0001-Shim-glib.patch ../../windows/fluidsynth-easyrpg/fluidsynth-no-glib.patch
cp 0002-Disable-most-features.patch ../../windows/fluidsynth-easyrpg/fluidsynth-no-deps.patch

popd

rm -rf fluidsynth

echo "Fluidsynth patches updated."
echo "Do not forget to manually update the vcpkg portfile"
