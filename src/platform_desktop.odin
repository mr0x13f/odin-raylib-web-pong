#+build !wasm32
#+build !wasm64p32

package game

import rl "vendor:raylib"
import "core:os"

read_entire_file :: proc(name: string, allocator := context.allocator, loc := #caller_location) -> (data: []byte, success: bool) {
	return os.read_entire_file(name, allocator, loc)
}

write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	return os.write_entire_file(name, data, truncate)
}

should_close :: proc() -> bool {
	// Never run this proc in browser. It contains a 16 ms sleep on web!
	return rl.WindowShouldClose()
}
