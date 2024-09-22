:: Builds the dependencies for EasyRPG Tools

call helper\prepare.cmd

:: Build 32-bit libraries
:: Using [core] everywhere to prevent surprises when new default-features are
:: added to libraries.
vcpkg install --triplet x86-windows-static --recurse^
 jasper[core] libwebp[core] freeimage[core]

:: Build 64-bit libraries
vcpkg install --triplet x64-windows-static --recurse^
 jasper[core] libwebp[core] freeimage[core]
