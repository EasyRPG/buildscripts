@echo off
echo EasyRPG Library Build System
msbuild.exe /? >NUL 2>&1 || (
  echo ERROR: This must be run from a Visual Studio Command Prompt.
  pause
  goto :EOF
)

if [%1]==[] (
    echo ERROR: Please provide a platform toolset ^(see README^)
    goto :EOF
)

set TARGETTOOLSET=%1

echo Compiling using toolset %TARGETTOOLSET%
echo.
@echo on
msbuild easyrpg-win32-libs.sln /t:Clean;Build /p:configuration=Debug /p:PlatformToolset=%TARGETTOOLSET% /m || goto :EOF
msbuild easyrpg-win32-libs.sln /t:Clean;Build /p:configuration=Release /p:PlatformToolset=%TARGETTOOLSET% /m || goto :EOF

call build-icu.cmd
