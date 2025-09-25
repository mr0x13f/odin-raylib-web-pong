#!/bin/bash -eu

# ---------- USAGE ----------
# build.sh debug
# build.sh release
# build.sh web
# ---------------------------

# Point this to where you installed the Emscripten SDK
# EMSCRIPTEN_SDK_DIR="/path/to/your/emsdk"
EMSCRIPTEN_SDK_DIR=PATH/TO/YOUR/emsdk

# Unpack Arguments
for arg in "$@"; do declare $arg='1'; done

# Build mode
if [ -v debug   ]; then build_mode=debug;   fi
if [ -v release ]; then build_mode=release; fi
if [ -v web     ]; then build_mode=web;     fi

mode_count=$(( ${debug:-0} + ${release:-0} + ${web:-0} ))
if [[ $mode_count -eq 0 ]]; then { echo "[ERROR] No build mode specified"; exit 1; } fi
if [[ $mode_count -gt 1 ]]; then { echo "[ERROR] Too many build modes specified"; exit 1; } fi

echo "[${build_mode^} build]"
out_dir="build/$build_mode"
mkdir -p "$out_dir"

# Odin compile
odin_main=src/main_desktop
if [ $build_mode = "web" ]; then odin_main=src/main_web; fi

odin_out=$out_dir/game_$build_mode
if [ $build_mode = "web" ]; then odin_out=$out_dir/game.wasm.o; fi

odin_flags="-vet -strict-style"
if [ $build_mode = "debug"   ]; then odin_flags="$odin_flags -o:minimal -debug -linker:radlink"; fi
if [ $build_mode = "release" ]; then odin_flags="$odin_flags -o:speed -disable-assert"; fi
if [ $build_mode = "web"     ]; then odin_flags="$odin_flags -o:speed -disable-assert -target:js_wasm32 -build-mode:obj -define:RAYLIB_WASM_LIB=env.o -define:RAYGUI_WASM_LIB=env.o"; fi

echo Compiling Odin...
odin build $odin_main -out="$odin_out"

# Emscripten
if [[ $build_mode == "web" ]]; then
    echo "Compiling WASM..."
    export EMSDK_QUIET=1
    source "$EMSCRIPTEN_SDK_DIR/emsdk_env.sh"

    ODIN_PATH=$(odin root)
    html_template="$odin_main/index_template.html"
    emcc_out="$out_dir/index.html"
    emcc_files=("$odin_out" "$ODIN_PATH/vendor/raylib/wasm/libraylib.a" "$ODIN_PATH/vendor/raylib/wasm/libraygui.a")
    emcc_flags=(-sUSE_GLFW=3 -sWASM_BIGINT -sWARN_ON_UNDEFINED_SYMBOLS=0 -sASSERTIONS --shell-file "$html_template" --preload-file assets)

    cp "$ODIN_PATH/core/sys/wasm/js/odin.js" "$out_dir/"
    emcc -o "$emcc_out" "${emcc_files[@]}" "${emcc_flags[@]}"

    rm -f "$odin_out"
fi

# Copy assets for release build
if [[ $build_mode == "release" ]]; then
    echo "Copying assets..."
    mkdir -p "$out_dir/assets"
    cp -r assets/* "$out_dir/assets/"
fi

echo "${build_mode^} build created in $out_dir"
