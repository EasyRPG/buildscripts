#!/bin/sh

echo
echo "Cleaning up library build folders and other stuff..."

rm -rf freetype-*/ harfbuzz-*/ icu/ icu-native/ libogg-*/ libpng-*/ libvorbis-*/ pixman-*/ \
	mpg123-*/ libsndfile-*/ speexdsp-*/ SDL2-*/ expat-*/ libxmp-lite-*/ opus-*/ opusfile-*/ \
	wildmidi-*/
rm -f *.zip *.bz2 *.gz *.xz *.tgz *.bin icudt* .patches-applied
rm -rf bin/ share/

echo " -> done"
