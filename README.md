# [odin-raylib-web-pong](https://mr0x13f.github.io/odin-raylib-web-pong/)

An implementation of Pong written in Odin using Raylib. Running natively on desktop and compiled to WASM to run in the browser.

Based on the [odin-raylib-web](https://github.com/karl-zylinski/odin-raylib-web) project template by Karl Zylinski.

This project was meant to try out the feasability of making a graphical application for the web using WASM with minimal setup. It also tests how usable Odin and Raylib are for a simple game. I was pleasently surprised how easy it was to do both. In fact I found it easier to write Pong in Odin/Raylib than other languages and frameworks I had used before, like Love2d. This is noteworthy as Odin is a native systems language without a garbage collector or fancy OOP features. Compared to this, paying the performance cost and reduced portability that's part of the trade-off with using other "simple" alternatives like Love2d, doesn't seem worth it anymore.

## Local setup

### Requirements
- **Odin compiler** from January 1st 2025 or newer
    - https://odin-lang.org/docs/install/#official-releases
    - On Windows: Requires MSVC and Windows SDK
- **(For web builds) Emscripten SDK**
    - https://emscripten.org/docs/getting_started/downloads.html#installation-instructions-using-the-emsdk-recommended
    - Also `EMSCRIPTEN_SDK_DIR` in `build.bat`
- **(On Windows) Git Bash**
    - `build.bat` uses Git-Bash by default on Windows to itself under Bash
    - Git-Bash ships with Git so you should already have it, otherwise install Git
    - If you wish to use another Bash, edit the line `set BASH=` in `build.bat`

### Desktop builds
- For debug builds run `build.bat debug`
- For release builds run `build.bat web`

### Web build
1. Point `EMSCRIPTEN_SDK_DIR` in `build.bat` to where you installed emscripten.
2. Run `build.bat web`.
3. Web game is in the `build/web` folder.

> [!NOTE]
> On Linux and macOS, `build.bat` must be invoked as `bash build.bat`.

> [!WARNING]
> You might not be able to run `build/web/index.html` directly due to "CORS policy" javascript errors.
> You can work around that by running a small server, i.e.:
> - `npx http-server ./build/web -c-1`
> - `python -m http.server --directory ./build/web`
