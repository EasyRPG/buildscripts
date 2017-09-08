#!/bin/sh

echo
echo "Cleaning up library build folders and other stuff..."

rm -rf freetype-*/ harfbuzz-*/ icu/ icu-native/ libogg-*/ libpng-*/ libvorbis-*/ pixman-*/ \
	mpg123-*/ libsndfile-*/ speexdsp-*/ SDL2-2.0.5/ expat-*/ libxmp-lite-*/
rm -f *.bz2 *.gz *.xz *.tgz *.bin icudt* .patches-applied
rm -rf bin/ share/

echo " -> done"
