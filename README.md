# [odin-raylib-web-pong](https://mr0x13f.github.io/odin-raylib-web-pong/)

An implementation of Pong written in Odin using Raylib. Running natively on desktop and compiled to WASM to run in the browser.

Based on the [odin-raylib-web](https://github.com/karl-zylinski/odin-raylib-web) project template by Karl Zylinski.

This project had the following goals:
- Test the feasability of making a graphical application for the web using WASM with minimal setup.
- See how usable Odin and Raylib are for a simple game.
- Have an easy to copy template for using my Odin build script utility `odin_builder` to target WASM.

This was achieved with a total download size of under 500kB uncompressed, of which roughly half is the WASM binary.

## Local setup

### Requirements
- **(Optional) Docker**
    - https://www.docker.com/products/docker-desktop/
    - May be used to build without needing Odin or the Emscripten SDK
- **Odin compiler**
    - https://odin-lang.org/docs/install/#official-releases
    - On Windows: Requires MSVC and Windows SDK
    - Optional if using Docker
- **(For web builds) Emscripten SDK**
    - https://emscripten.org/docs/getting_started/downloads.html#installation-instructions-using-the-emsdk-recommended
    - Be sure to add `emsdk/upstream/emscripten` to your `PATH`
    - Optional if using Docker
- **(On Windows) Git Bash**
    - `build.bat` uses Git-Bash by default on Windows to run `build.sh` under Bash
    - Git-Bash ships with Git so you should already have it, otherwise install Git
    - If you wish to use another Windows Bash, edit the line `set WIN_BASH=` in `build.bat`

### Building on Windows
On Windows, run `build.bat` followed by build arguments.
For example: `build.bat release`

The `build.bat` script searches for your local Git Bash installation and uses it to run `build.sh`.
Because of this, you can follow the rest of this setup guide, except using `build.bat` instead of `build.sh`.

### Building with Docker
Docker can be used to create builds without needing to install Odin or the Emscripten SDK.
To build with Docker, run `build.sh` with `docker` as the first argument, for example:
`./build.sh docker release`

The same applies on Windows:
`build.bat docker release`

### Desktop builds
Run `build.sh` followed by build arguments.
- For debug builds run `./build.sh debug`
- For release builds run `./build.sh release`

For other arguments, run `./build.sh help`

### Web build
1. Run `./build.sh debug web`.
2. Web game is in the `build/web_debug` folder.

> [!WARNING]
> You might not be able to open `build/web_debug/index.html` directly due to "CORS policy" javascript errors.
> You can work around that by running a small server, i.e.:
> - `npx http-server ./build/web_debug -c-1`
> - `python -m http.server --directory ./build/web_debug`
