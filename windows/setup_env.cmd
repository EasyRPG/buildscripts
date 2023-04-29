@echo off

cd ..

echo Press enter to set the EasyRPG development environment to
echo %CD%

pause

setx EASYRPG_BUILDSCRIPTS "%CD%"

echo Done. Log out so that the environment changes take effect.

pause

