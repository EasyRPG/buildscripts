@echo off
echo EasyRPG Build System - ICU4C

msbuild.exe /? >NUL 2>&1 || (
  echo ERROR: This must be run from a Visual Studio Command Prompt.
  pause
  goto :EOF
)

IF "%EASYDEV_MSVC%"=="" SET EASYDEV_MSVC=%CD%\build

copy /Y patches\icudt56l.dat projects\icu\source\data\in

set PATH=%CD%/msys/bin;%PATH%

set __tmp=%CD%\projects\icu-native\source
set ICU_CROSS_BUILD=%__tmp:\=/%

if "%Platform%"=="ARM" (
  xcopy /Y /I /E projects\icu projects\icu-native
)

pushd projects\icu\source
if "%Platform%"=="ARM" (
  set CPPFLAGS=-D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1
  sh runConfigureICU Cygwin/MSVC --with-cross-build=%ICU_CROSS_BUILD% --host=i686-pc-mingw32 --enable-debug --disable-release --enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --enable-extras=no --enable-icuio=no --with-data-packaging=static
) else (
  sh runConfigureICU --enable-debug --disable-release Cygwin/MSVC --enable-static --disable-shared --disable-tests --disable-samples --enable-extras=no --enable-icuio=no --with-data-packaging=static --prefix "$EASYDEV_MSVC/lib"
)
make clean
make

xcopy /Y /I lib\*.lib %EASYDEV_MSVC%\lib\%Platform%\Debug

del lib\*.lib
if "%Platform%"=="ARM" (
  sh runConfigureICU Cygwin/MSVC --with-cross-build=%ICU_CROSS_BUILD% --host=i686-pc-mingw32 --enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --enable-extras=no --enable-icuio=no --with-data-packaging=static
) else (
  sh runConfigureICU Cygwin/MSVC --enable-static --disable-shared --disable-tests --disable-samples --enable-extras=no --enable-icuio=no --with-data-packaging=static --prefix "$EASYDEV_MSVC/lib"
)
make clean
make

xcopy /Y /I lib\*.lib %EASYDEV_MSVC%\lib\%Platform%\Release

popd

if "%Platform%"=="ARM" (
  xcopy /Y /I winrt\*.lib %EASYDEV_MSVC%\lib\%Platform%\Debug
  xcopy /Y /I winrt\*.lib %EASYDEV_MSVC%\lib\%Platform%\Release
)
