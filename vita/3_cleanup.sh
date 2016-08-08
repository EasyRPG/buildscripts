#!/bin/bash

################################################################
# Cleanup library build folders and other stuff

rm -rf zlib-*/ freetype-*/ harfbuzz-*/ icu/ icu-native/ libmodplug-*/ libogg-*/ libpng-*/ libvorbis-*/ pixman-*/ mpg123-*/ libsndfile-*/ speexdsp-*/ .patches-applied
rm -rf libvita2d/ vdpm/
rm -f *.bz2 *.gz *.xz *.tgz *.pl icudt*
