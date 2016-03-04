:: Downloads boost and extracts it in the EasyRPG include dir
:: Licensed under WTFPL

set PATH=%CD%\msys\bin;%PATH%
set BOOST_NAME=boost_1_60_0

wget http://sourceforge.net/projects/boost/files/boost/1.60.0/%BOOST_NAME%.tar.bz2/download

tar -xf %BOOST_NAME%.tar.bz2 -C build/include --strip-components=1 %BOOST_NAME%/boost

del %BOOST_NAME%.tar.bz2
