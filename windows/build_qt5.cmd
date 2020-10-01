:: Builds the dependencies for EasyRPG Editor Qt

call helper\prepare.cmd

:: Depend on icu-easyrpg
:: FIXME: Delete this when vcpkg implements "Provides:"
powershell -Command "(Get-Content ports\qt5-base\CONTROL) -replace 'icu', 'icu-easyrpg' | Out-File -encoding ASCII 'ports\qt5-base\CONTROL'"

:: Build 64-bit libraries
vcpkg install --triplet x64-windows-static --recurse^
 expat[core]^
 qt5[core,multimedia,svg,declarative,extras]
