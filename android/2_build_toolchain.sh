export WORKSPACE=$PWD

export NDK_ROOT=$WORKSPACE/android-ndk-r10e
export SDK_ROOT=$WORKSPACE/android-sdk

# Patch cpufeatures, hangs in Android 4.0.3
patch -Np0 < cpufeatures.patch

# Setup PATH
PATH=$PATH:$NDK_ROOT:$SDK_ROOT/tools


####################################################
# Install standalone toolchain x86
export PLATFORM_PREFIX=$WORKSPACE/x86-toolchain
$NDK_ROOT/build/tools/make-standalone-toolchain.sh --platform=android-9 --ndk-dir=$NDK_ROOT --toolchain=x86-4.9 --install-dir=$PLATFORM_PREFIX --stl=gnustl

export OLD_PATH=$PATH
export PATH=$PLATFORM_PREFIX/bin:$PATH

export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/support/include"
export LDFLAGS="-L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export TARGET_HOST="i686-linux-android"

# Install boost header
cp -r boost_1_60_0/boost/ $PLATFORM_PREFIX/include/boost/

# Install libpng
cd libpng-1.6.21
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install freetype
cd freetype-2.6.3
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static --with-harfbuzz=no
make -j2
make install
cd ..

# Install pixman
cd pixman-0.34.0
sed -i.bak 's/SUBDIRS = pixman demos test/SUBDIRS = pixman/' Makefile.am
autoreconf -fi
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libogg
tar xf libogg-1.3.2.tar.xz
cd libogg-1.3.2
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libvorbis
tar xf libvorbis-1.3.5.tar.xz
cd libvorbis-1.3.5
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libmad
cd libmad-0.15.1b
patch -Np1 < ../libmad-pkg-config.diff
autoreconf -fi
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libmodplug
tar xf libmodplug-0.8.8.5.tar.gz
cd libmodplug-0.8.8.5
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install SDL2
cd SDL
mv include/SDL_config_android.h include/SDL_config.h
mkdir jni
echo "APP_STL := gnustl_static" > "jni/Application.mk"
echo "APP_ABI := armeabi armeabi-v7a x86 mips" >> "jni/Application.mk"
ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android.mk APP_PLATFORM=android-9
cp libs/x86/* $PLATFORM_PREFIX/lib/
cp include/* $PLATFORM_PREFIX/include/
cd ..

# Install SDL2_mixer
cd SDL_mixer
patch -Np1 -d timidity < ../timidity-android.patch
patch -Np0 < ../sdl-mixer-config.patch
make clean
sh autogen.sh
sh autogen.sh
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --enable-music-mp3-mad-gpl --disable-sdltest --disable-music-mod
make -j2
make install
cd ..

# Install ICU
unset CPPFLAGS
unset LDFLAGS

cp -r icu icu-native
cp icudt56l.dat icu/source/data/in/
cp icudt56l.dat icu-native/source/data/in/
cd icu-native/source
sed -i.bak 's/SMALL_BUFFER_MAX_SIZE 512/SMALL_BUFFER_MAX_SIZE 2048/' tools/toolutil/pkg_genc.h
chmod u+x configure
./configure --enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools --enable-extras=no --enable-icuio=no --with-data-packaging=static
make -j2
export ICU_CROSS_BUILD=$PWD

# Cross compile ICU
cd ../../icu/source

export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/cxx-stl/stlport/stlport -O3 -fno-short-wchar -DU_USING_ICU_NAMESPACE=0 -DU_GNUC_UTF16_STRING=0 -fno-short-enums -nostdlib"
export LDFLAGS="-lc -Wl,-rpath-link=$PLATFORM_PREFIX/lib -L$PLATFORM_PREFIX/lib/"

chmod u+x configure
make clean
./configure --with-cross-build=$ICU_CROSS_BUILD --enable-strict=no  --enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --enable-extras=no --enable-icuio=no --host=$TARGET_HOST --with-data-packaging=static --prefix=$PLATFORM_PREFIX

make -j2
make install

unset CPPFLAGS
unset LDFLAGS

################################################################
# Install standalone toolchain ARMeabi
cd $WORKSPACE

export PATH=$OLD_PATH
export PLATFORM_PREFIX=$WORKSPACE/armeabi-toolchain
$NDK_ROOT/build/tools/make-standalone-toolchain.sh --platform=android-9 --ndk-dir=$NDK_ROOT --toolchain=arm-linux-androideabi-4.9 --install-dir=$PLATFORM_PREFIX  --stl=gnustl
export PATH=$PLATFORM_PREFIX/bin:$PATH

export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/support/include -I$NDK_ROOT/sources/android/cpufeatures"
export LDFLAGS="-L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export TARGET_HOST="arm-linux-androideabi"

# Install boost header
cp -r boost_1_60_0/boost/ $PLATFORM_PREFIX/include/boost/

# Install libpng
cd libpng-1.6.21
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install freetype
cd freetype-2.6.3
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static --with-harfbuzz=no
make -j2
make install
cd ..

# Install pixman
cd pixman-0.34.0
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libogg
cd libogg-1.3.2
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libvorbis
cd libvorbis-1.3.5
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libmad
cd libmad-0.15.1b
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libmodplug
cd libmodplug-0.8.8.5
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install SDL2
cd SDL
# Was already compiled because of Android.mk voodoo
cp libs/armeabi/* $PLATFORM_PREFIX/lib/
cp include/* $PLATFORM_PREFIX/include/
cd ..

# Install SDL2_mixer
cd SDL_mixer
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --enable-music-mp3-mad-gpl --disable-sdltest --disable-music-mod
make -j2
make install
cd ..

# Cross compile ICU
cd icu/source

export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/cxx-stl/stlport/stlport -O3 -fno-short-wchar -DU_USING_ICU_NAMESPACE=0 -DU_GNUC_UTF16_STRING=0 -fno-short-enums -nostdlib"
export LDFLAGS="-lc -Wl,-rpath-link=$PLATFORM_PREFIX/lib -L$PLATFORM_PREFIX/lib/"

chmod u+x configure
make clean
./configure --with-cross-build=$ICU_CROSS_BUILD --enable-strict=no  --enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --enable-extras=no --enable-icuio=no --host=$TARGET_HOST --with-data-packaging=static --prefix=$PLATFORM_PREFIX

make -j2
make install

################################################################
# Install standalone toolchain ARMeabi-v7a
cd $WORKSPACE

# Setting up new toolchain not required, only difference is CPPFLAGS

export PLATFORM_PREFIX_ARM=$WORKSPACE/armeabi-toolchain
export PLATFORM_PREFIX=$WORKSPACE/armeabi-v7a-toolchain

export CPPFLAGS="-I$PLATFORM_PREFIX_ARM/include -I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/support/include -I$NDK_ROOT/sources/android/cpufeatures -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3"
export LDFLAGS="-L$PLATFORM_PREFIX_ARM/lib -L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export TARGET_HOST="arm-linux-androideabi"

# Install boost header
mkdir $PLATFORM_PREFIX/include
cp -r boost_1_60_0/boost/ $PLATFORM_PREFIX/include/boost/

# Install libpng
cd libpng-1.6.21
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install freetype
cd freetype-2.6.3
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static --with-harfbuzz=no
make -j2
make install
cd ..

# Install pixman
cd pixman-0.34.0
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libogg
cd libogg-1.3.2
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libvorbis
cd libvorbis-1.3.5
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libmad
cd libmad-0.15.1b
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libmodplug
cd libmodplug-0.8.8.5
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install SDL2
cd SDL
# Was already compiled because of Android.mk voodoo
cp libs/armeabi-v7a/* $PLATFORM_PREFIX/lib/
cp include/* $PLATFORM_PREFIX/include/
cd ..

# Install SDL2_mixer
cd SDL_mixer
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --enable-music-mp3-mad-gpl --disable-sdltest --disable-music-mod
make -j2
make install
cd ..

# Cross compile ICU
cd icu/source

export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/cxx-stl/stlport/stlport -O3 -fno-short-wchar -DU_USING_ICU_NAMESPACE=0 -DU_GNUC_UTF16_STRING=0 -fno-short-enums -nostdlib -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3"
export LDFLAGS="-lc -Wl,-rpath-link=$PLATFORM_PREFIX/lib -L$PLATFORM_PREFIX/lib/"

chmod u+x configure
make clean
./configure --with-cross-build=$ICU_CROSS_BUILD --enable-strict=no  --enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --enable-extras=no --enable-icuio=no --host=$TARGET_HOST --with-data-packaging=static --prefix=$PLATFORM_PREFIX

make -j2
make install

################################################################
# Install standalone toolchain MIPS
cd $WORKSPACE

export PATH=$OLD_PATH
export PLATFORM_PREFIX=$WORKSPACE/mips-toolchain
$NDK_ROOT/build/tools/make-standalone-toolchain.sh --platform=android-9 --ndk-dir=$NDK_ROOT --toolchain=mipsel-linux-android-4.9 --install-dir=$PLATFORM_PREFIX  --stl=gnustl
export PATH=$PLATFORM_PREFIX/bin:$PATH

export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/android/support/include -I$NDK_ROOT/sources/android/cpufeatures"
export LDFLAGS="-L$PLATFORM_PREFIX/lib"
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export TARGET_HOST="mipsel-linux-android"

# Install boost header
cp -r boost_1_60_0/boost/ $PLATFORM_PREFIX/include/boost/

# Install libpng
cd libpng-1.6.21
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install freetype
cd freetype-2.6.3
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static --with-harfbuzz=no
make -j2
make install
cd ..

# Install pixman
cd pixman-0.34.0
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libogg
cd libogg-1.3.2
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libvorbis
cd libvorbis-1.3.5
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libmad
cd libmad-0.15.1b
make clean
FPM="-DFPM_DEFAULT" ./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install libmodplug
cd libmodplug-0.8.8.5
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --disable-shared --enable-static
make -j2
make install
cd ..

# Install SDL2
cd SDL
# Was already compiled because of Android.mk voodoo
cp libs/mips/* $PLATFORM_PREFIX/lib/
cp include/* $PLATFORM_PREFIX/include/
cd ..

# Install SDL2_mixer
cd SDL_mixer
make clean
./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX --enable-music-mp3-mad-gpl --disable-sdltest --disable-music-mod
make -j2
make install
cd ..

# Cross compile ICU
cd icu/source

export CPPFLAGS="-I$PLATFORM_PREFIX/include -I$NDK_ROOT/sources/cxx-stl/stlport/stlport -O3 -fno-short-wchar -DU_USING_ICU_NAMESPACE=0 -DU_GNUC_UTF16_STRING=0 -fno-short-enums -nostdlib"
export LDFLAGS="-lc -Wl,-rpath-link=$PLATFORM_PREFIX/lib -L$PLATFORM_PREFIX/lib/"

chmod u+x configure
make clean
./configure --with-cross-build=$ICU_CROSS_BUILD --enable-strict=no  --enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --enable-extras=no --enable-icuio=no --host=$TARGET_HOST --with-data-packaging=static --prefix=$PLATFORM_PREFIX

make -j2
make install

cd $WORKSPACE
