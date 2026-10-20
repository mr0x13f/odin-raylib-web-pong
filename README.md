# [odin-raylib-web-pong](https://mr0x13f.github.io/odin-raylib-web-pong/)

An implementation of Pong written in Odin using Raylib. Running natively on desktop and compiled to WASM to run in the browser.

Based on the [odin-raylib-web](https://github.com/karl-zylinski/odin-raylib-web) project template by Karl Zylinski.

This project was meant to try out the feasability of making a graphical application for the web using WASM with minimal setup. It also tests how usable Odin and Raylib are for a simple game.

## Local setup

### Requirements
- **(Optionally) Docker**
    - https://www.docker.com/products/docker-desktop/
    - May be used to build without needing Odin or the Emscripten SDK
- **Odin compiler** from January 1st 2025 or newer
    - https://odin-lang.org/docs/install/#official-releases
    - On Windows: Requires MSVC and Windows SDK
- **(For web builds) Emscripten SDK**
    - https://emscripten.org/docs/getting_started/downloads.html#installation-instructions-using-the-emsdk-recommended
    - Also `EMSCRIPTEN_SDK_DIR` in `build.bat`
- **(On Windows) Git Bash**
    - `build.bat` uses Git-Bash by default on Windows to run `build.sh` under Bash
    - Git-Bash ships with Git so you should already have it, otherwise install Git
    - If you wish to use another Windows Bash, edit the line `set WIN_BASH=` in `build.bat`

### Building on Windows
On Windows, run `build.bat` followed by build arguments.
For example: `build.bat release`

The `build.bat` script searches for your local Git Bash installation and uses it to run `build.sh`.
Because of this, you can follow the rest of this setup guide, but except using `build.bat` instead of `build.sh`.

### Building with Docker
Docker can be used to create builds without needing to install Odin or the Emscripten SDK.
To build with Docker, run `build.sh` with `docker` as the first argument, for example:
`build.sh docker release`

The same applies on Windows:
`build.bat docker release`

### Desktop builds
Run `build.sh` followed by build arguments.
- For debug builds run `build.sh debug`
- For release builds run `build.sh release`

For other arguments, run `build.sh help`

### Web build
1. Point `EMSCRIPTEN_SDK_DIR` in `build.bat` to where you installed emscripten.
2. Run `build.sh web`.
3. Web game is in the `build/web` folder.

> [!WARNING]
> You might not be able to open `build/web/index.html` directly due to "CORS policy" javascript errors.
> You can work around that by running a small server, i.e.:
> - `npx http-server ./build/web -c-1`
> - `python -m http.server --directory ./build/web`
