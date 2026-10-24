:: This script attempts to find a local installation of Git Bash and uses it to run build.sh.
:: To force a specific Bash executable, set the WIN_BASH variable.
:: For usage, see build.sh

@echo off

:: Put your preferred Windows Bash here
set WIN_BASH=

if defined WIN_BASH goto check_bash

where bash.exe >nul 2>&1
if not errorlevel 1 (
for /f "delims=" %%i in ('where bash.exe 2^>nul') do (
if not defined WIN_BASH set "WIN_BASH=%%i"
)
)
if defined WIN_BASH goto run

for /f "delims=" %%i in ('where git.exe 2^>nul') do (
if not defined WIN_BASH if exist "%%~dpi..\bin\bash.exe" (
set "WIN_BASH=%%~dpi..\bin\bash.exe"
)
if not defined WIN_BASH if exist "%%~dpi..\usr\bin\bash.exe" (
set "WIN_BASH=%%~dpi..\usr\bin\bash.exe"
)
if not defined WIN_BASH if exist "%%~dpi....\usr\bin\bash.exe" (
set "WIN_BASH=%%~dpi....\usr\bin\bash.exe"
)
if not defined WIN_BASH if exist "%%~dpi....\bin\bash.exe" (
set "WIN_BASH=%%~dpi....\bin\bash.exe"
)
)
if defined WIN_BASH goto check_bash

echo [ERROR] Could not find Bash.
echo Install Git for Windows or MSYS2, add bash.exe to PATH,
echo or set WIN_BASH to the full path of bash.exe.
exit /b 1

:check_bash
if exist "%WIN_BASH%" goto run
echo [ERROR] Bash executable not found: "%WIN_BASH%" >&2
exit /b 1

:run
"%WIN_BASH%" "%~dp0build.sh" %*
exit /b %errorlevel%
