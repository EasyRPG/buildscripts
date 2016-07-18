#!/bin/bash

################################################################
# Cleanup library build folders and other stuff

rm -rf zlib-*/ freetype-*/ harfbuzz-*/ icu/ icu-native/ libmad-*/ libmodplug-*/ libogg-*/ libpng-*/ libvorbis-*/ pixman-*/ mpg123-*/ libsndfile-*/ speexdsp-*/ sdl-wii/ tremor-lowmem/ .patches-applied
rm -rf ctrulib/ sf2dlib/ lpp-3ds_libraries/
rm -f *.bz2 *.gz *.xz *.tgz *.pl
