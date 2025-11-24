:: Builds the dependencies for EasyRPG Editor Qt

:: call helper\prepare.cmd

curl -LO "https://github.com/miurahr/aqtinstall/releases/download/v3.3.0/aqt.exe"

aqt install-qt -O qt windows desktop 6.10.1 win64_msvc2022_64 -m all
