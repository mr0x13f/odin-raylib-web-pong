@echo off
setlocal enabledelayedexpansion

:: ---------- USAGE ----------
:: build.bat debug
:: build.bat release
:: build.bat web
:: ---------------------------

:: Point this to where you installed the Emscripten SDK
set EMSCRIPTEN_SDK_DIR=C:\PATH\TO\YOUR\emsdk

:: Unpack Arguments
for %%a in (%*) do set "%%~a=1"

:: Build mode
if "%debug%"=="1"   set "build_mode=debug"   && set "build_name=Debug"  
if "%release%"=="1" set "build_mode=release" && set "build_name=Release"
if "%web%"=="1"     set "build_mode=web"     && set "build_name=Web"    

set /a mode_count=debug + release + web
if %mode_count%==0    echo [ERROR] No build mode specified && exit /b 1
if %mode_count% gtr 1 echo [ERROR] Too many build modes specified && exit /b 1

echo [%build_name% build]
set "out_dir=build\%build_mode%"
if not exist "%out_dir%" mkdir "%out_dir%"

:: Odin compile
set "odin_main=src\main_desktop"
if "%build_mode%"=="web" set "odin_main=src\main_web"

set "odin_out=%out_dir%\game_%build_mode%.exe"
if "%build_mode%"=="web" set "odin_out=%out_dir%\game.wasm.o"

set "odin_flags=-vet -strict-style"
if "%build_mode%"=="debug"   set "odin_flags=%odin_flags% -o:minimal -debug -linker:radlink"
if "%build_mode%"=="release" set "odin_flags=%odin_flags% -o:speed -disable-assert"
if "%build_mode%"=="web"     set "odin_flags=%odin_flags% -o:speed -disable-assert -target:js_wasm32 -build-mode:obj -define:RAYLIB_WASM_LIB=env.o -define:RAYGUI_WASM_LIB=env.o"

echo Compiling Odin...
odin build %odin_main% -out:%odin_out% %odin_flags%
if %ERRORLEVEL% NEQ 0 exit /b 1

:: Emscripten
if "%build_mode%"=="web" (
    echo Compiling WASM...
    set "EMSDK_QUIET=1"
    call "!EMSCRIPTEN_SDK_DIR!\emsdk_env.bat"

    for /f "delims=" %%i in ('odin root') do set "ODIN_PATH=%%i"
    set "html_template=!odin_main!\index_template.html"
    set "emcc_out=!out_dir!\index.html"
    set emcc_files="%odin_out%" "!ODIN_PATH!\vendor\raylib\wasm\libraylib.a" "!ODIN_PATH!\vendor\raylib\wasm\libraygui.a"
    set emcc_flags=-sUSE_GLFW=3 -sWASM_BIGINT -sWARN_ON_UNDEFINED_SYMBOLS=0 -sASSERTIONS --shell-file "!html_template!" --preload-file assets

    copy "!ODIN_PATH!\core\sys\wasm\js\odin.js" "%out_dir%" >NUL
    call emcc -o "!emcc_out!" !emcc_files! !emcc_flags!
    if !ERRORLEVEL! NEQ 0 exit /b 11

    if exist "%odin_out%" del "%odin_out%" >NUL
)

:: Copy assets for release build
if "%build_mode%"=="release" (
    echo Copying assets...
    robocopy assets "%out_dir%\assets" /mir >nul
)

echo %build_name% build created in %out_dir%
