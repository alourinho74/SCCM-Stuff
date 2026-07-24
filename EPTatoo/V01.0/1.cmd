set source="%~dp0"
set sourceWithoutQuotes=%source:"=%

REM powershell.exe -ExecutionPolicy Bypass -command .\EPTatoo.ps1
set powershellCommand="&{&'%sourceWithoutQuotes%EPTatoo.ps1' "; exit $LASTEXITCODE}

%PowershellHome%powershell.exe -ExecutionPolicy Bypass -Command %powershellCommand%
@echo %ERRORLEVEL%
set exitCode=%ERRORLEVEL%

exit /b %exitCode%
