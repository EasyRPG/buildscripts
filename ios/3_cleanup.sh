#!/bin/sh

echo
echo "Cleaning up library build folders and other stuff..."

rm -rf zlib-*/ freetype-*/ harfbuzz-*/ icu/ icu-native/ libpng-*/ expat-*/ pixman-*/ mpg123-*/ \
	libsndfile-*/ libxmp-lite-*/ speexdsp-*/ wildmidi-*/ libogg-*/ libvorbis-*/ \
	SDL2-*/
rm -f *.bz2 *.gz *.xz *.tgz icudt* .patches-applied
rm -rf bin/ share/ sbin/

echo " -> done"
