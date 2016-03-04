#!/bin/bash

# Supported os : "darwin" or "linux"
os=`uname`
darwin="Darwin"
linux="Linux"

if [ $os = $darwin ] ; then
	echo "Darwin detected"
	brew install hg
	brew install autoconf
fi

export WORKSPACE=$PWD

#Compile toolchain

#Android SDK : "android-sdk" folder
#Linux
if [ $os = $linux ] ; then
	rm -f android-sdk_r24.4.1-linux.tgz
	wget http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz
	tar xf android-sdk_r24.4.1-linux.tgz
	rm android-sdk_r24.4.1-linux.tgz
	mv android-sdk-linux android-sdk
#Mac
elif [ $os = $darwin ] ; then
	rm -f android-sdk_r24.4.1-macosx.zip
	wget http://dl.google.com/android/android-sdk_r24.4.1-macosx.zip
	tar xf android-sdk_r24.4.1-macosx.zip
	rm android-sdk_r24.4.1-macosx.zip
	mv android-sdk-macosx android-sdk
fi

PATH=$PATH:$WORKSPACE/android-sdk/tools

# Install SDK12 and Platform-tools
num=$(android list sdk --all | grep "Android SDK Build-tools, revision 23.0.2" | head -n1 | awk '{gsub(/[^0-9]/,"", $1);print $1}')
echo "y" | android update sdk -u -a -t $num

num=$(android list sdk --all | grep "Android SDK Platform-tools" | head -n1 | awk '{gsub(/[^0-9]/,"", $1);print $1}')
echo "y" | android update sdk -u -a -t $num

num=$(android list sdk --all | grep "SDK Platform Android 3.1, API 12" | head -n1 | awk '{gsub(/[^0-9]/,"", $1);print $1}')
echo "y" | android update sdk -u -a -t $num


#Android NDK : "android-ndk-r10e" folder
#Linux
if [ $os = $linux ] ; then
	rm -f android-ndk-r10e-linux-x86_64.bin
	wget http://dl.google.com/android/ndk/android-ndk-r10e-linux-x86_64.bin
	chmod u+x android-ndk-r10e-linux-x86_64.bin
	./android-ndk-r10e-linux-x86_64.bin
	rm android-ndk-r10e-linux-x86_64.bin
#Mac
elif [ $os = $darwin ] ; then
	rm -f android-ndk-r10e-darwin-x86_64.bin
	wget http://dl.google.com/android/ndk/android-ndk-r10e-darwin-x86_64.bin
	chmod u+x android-ndk-r10e-darwin-x86_64.bin
	./android-ndk-r10e-darwin-x86_64.bin
	rm android-ndk-r10e-darwin-x86_64.bin
fi

# Install boost header
rm -f boost_1_60_0.tar.bz2
wget http://sourceforge.net/projects/boost/files/boost/1.60.0/boost_1_60_0.tar.bz2
tar xf boost_1_60_0.tar.bz2
rm boost_1_60_0.tar.bz2

# Install libpng
rm -f libpng-1.6.21.tar.xz
wget http://prdownloads.sourceforge.net/libpng/libpng-1.6.21.tar.xz
tar xf libpng-1.6.21.tar.xz
rm libpng-1.6.21.tar.xz

# Install freetype
rm -f freetype-2.6.3.tar.bz2
wget http://download.savannah.gnu.org/releases/freetype/freetype-2.6.3.tar.bz2
tar xf freetype-2.6.3.tar.bz2
rm freetype-2.6.3.tar.bz2

# Install harfbuzz
rm -f harfbuzz-1.2.3.tar.bz2
wget http://www.freedesktop.org/software/harfbuzz/release/harfbuzz-1.2.3.tar.bz2
tar xf harfbuzz-1.2.3.tar.bz2
rm harfbuzz-1.2.3.tar.bz2

# Install pixman
rm -f pixman-0.34.0.tar.gz
wget http://cairographics.org/releases/pixman-0.34.0.tar.gz
tar xf pixman-0.34.0.tar.gz
rm pixman-0.34.0.tar.gz

# Install libogg
rm -f libogg-1.3.2.tar.xz
wget http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.xz
tar xf libogg-1.3.2.tar.xz
rm libogg-1.3.2.tar.xz

# Install libvorbis
rm -f libvorbis-1.3.5.tar.xz
wget http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.5.tar.xz
tar xf libvorbis-1.3.5.tar.xz
rm libvorbis-1.3.5.tar.xz

# Install libmad
rm -f libmad-0.15.1b.tar.gz
wget ftp://ftp.mars.org/pub/mpeg/libmad-0.15.1b.tar.gz
tar xf libmad-0.15.1b.tar.gz
rm libmad-0.15.1b.tar.gz

# Install libmodplug
rm -f libmodplug-0.8.8.5.tar.gz
wget http://sourceforge.net/projects/modplug-xmms/files/libmodplug/0.8.8.5/libmodplug-0.8.8.5.tar.gz
tar xf libmodplug-0.8.8.5.tar.gz
rm libmodplug-0.8.8.5.tar.gz

# Install SDL2
hg clone http://hg.libsdl.org/SDL

# Install SDL2_mixer
hg clone http://hg.libsdl.org/SDL_mixer

# Install ICU
rm -f icu4c-56_1-src.tgz
wget http://download.icu-project.org/files/icu4c/56.1/icu4c-56_1-src.tgz
tar xf icu4c-56_1-src.tgz
rm icu4c-56_1-src.tgz

# Install icudata
rm -f icudata.tar.xz
wget https://easy-rpg.org/jenkins/job/icudata/lastSuccessfulBuild/artifact/icu/source/data/out/icudata.tar.xz
tar xf icudata.tar.xz
rm icudata.tar.xz
