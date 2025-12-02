:: Downloads the Qt6 precompiled libraries
:: These are the official ones from the Qt Project
:: Compiling Qt6 is not feasible as it takes hours

curl -LO "https://github.com/miurahr/aqtinstall/releases/download/v3.3.0/aqt.exe"

aqt install-qt -O qt windows desktop 6.10.1 win64_msvc2022_64 -m all
