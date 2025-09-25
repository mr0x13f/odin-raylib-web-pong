# [odin-raylib-web-pong](https://mr0x13f.github.io/odin-raylib-web-pong/)

Based on the [odin-raylib-web](https://github.com/karl-zylinski/odin-raylib-web) project template by Karl Zylinski.

## Local setup

### Requirements
- **Emscripten**. Follow instructions here: https://emscripten.org/docs/getting_started/downloads.html (the stuff under "Installation instructions using the emsdk (recommended)").
- **Recent Odin compiler**: This uses Raylib binding changes that were done on January 1, 2025.

### Building
1. Point `EMSCRIPTEN_SDK_DIR` in `build_web.bat/sh` to where you installed emscripten.
2. Run `build_web.bat/sh`.
3. Web game is in the `build/web` folder.

> [!NOTE]
> `build_web.bat` is for windows, `build_web.sh` is for Linux / macOS.

> [!WARNING]
> You can't run `build/web/index.html` directly due to "CORS policy" javascript errors. You can work around that by running a small python web server:
> - Go to `build/web` in a console.
> - Run `python -m http.server`
> - Go to `localhost:8000` in your browser.
>
> _For those who don't have python: Emscripten comes with it. See the `python` folder in your emscripten installation directory._

Build a desktop executable using `build_desktop.bat/sh`. It will end up in the `build/desktop` folder.
