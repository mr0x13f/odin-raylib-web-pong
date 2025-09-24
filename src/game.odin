package game

import rl "vendor:raylib"
import "core:c"

run: bool

game_init :: proc() {
	run = true
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT, .MSAA_4X_HINT})
	rl.InitWindow(1280, 720, "Odin/Raylib/WASM Pong")

	pong_init()
}

game_loop :: proc() {

	game_update(rl.GetFrameTime())

	rl.BeginDrawing()

	game_draw()
	game_ui()

	rl.EndDrawing()

	// Anything allocated using temp allocator is invalid after this.
	free_all(context.temp_allocator)
}

game_update :: proc(dt: f32) {

	pong_update(dt)

}

game_draw :: proc() {
	
	pong_draw()
	
}

game_ui :: proc () {

	pong_ui()

}

web_window_resized :: proc(w, h: int) {
	rl.SetWindowSize(c.int(w), c.int(h))
}

game_shutdown :: proc() {
	rl.CloseWindow()
}

game_should_run :: proc() -> bool {
	if should_close() {
		run = false
	}

	return run
}