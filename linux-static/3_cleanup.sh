#!/bin/sh

echo
echo "Cleaning up library build folders and other stuff..."

rm -rf freetype-*/ harfbuzz-*/ icu/ libogg-*/ libpng-*/ libvorbis-*/ pixman-*/ \
	mpg123-*/ libsndfile-*/ speexdsp-*/ SDL2-*/ SDL2_mixer-*/ SDL2_image-*/ \
	expat-*/ libxmp-lite-*/ opus-*/ opusfile-*/ wildmidi-*/ zlib-*/
rm -f *.zip *.bz2 *.gz *.xz *.tgz icudt* .patches-applied config.cache
rm -rf bin/ sbin/ share/

echo " -> done"
