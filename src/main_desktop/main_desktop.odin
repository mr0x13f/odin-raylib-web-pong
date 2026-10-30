package main_desktop

import "core:log"
import "core:os"
import "core:path/filepath"
import game "src:."

main :: proc() {
	if !ODIN_DEBUG {
		// Set working dir to dir of executable.
		exe_path := os.args[0]
		exe_dir := filepath.dir(string(exe_path))
		os.set_working_directory(exe_dir)
	}

	context.logger = log.create_console_logger()
	
	game.game_init()

	for game.game_should_run() {
		game.game_loop()
	}

	game.game_shutdown()
}
