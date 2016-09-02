#!/bin/sh

echo
echo "Cleaning up library build folders and other stuff..."

rm -rf zlib-*/ freetype-*/ harfbuzz-*/ icu/ icu-native/ libpng-*/ expat-*/ pixman-*/ mpg123-*/ \
	libsndfile-*/ libxmp-lite-*/ speexdsp-*/ wildmidi-*/ libiconv-*/ sdl-wii/ tremor-lowmem/
rm -f *.bz2 *.gz *.xz *.tgz *.pl icudt* .patches-applied
rm -rf bin/ share/

echo " -> done"
