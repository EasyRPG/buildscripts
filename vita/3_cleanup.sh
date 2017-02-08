#!/bin/bash

################################################################
# Cleanup library build folders and other stuff

rm -rf zlib-*/ freetype-*/ harfbuzz-*/ icu/ icu-native/ libogg-*/ libpng-*/ libvorbis-*/ pixman-*/ mpg123-*/ libsndfile-*/ speexdsp-*/ .patches-applied
rm -rf vdpm/ vita2dlib/ vitashaders/ vita-headers/
rm -f *.bz2 *.gz *.xz *.tgz *.pl icudt*
