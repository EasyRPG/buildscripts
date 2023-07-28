@echo off

echo This script will download precompiled development libraries for EasyRPG.
echo They are only compatible with the latest version of Visual Studio 2022.
echo.
echo When you continue an existing "vcpkg" folder will be deleted.

pause

IF EXIST vcpkg (
	echo Deleting "vcpkg". This takes a while...
	rmdir /S /Q vcpkg
)

echo Downloading...
curl -SLOR https://ci.easyrpg.org/downloads/windows/toolchain-windows.zip

echo Extracting...
mkdir vcpkg
tar -xf toolchain-windows.zip -C vcpkg --strip-components=1
del toolchain-windows.zip

echo Done :)

pause
