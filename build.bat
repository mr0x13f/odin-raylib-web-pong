: # ---------- USAGE -------------------------------------
: # build.bat debug
: # build.bat release
: # build.bat web
: # ------------------------------------------------------
: # For web builds, set the EMSCRIPTEN_SDK_DIR variable further down
: # ------------------------------------------------------
: # On Linux/macOS, invoke as: $ bash build.bat
: # ------------------------------------------------------
: # This script is a polyglottal Batch/Bash script.
: # Under Windows it will find Git-Bash and re-run itself under Bash.
: # On Linux/macOS/Git-Bash it will skip the Windows section.
: # ------------------------------------------------------

echo \" <<'BATCH' >/dev/null ">NUL "\" \`""
:: ------------------------------------------------------
:: Windows Batch section, skipped under Bash
:: ------------------------------------------------------
@ECHO OFF

:: Put your preferred Windows Bash here
set WIN_BASH=

:: Try finding Git Bash
if defined WIN_BASH goto run
for /f "delims=" %%i in ('where git.exe 2^>nul') do set "GIT_EXE=%%i"
set "WIN_BASH=%GIT_EXE:\cmd\git.exe=\bin\bash.exe%"
if /I "%WIN_BASH%"=="%GIT_EXE%" (set "error=1") else if not exist "%WIN_BASH%" (set "error=1")
if defined error (echo [ERROR] No Bash path specified and could not find Git Bash. & exit /b 1)

:: Run this same script with Bash
:run
"%WIN_BASH%" "%~f0" %*
exit
BATCH

# ------------------------------------------------------
# From now on, this script will run under Bash
# ------------------------------------------------------

# Point this to where you installed the Emscripten SDK
EMSCRIPTEN_SDK_DIR=.

# Unpack Arguments
for arg in "$@"; do declare $arg='1'; done

# Build mode
if [ -n "${debug+x}"   ]; then build_mode=debug;   fi
if [ -n "${release+x}" ]; then build_mode=release; fi
if [ -n "${web+x}"     ]; then build_mode=web;     fi

mode_count=$(( ${debug:-0} + ${release:-0} + ${web:-0} ))
if [[ $mode_count -eq 0 ]]; then { echo "[ERROR] No build mode specified"; exit 1; } fi
if [[ $mode_count -gt 1 ]]; then { echo "[ERROR] Too many build modes specified"; exit 1; } fi

# Make sure we can find Emscripten SDK for web builds
if [ "$build_mode" = "web" ] && [ ! -e "emcc" ] && [ ! -e "$EMSCRIPTEN_SDK_DIR/emsdk_env.sh" ]; then
    echo "[ERROR] Can't find Emscripten SDK, make sure EMSCRIPTEN_SDK_DIR is set correctly"; exit 1
fi

# Platform
case "$(uname -s)" in
    Linux)                platform="linux";   exe_ext="" ;;
    Darwin)               platform="macos";   exe_ext="" ;;
    MINGW*|MSYS*|CYGWIN*) platform="windows"; exe_ext=".exe" ;;
    *) platform="UNKNOWN PLATFORM"; exe_ext="" ;;
esac

# Prepare
build_name="$(echo "$platform $build_mode" | awk '{printf toupper(substr($1,1,1)) substr($1,2) " " toupper(substr($2,1,1)) substr($2,2)}')"
echo "[$build_name build]"
out_dir="build/$build_mode"
mkdir -p "$out_dir"

# Odin compile
odin_flags="-vet -strict-style"

if [ $build_mode = "debug" ]; then
    odin_main=src/main_desktop
    odin_out=$out_dir/game_${platform}_${build_mode}${exe_ext}
    odin_flags="$odin_flags -o:minimal -debug"
    if [ $platform = "windows" ]; then odin_flags="$odin_flags -linker:radlink"; fi

elif [ $build_mode = "release" ]; then
    odin_main=src/main_desktop
    odin_out=$out_dir/game_${platform}${exe_ext}
    odin_flags="$odin_flags -o:speed -disable-assert"

elif [ $build_mode = "web" ]; then
    odin_main=src/main_web
    odin_out=$out_dir/game.wasm.o
    odin_flags="$odin_flags -o:speed -disable-assert -target:js_wasm32 -build-mode:obj -define:RAYLIB_WASM_LIB=env.o -define:RAYGUI_WASM_LIB=env.o"
fi

echo Compiling Odin
odin build "$odin_main" ${odin_flags[@]} -out="$odin_out" || exit 1

# Emscripten
if [[ $build_mode == "web" ]]; then
    echo "Compiling WASM..."
    export EMSDK_QUIET=1
    source "$EMSCRIPTEN_SDK_DIR/emsdk_env.sh"
    cmd "$EMSCRIPTEN_SDK_DIR/emsdk_env.bat"

    ODIN_PATH=$(odin root)
    html_template="$odin_main/index_template.html"
    emcc_out="$out_dir/index.html"
    emcc_files=("$odin_out" "$ODIN_PATH/vendor/raylib/wasm/libraylib.a" "$ODIN_PATH/vendor/raylib/wasm/libraygui.a")
    emcc_flags=(-sUSE_GLFW=3 -sWASM_BIGINT -sWARN_ON_UNDEFINED_SYMBOLS=0 -sASSERTIONS --shell-file "$html_template" --preload-file assets)

    cp "$ODIN_PATH/core/sys/wasm/js/odin.js" "$out_dir/"
    emcc -o "$emcc_out" "${emcc_files[@]}" "${emcc_flags[@]}" || exit 1

    rm -f "$odin_out"
fi

# Copy assets for release build
if [[ $build_mode == "release" ]]; then
    echo "Copying assets..."
    mkdir -p "$out_dir/assets"
    cp -r assets/* "$out_dir/assets/"
fi

echo "$build_name build created in $out_dir"
