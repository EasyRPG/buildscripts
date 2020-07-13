# EasyRPG buildscripts

The scripts used to compile needed libraries for supported platform ports
on our Jenkins CI server https://ci.easyrpg.org/view/Toolchains/

## Notes

Specific building requirements for all platforms:

 - bash
 - autotools (autoconf, automake & libtool)
 - cmake
 - git
 - curl
 - core tools like make, perl, patch & pkg-config

Recommended building requirements for Linux:

 - ccache
