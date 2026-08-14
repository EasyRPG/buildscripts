#!/bin/bash

# abort on error
set -e

export NXDK_DEVKIT_DIR="nxdk"
eval "$("$NXDK_DEVKIT_DIR/bin/activate" -s)"

# Verify NXDK environment
if [ -z "${NXDK_DIR}" ]; then
    echo "Error: NXDK_DIR is not set. Run 'source nxdk/bin/activate' before building." >&2
    exit 1
fi

echo $NXDK_DIR

export WORKSPACE=$PWD

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../shared/import.sh

# Number of CPUs
nproc=$(nproc)

# Use ccache?
test_ccache

# Ensure that only NXDK libs get built, since there's no target right now
export NXDK_ONLY=y 

# Compile NXDK
(cd $NXDK_DIR
	make
	make tools
)

if [ ! -f .patches-applied ]; then
	echo "Patching libraries"

	patches_common

	verbosemsg "SDL3-NXDK"
	(cd $SDL3_DIR		
		patch CMakeLists.txt < $WORKSPACE/patches/sdl3-nxdk/add_install_to_cmakelists.patch
	)

	verbosemsg "mpg123"
	(cd $MPG123_DIR
		# This fixes some trip ups in compilation, where configure doesn't think that the compiler works (it does).
		# It also bypasses a failure to determine the output file extension, and fixes a failure to detect Windows 
		# unicode filename support.
		patch configure < $WORKSPACE/patches/mpg123/patch_configure_checks.patch
		# Outputs lib in .a format, since compiler detection stuff was putting out a .lib, and use llvm-ar instead of
		# lib.exe which it wants to use for MSVC
		patch configure < $WORKSPACE/patches/mpg123/output_as_dot_a_use_llvm_ar.patch
		patch src/config.h.in < $WORKSPACE/patches/mpg123/use_stricmp_strnicmp.patch
		# Stub out various file access functions & add a couple defines to reduce file IO function count
		patch -Np1 < $WORKSPACE/patches/mpg123/stub_out_file_io.patch
	)
	verbosemsg "fluidlite"
	(cd $FLUIDLITE_DIR
		# Compiles based on C99 standard to avoid issues linking with NXDK
		patch CMakeLists.txt < $WORKSPACE/patches/fluidlite/force_c99_compilation.patch
	)

	verbosemsg "wildmidi"
	(cd $WILDMIDI_DIR
		# Sets file I/O to use C STL (file I/O is unused by EasyRPG)
		# Also shims atof which was compiling as _atof & thus not finding it in NXDK
		patch src/file_io.c < $WORKSPACE/patches/wildmidi/use_generic_io_and_atof_shim.patch

	)

	verbosemsg "speexdsp"
	(cd $SPEEXDSP_DIR
		# Same old autoconf issues
		patch configure < $WORKSPACE/patches/speexdsp/avoid_autoconf_issues.patch
	)

	verbosemsg "expat"
	(cd $EXPAT_DIR
		# Prevent underscores being expected on function names; can't do via CMakeLists logic easily
		patch lib/expat_external.h < $WORKSPACE/patches/expat/avoid_export_underscores.patch
		# This doesn't seem to have any downstream effects in this configuration
		patch lib/winconfig.h < $WORKSPACE/patches/expat/ignore_memory_dot_h.patch
		# Remove get PID since Xbox has no meaningful PID
		patch lib/xmlparse.c < $WORKSPACE/patches/expat/no_get_pid.patch
		# Skip errno since not found
		patch lib/xmlparse.c < $WORKSPACE/patches/expat/no_errno.patch
	)

	verbosemsg "libogg"
	(cd $LIBOGG_DIR
		patch configure < $WORKSPACE/patches/libogg/avoid_autoconf_issues.patch
		# This couldn't be done via autoconf
		patch src/Makefile.am < $WORKSPACE/patches/libogg/skip_tests.patch
	)

	verbosemsg "libvorbis"
	(cd $LIBVORBIS_DIR
		patch configure < $WORKSPACE/patches/libvorbis/avoid_autoconf_issues.patch
		# nuclear option, could possibly be skipped more elegantly
		patch lib/Makefile.in < $WORKSPACE/patches/libvorbis/skip_tests.patch
	)

	verbosemsg "opus"
	(cd $OPUS_DIR
		patch celt/arch.h < $WORKSPACE/patches/opus/skip_abort_behavior.patch
		patch celt/ecintrin.h < $WORKSPACE/patches/opus/skip_intrinsics.patch
	)

	verbosemsg "opusfile"
	(cd $OPUSFILE_DIR
		patch configure < $WORKSPACE/patches/opusfile/avoid_autoconf_issues.patch
		patch src/stream.c < $WORKSPACE/patches/opusfile/no_win32_io.patch
	)

	verbosemsg "libsndfile"
	(cd $LIBSNDFILE_DIR
		# This also changes a flag to skip windows version file
		patch configure < $WORKSPACE/patches/libsndfile/avoid_autoconf_issues.patch
		patch src/sfconfig.h < $WORKSPACE/patches/libsndfile/update_defines.patch
		patch src/common.c < $WORKSPACE/patches/libsndfile/skip_logging.patch
		patch -Np1 < $WORKSPACE/patches/libsndfile/skip_file_io.patch
	)

	verbosemsg "libxmp-lite"
	(cd $LIBXMP_LITE_DIR
		# Fixes some NXDK defs
		patch CMakeLists.txt < $WORKSPACE/patches/libxmp-lite/use_c99.patch
		# The define for LIBXMP_STATIC wasn't making it into the headers
		patch include/libxmp-lite/xmp.h < $WORKSPACE/patches/libxmp-lite/force_libxmp_static_define.patch
	)

	verbosemsg "lhasa"
	(cd $LHASA_DIR
		patch configure < $WORKSPACE/patches/lhasa/avoid_autoconf_issues.patch
		patch lib/lha_arch_win32.c <  $WORKSPACE/patches/lhasa/stub_lha_arch_set_binary.patch
	)

	# No Harfbuzz right now, too heavy.  Builds though
	# verbosemsg "harfbuzz"
	# (cd $HARFBUZZ_DIR
	# 	patch -Np1 < $WORKSPACE/patches/harfbuzz/ignore_glib.patch
	# 	patch src/hb-blob.cc < $WORKSPACE/patches/harfbuzz/no_win32_io.patch
	# )

	(cd $ZLIB_DIR
		patch -Np1 < $WORKSPACE/patches/zlib/skip_io_stuff.patch
	)

	#FIX ICU
	verbosemsg "icu"
	(cd $ICU_DIR
		# Bypasses compiler checks which don't work (why?), also sets host fragment to
		# icu_cv_host_frag=mh-mingw instead of icu_cv_host_frag=mh-msys-msvc to avoid 
		# unwanted preprocessor directives
		patch source/configure < $WORKSPACE/patches/icu/patch_configure_checks.patch
		# Prevent using Windows API for stuff not provided by NXDK.  Most of this
		# depends on registry values, and should not be used by EasyRPG anyway.
		patch source/config/pkgdataMakefile.in < $WORKSPACE/patches/icu/data_no_pie.patch
		patch source/common/normalizer2.cpp < $WORKSPACE/patches/icu/normalizer_static_cast.patch
		patch source/common/ustrenum.cpp < $WORKSPACE/patches/icu/avoid_rti_str_ptr_cmp.patch
		patch -Np1 < $WORKSPACE/patches/icu/ignore_windows_locale.patch
		patch -Np1 < $WORKSPACE/patches/icu/ignore_windows_datetime.patch
		patch -Np1 < $WORKSPACE/patches/icu/ignore_timezone.patch
		patch -Np1 < $WORKSPACE/patches/icu/ignore_windows_number_formats.patch
	)

	touch .patches-applied
