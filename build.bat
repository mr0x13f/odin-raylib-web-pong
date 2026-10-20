:: This script attempts to find a local installation of Git Bash and uses it to run build.sh.
:: To force a specific Bash executable, set the WIN_BASH variable.
:: For usage, see build.sh

@echo off

:: Put your preferred Windows Bash here
set WIN_BASH=

:: Try finding Git Bash
if defined WIN_BASH goto run
for /f "delims=" %%i in ('where git.exe 2^>nul') do set "GIT_EXE=%%i"
set "WIN_BASH=%GIT_EXE:\cmd\git.exe=\bin\bash.exe%"
if /I "%WIN_BASH%"=="%GIT_EXE%" (set "error=1") else if not exist "%WIN_BASH%" (set "error=1")
if defined error (echo [ERROR] No Bash path specified and could not find Git Bash. & exit /b 1)

:: Run build.sh under Bash
:run
"%WIN_BASH%" "%~f0\..\build.sh" %*
exit
