// These procs are the ones that will be called from `index.html`, which is
// generated from `index_template.html`.

package main_web

import "core:log"
import "base:runtime"
import "core:c"
import "core:mem"
import game ".."

@(private="file")
web_context: runtime.Context

@export
main_start :: proc "c" () {
	context = runtime.default_context()

	// The WASM allocator doesn't seem to work properly in combination with
	// emscripten. There is some kind of conflict with how the manage memory.
	// So this sets up an allocator that uses emscripten's malloc.
	context.allocator = emscripten_allocator()
	runtime.init_global_temporary_allocator(1*mem.Megabyte)

	web_context = context

	game.game_init()
}

@export
main_update :: proc "c" () -> bool {
	context = web_context
	game.game_loop()
	return game.game_should_run()
}

@export
main_end :: proc "c" () {
	context = web_context
	game.game_shutdown()
}

@export
web_window_size_changed :: proc "c" (w: c.int, h: c.int) {
	context = web_context
	game.web_window_resized(int(w), int(h))
}