fi

export XBE_TITLE="EasyRPG Player" #TODO: Where to put this.  Probably not here


cd $WORKSPACE

echo "Preparing toolchain"

export PLATFORM_PREFIX=$WORKSPACE

function set_build_flags {
	export CMAKE_SYSTEM_NAME="Generic"
	export CMAKE_SYSTEM_PROCESSOR="x86"
	export CMAKE_SYSTEM_LIBRARY_PATH="${NXDK_DIR}/lib"
	export CMAKE_SYSTEM_INCLUDE_PATH="${NXDK_DIR}/include"
	export MAKEFLAGS="-j${nproc:-2}"
	
	export TARGET_HOST="i386-pc-windows-msvc"

	# Include headers that provide some Win32 types not provided by NXDK
	export CPPFLAGS="$CPPFLAGS -I$WORKSPACE/compat_headers -I$WORKSPACE/include"

	# TRY_COMPILE_TARGET_TYPE_STATIC prevents compilation from choking on wanting an EXE
	export CMAKE_EXTRA_ARGS="$CMAKE_EXTRA_ARGS -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY -DCMAKE_SYSTEM_PROCESSOR=x86"

	eval "$(
		make -f scripts/dump_nxdk_env.mk print | sed 's/^/export /'
	)"
	export CC=nxdk-cc
	export CXX=nxdk-cxx
	export LD=nxdk-link
	export AS=nxdk-as
	export LINK=nxdk-link


	make_meson_cross xbox > meson-cross.txt
}

