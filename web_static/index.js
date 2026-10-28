if (typeof WASM_FILE === "undefined") {
    console.error("WASM_FILE not defined")
}

let odinMemoryInterface = new odin.WasmMemoryInterface();
odinMemoryInterface.setIntSize(4);
let odinImports = odin.setupDefaultImports(odinMemoryInterface);
let exports;

// The Module is used as configuration for emscripten.
var Module = {
    // This is called by emscripten when it starts up.
    instantiateWasm: (emscriptenImports, successCallback) => {
        let imports = {
            // Add custom imports here
            ...odinImports,
            ...emscriptenImports,
        }

        return WebAssembly.instantiateStreaming(fetch(WASM_FILE), imports).then((output) => {
            exports = output.instance.exports;
            odinMemoryInterface.setExports(exports);
            odinMemoryInterface.setMemory(exports.memory);
            return successCallback(output.instance);
        });
    },
    // This happens a bit after `instantiateWasm`, when everything is
    // done setting up. At that point we can run code.
    onRuntimeInitialized: () => {

        // Calls any procedure marked with @init
        exports._start();

        // See src/main_web/main_web.odin for main_start,
        // main_update and main_end.
        exports.main_start();

        function send_resize() {
            let canvas = document.getElementById('canvas');
            exports.web_window_size_changed(canvas.width, canvas.height);
        }

        window.addEventListener('resize', (event) => {
            send_resize();
        }, true);

        // This can probably be done better: Ideally we'd feed the
        // initial size to `main_start`. But there seems to be a
        // race condition. `canvas` doesn't have it's correct size yet.
        send_resize();

        // Runs the "main loop".
        function do_main_update() {
            if (!exports.main_update()) {
                exports.main_end();

                // Calls procedures marked with @fini
                exports._end();
                return;
            }
            window.requestAnimationFrame(do_main_update);
        }

        window.requestAnimationFrame(do_main_update);
    },
    canvas: (function() {
        return document.getElementById("canvas");
    })()
};
