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

:: Revert fmtlib to the previous version because fmt::styled does not compile
:: Remove this when the next fmtlib version is released
git restore -s 50ca16008cebab427e90a98f8ffc34208b215dba ports/fmt

:: Optimize the debug libraries
copy ..\helper\windows.cmake scripts\toolchains\windows.cmake

:: add custom editor triplet
copy ..\helper\x64-windows-static-easyrpgeditor.cmake triplets\x64-windows-static-easyrpgeditor.cmake

:: Copy custom portfiles
:: ICU static data file
xcopy /Y /I /E ..\icu-easyrpg ports\icu-easyrpg
:: fluidsynth without glib dependency
xcopy /Y /I /E ..\fluidsynth-easyrpg ports\fluidsynth-easyrpg
:: lhasa (delete when upstream port accepted)
xcopy /Y /I /E ..\lhasa-easyrpg ports\lhasa-easyrpg
