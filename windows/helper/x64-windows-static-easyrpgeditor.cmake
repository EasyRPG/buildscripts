set(VCPKG_TARGET_ARCHITECTURE x64)
# Qt6 uses the dynamic CRT (/MD)
# The CRT must match for all linked libraries
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
# Use our downloaded Qt6 prebuild
# Compiling Qt6 manually takes hours
set(VCPKG_ENV_PASSTHROUGH Qt6_Path)
