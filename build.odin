#+feature using-stmt
package build

import "core:os"
import "core:strings"
import "core:fmt"
import "lib/odin_builder/builder"

/*
    ===== Usage =====
        odin run . -- [..args]

    ===== Examples =====
    Debug build:
        odin run . -- debug
    Release build:
        odin run . -- release
    Watch-for-changes debug build without vetting:
        odin run . -- debug watch novet
*/

args: struct {
    debug:   bool "Debug build mode",
    release: bool "Release build mode",
    web:     bool "Web target",
    run:     bool "Run after building",
    clean:   bool "Delete old build files",
    watch:   bool "Watch for changes",
    vet:     bool "Extra vetting",
    novet:   bool "No vetting",
    asan:    bool "Use address sanitizer",
    help:    bool "Show usage",
}

// TODO: on docker/linux: implement file watch
// TODO: on docker/linux: implement delete junk bin file

main :: proc() {
    using args, builder
    read_args(&args)

    if len(cli_args) == 0 {
        print_usage(&args); exit(1) }
    if help {
        print_usage(&args); exit() }

    expect_exactly_one_of(debug, release)
    if run && watch { error("Cannot run AND watch") }
    if run && web   { error("Cannot run web build") }

    // Info
    app_name         := "pong"
    src_dir          := "src"
    lib_dir          := "lib"
    build_dir        := "build"
    assets_dir       := "assets"
    web_static_dir   := "web_static"
    desktop_main_dir := "src/main_desktop"
    desktop_main_pkg := "main_desktop"
    web_main_dir     := "src/main_web"
    web_main_pkg     := "main_web"
    wasm_file        := "pong.wasm"

    // Prepare Build
    build_config := debug ? "debug" : release ? "release" : ""
    target := web ? "web" : NATIVE_PLATFORM
    odin_target := Odin_Build_Targets.Native
    odin_build_mode := Odin_Build_Mode.Executable
    build_name := fmt.aprintf("%s %s", strings.to_pascal_case(target), strings.to_pascal_case(build_config))
    out_dir := join(build_dir, fmt.aprintf("%s_%s", target, build_config))
    odin_out := join(out_dir, app_name)
    odin_main_dir := web ? web_main_dir : desktop_main_dir
    odin_main_pkg := web ? web_main_pkg : desktop_main_pkg

    fmt.printfln("[%s build]", build_name)
    
    // Build flags
    build_options: Odin_Build_Options
    build_options.collections["src"] = src_dir
    build_options.collections["lib"] = lib_dir

    if debug {
        build_options.debug = true
        build_options.optimization = .Minimal
        if target == WINDOWS {
            build_options.subsystem = .Console
        } 
    }
    if release {
        build_options.disable_assert = true
        build_options.optimization = .Speed
        if target == WINDOWS {
            build_options.subsystem = .Windows
        }
    }

    if web {
        odin_target = .Js_Wasm32
        odin_build_mode = .Object
        build_options.define["RAYLIB_WASM_LIB"] = "env.o"
        build_options.define["RAYGUI_WASM_LIB"] = "env.o"
    }

    if asan { build_options.sanitize = .Address }

    build_options.vet_packages = { desktop_main_dir, desktop_main_pkg }
    if !novet {
        build_options.vet_cast = true
        build_options.vet_semicolon = true
        build_options.vet_shadowing = true
        build_options.vet_style = true
        build_options.vet_unused_imports = true
        build_options.vet_unused_variables = true
        build_options.vet_using_param = true
        build_options.vet_using_stmt = true
        build_options.vet_when_shadowing = true
    }
    if vet  {
        build_options.vet_unused_procedures = true
    }

    // Clean
    if clean || release {
        clear_dir(out_dir)
    }
    mkdir(out_dir)

    // Prepare web build
    emcc_input_files: []string
    emcc_flags: []string
    emcc_config_flags: []string
    emcc_out: string
    wasm_obj_path: string
    emcc_cmd: string
    if web {
        emcc_cmd = NATIVE_WINDOWS ? "emcc.bat" : "emcc"
        emcc_out = join(out_dir, fmt.aprintf("%s.js", app_name))
        wasm_obj_path = append_extension(odin_out, .Object, odin_target)
        emcc_input_files = {
            wasm_obj_path,
            join(ODIN_ROOT, "vendor/raylib/wasm/libraylib.web.a"),
            join(ODIN_ROOT, "vendor/raylib/wasm/libraygui.a")
        }
        emcc_flags = {
            "--preload-file", assets_dir,
            "-sEXPORTED_RUNTIME_METHODS=['HEAPF32']",
            "-sWASM_BIGINT",
            "-sUSE_GLFW=3",
            "-sWARN_ON_UNDEFINED_SYMBOLS=0",
        }
        if debug { emcc_config_flags = {
            "-O0",
            "-g3",
            "-sSTACK_OVERFLOW_CHECK=2",
            "-sSAFE_HEAP=2",
            "-sASSERTIONS=1",
        }}
        if release { emcc_config_flags = {
            // -O3 and -sASSERTIONS=0 together causes Emscripten to minify import/export names,
            // which breaks our JS code since we hand over named imports from odin.js and call exports by name.
            // Adding -lexports.js prevents this minification
            "-O3",
            "-sASSERTIONS=0",
            "-lexports.js",
            // --------------------------------
            "-sSTACK_OVERFLOW_CHECK=0",
            "-sSAFE_HEAP=0",
            "--closure", "1", // Javascript minification
        }}
        
        // Check that emcc is available
        call({"where", emcc_cmd}, silent = true) or_else
            error("emcc is not available in PATH. Make sure the Emscripten SDK is installed, and add it to your PATH or run $ source emsdk_env.sh")
     }

    // Compile
    for watch_dir(watch, src_dir) {
        
        fmt.printfln("Building %s...", app_name)
        out_file, success := odin_build(odin_main_dir, odin_out, odin_build_mode, odin_target, build_options)

        if web && success {
            success = call({emcc_cmd, "-o", emcc_out}, emcc_input_files, emcc_flags, emcc_config_flags)
        }
        if web && success {
            os.remove(wasm_obj_path)
            move(emcc_out, tjoin(out_dir, "emscripten.js"))
            copy(tjoin(out_dir, "odin.js"), tjoin(ODIN_ROOT, "core/sys/wasm/js/odin.js"))
            copy_dir_contents(out_dir, web_static_dir)
        }

        if success {
            fmt.printfln(FG_GREEN + "%s build created in " + FG_CYAN + "%s" + os.Path_Separator_String + RESET, build_name, out_dir)
        } else {
            fmt.printfln(FG_RED + "%s build failed" + RESET, build_name)
        }

        if success && run {
            fmt.printfln("Running...")
            fmt.println("================================================================================")
            call({out_file}, interactive = true)
        }
        
        if !success && !watch { exit(1) }
    }
}
