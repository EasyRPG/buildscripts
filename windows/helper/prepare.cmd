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

