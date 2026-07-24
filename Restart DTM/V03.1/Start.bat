@echo off
@echo Running config batch

::menu_action
::1 - for restart
::2 - verify restart
set menu_action=%1

::Control_Windows
::time (in hours) to control the last restart
set Control_Window=%2

::Restart_Time_Out
::Timeout in minutes
set Restart_Time_Out=%3

::Maximum Postpone allowed
::Timeout in minutes
set restartMaxPostpone=%4

::restartDescriptions
::Text do display on restart popup
set restartDescriptions=%5

::restart_Action
::"r"-restart; "l"-logoff
set restart_Action=%6

::Abort_Action
::"y" - abort "n" - no abort
set Abort_Action=%7


set source="%~dp0"
set sourceWithoutQuotes=%source:"=%

for /f %%i in ('Powershell.exe $pshome') do set PowershellHome=%%i

:: Make sure we are running x64 PS on 64 bit OS. If not then start a new x64 process of powershell
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OS=32BIT || set OS=64BIT

if %OS%==64BIT (
if exist %WINDIR%\sysnative\reg.exe (
set PowershellHome=%PowershellHome:syswow64=sysnative%
) 
)

::if exist %PowershellHome%\powershell.exe.config ( 
::  Copy /Y %PowershellHome%\powershell.exe.config %source%\powershell.exe.config.bak
::  Copy /Y %source%\powershell.exe.config %PowershellHome%\powershell.exe.config
::) else (
::  Copy /Y %source%\powershell.exe.config  %PowershellHome%\powershell.exe.config
::)

set powershellCommand="&{&'%sourceWithoutQuotes%Restart.ps1' %menu_action% '%Control_Window%' %Restart_Time_Out% %restartMaxPostpone% %restartDescriptions% %restart_Action% %Abort_Action%"; exit $LASTEXITCODE}
set psexecPath="%sourceWithoutQuotes%Psexec.exe"

::%psexecPath% -accepteula -si %PowershellHome%\powershell.exe -ExecutionPolicy Bypass -windowstyle hidden -noexit -Command %powershellCommand%
::%psexecPath% -accepteula -si %PowershellHome%\powershell.exe -ExecutionPolicy Bypass -windowstyle hidden -Command %powershellCommand%
%PowershellHome%\powershell.exe -ExecutionPolicy Bypass -Command %powershellCommand%

@echo %ERRORLEVEL%
set exitCode=%ERRORLEVEL%

:: restore the powershell.exe.config to what was before if there was one, or else remove it
::if exist %source%\powershell.exe.config.bak (
::   Copy %source%\powershell.exe.config.bak %PowershellHome%\powershell.exe.config
 ::  Del /F /Q %source%\powershell.exe.config.bak
::) else (
::   Del /F /Q   %PowershellHome%\powershell.exe.config
::)

set powershellCommand=""
set sourceWithoutQuotes=""
set source=""
set PowershellHome=""
exit /b %exitCode%