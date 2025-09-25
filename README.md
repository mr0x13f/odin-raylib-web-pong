# [odin-raylib-web-pong](https://mr0x13f.github.io/odin-raylib-web-pong/)

An implementation of Pong written in Odin using Raylib. Running natively on desktop and compiled to WASM to run in the browser.

Based on the [odin-raylib-web](https://github.com/karl-zylinski/odin-raylib-web) project template by Karl Zylinski.

This project was meant to try out the feasability of making a graphical application for the web using WASM with minimal setup. It also tests how usable Odin and Raylib are for a simple game. I was pleasently surprised how easy it was to do both. In fact I found it easier to write Pong in Odin/Raylib than other languages and frameworks I had used before, like Love2d. This is noteworthy as Odin is a native systems language without a garbage collector or fancy OOP features. Compared to this, paying the performance cost and reduced portability that's part of the trade-off with using other "simple" alternatives like Love2d, doesn't seem worth it anymore.

## Local setup

### Requirements
- **Odin compiler** from January 1st 2025 or newer
    - https://odin-lang.org/docs/install/#official-releases
    - On Windows: Requires MSVC and Windows SDK
- **Emscripten SDK**
    - https://emscripten.org/docs/getting_started/downloads.html#installation-instructions-using-the-emsdk-recommended

### Desktop builds
- For debug builds run `build_web.bat/sh debug`
- For release builds run `build_web.bat/sh web`

### Web build
1. Point `EMSCRIPTEN_SDK_DIR` in `build_web.bat/sh` to where you installed emscripten.
2. Run `build.bat/sh web`.
3. Web game is in the `build/web` folder.

> [!NOTE]
> `build.bat` is for windows, `build.sh` is for Linux / macOS.

> [!WARNING]
> You might not be able to run `build/web/index.html` directly due to "CORS policy" javascript errors. You can work around that by running a small server, i.e.:
> - `npx http-server ./build/web -c-1`
> - `python -m http.server --directory ./build/web`