install_lib_icu_native 

set_build_flags


eval "$(
    make -f scripts/dump_sdl3_env.mk SDL3_DIR="$SDL3_DIR" print | sed 's/^/export /'
)"

echo "FLAGS:"
echo $SDL3_FLAGS # now how to use these

####################LITE BUILD#######################################

install_lib_cmake $ZLIB_DIR $ZLIB_ARGS

install_lib_cmake $LIBPNG_DIR $LIBPNG_ARGS

# Flags disable compilation of tests & INI Reader, both of which cause issues with missing Win32 headers in NXDK, and this avoids patching
install_lib_meson $INIH_DIR $INIH_ARGS -Dtests=false -Dwith_INIReader=false

install_lib_cmake $FMT_DIR $FMT_ARGS -DCMAKE_CXX_FLAGS=-DFMT_USE_WRITE_CONSOLE=1 -DFMT_OS=0

install_lib_cmake $NLOHMANNJSON_DIR $NLOHMANNJSON_ARGS

install_lib_cmake $EXPAT_DIR $EXPAT_ARGS -DXML_STATIC=ON

install_lib $SPEEXDSP_DIR $SPEEXDSP_ARGS --host=i686-pc-mingw32

install_lib_cmake $FLUIDLITE_DIR $FLUIDLITE_ARGS

install_lib "$MPG123_DIR" $MPG123_ARGS --host=i686-pc-mingw32 --disable-id3v2 --with-cpu=sse --disable-largefile ac_cv_func_strerror=yes ac_cv_sizeof_off_t=4

install_lib_cmake $SDL3_DIR $SDL3_ARGS -DNXDK_DIR=$NXDK_DIR

install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=ON

install_lib_meson $PIXMAN_DIR $PIXMAN_ARGS -Dmmx=disabled -Dsse2=disabled -Dssse3=disabled

#####################HEAVY BUILD################################################

install_lib $LIBOGG_DIR $LIBOGG_ARGS --host=i686-pc-mingw32

install_lib $LIBVORBIS_DIR $LIBVORBIS_ARGS --host=i686-pc-mingw32

install_lib_cmake $WILDMIDI_DIR $WILDMIDI_ARGS

install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=ON

# Harfbuzz is too heavy memory wise to use at all, probably
#install_lib_meson $HARFBUZZ_DIR $HARFBUZZ_ARGS  -Dgobject=disabled

# No Harfbuzz for now
# install_lib_cmake $FREETYPE_DIR $FREETYPE_ARGS -DFT_DISABLE_HARFBUZZ=OFF

install_lib $LHASA_DIR $LHASA_ARGS --host=i686-pc-mingw32

install_lib_cmake $LIBXMP_LITE_DIR $LIBXMP_LITE_ARGS

install_lib_cmake $OPUS_DIR $OPUS_ARGS

install_lib $OPUSFILE_DIR $OPUSFILE_ARGS --host=i686-pc-mingw32

install_lib $LIBSNDFILE_DIR $LIBSNDFILE_ARGS --host=i686-pc-mingw32 --disable-win-version-resource ac_cv_func_floor=yes ac_cv_search_floor=yes use_windows_api=0

# Set these flags only for ICU (or figure out how to do it with $ICU_ARGS)
export ac_cv_c_bigendian=no
export ac_cv_var_tzname=no
export CPPFLAGS="$CPPFLAGS \
  -DU_STATIC_IMPLEMENTATION \
  -DU_PLATFORM_HAS_WIN32_API=0 \
  -DU_PLATFORM_USES_ONLY_WIN32_API=0 \
  -DU_PLATFORM_IMPLEMENTS_POSIX=0 \
  -DUCONFIG_NO_FILE_IO=1 \
  -DU_WCHAR_IS_UTF16=1 \
  -DU_HAVE_CHAR16_T=0 \
  -DU_HAVE_NL_LANGINFO_CODESET=0 \
  -DU_HAVE_TIMEZONE=0 \
  -DU_HAVE_TZSET=0 \
  -DU_HAVE_TZNAME=0 \
  -DU_HAVE_NL_LANGINFO_CODESET=0"
  
export PKGDATA_OPTS="-w -O $PWD/icu-cross/config/pkgdata.inc"
export CXXFLAGS="$CXXFLAGS -Wno-microsoft-include -std=c++17"

install_lib_icu_cross

