:: Builds the dependencies for EasyRPG Editor

call helper\prepare.cmd

:: Build 64-bit libraries
vcpkg install --triplet x64-windows-eze --recurse^
 zlib[core] expat[core] inih[cpp] nlohmann-json[core] glaze[core]

:: Other dependencies such as Kirigami are built via vcpkg.json and a custom
:: overlay in the editor repository. This makes updating them easier.
