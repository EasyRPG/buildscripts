#!/bin/bash

################################################################
# Cleanup library build folders and other stuff

rm -rf zlib-*/ freetype-*/ harfbuzz-*/ icu/ icu-native/ libmad-*/ libmodplug-*/ libogg-*/ libpng-*/ libvorbis-*/ pixman-*/ mpg123-*/ libsndfile-*/ speexdsp-*/ tremor-lowmem/ wildmidi-*/ .patches-applied
rm -rf sf2dlib/
rm -f *.bz2 *.gz *.xz *.tgz *.pl icudt*
