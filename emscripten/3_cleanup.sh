#!/bin/sh

echo
echo "Cleaning up library build folders and other stuff..."

rm -rf icu/ icu-native/ libogg-*/ libpng-*/ libvorbis-*/ pixman-*/ \
	mpg123-*/ libsndfile-*/ speexdsp-*/ SDL2/ \
	expat-*/ libxmp-lite-*/ opus-*/ opusfile-*/ zlib-*/
rm -f *.gz *.xz *.bz2 *.tgz icudt* .patches-applied config.cache
rm -rf bin/ sbin/ share/

echo " -> done"
