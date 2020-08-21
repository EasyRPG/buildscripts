:: Update/Fetch vcpkg repository
IF EXIST vcpkg (
	cd vcpkg
	git reset --hard
	git pull origin
) ELSE (
	git clone https://github.com/Microsoft/vcpkg.git
	cd vcpkg
)

:: Build vcpkg
call bootstrap-vcpkg.bat

:: Copy custom portfiles (ICU static data file)
xcopy /Y /I /E ..\icu-easyrpg ports\icu-easyrpg

:: Build 32-bit libraries
:: Using [core] everywhere to prevent surprises when new default-features are
:: added to libraries.
vcpkg install --triplet x86-windows-static^
 libpng[core] expat[core] pixman[core] freetype[core] harfbuzz[core]^
 libvorbis[core] libsndfile[core] wildmidi[core] libxmp-lite[core]^
 speexdsp[core] mpg123[core] opusfile[core] fluidlite[core]^
 sdl2-image[core] sdl2-mixer[core,nativemidi]^
 icu-easyrpg[core] fmt[core]

:: Build 64-bit libraries
vcpkg install --triplet x64-windows-static^
 libpng[core] expat[core] pixman[core] freetype[core] harfbuzz[core]^
 libvorbis[core] libsndfile[core] wildmidi[core] libxmp-lite[core]^
 speexdsp[core] mpg123[core] opusfile[core] fluidlite[core]^
 sdl2-image[core] sdl2-mixer[core,nativemidi]^
 icu-easyrpg[core] fmt[core]
