package game

import "core:math"
import rl "vendor:raylib"

vec2 :: [2]f32

get_render_size :: proc() -> vec2 {
    return {f32(rl.GetRenderWidth()), f32(rl.GetRenderHeight())}
}

set_raygui_text_size :: proc (text_size: f32) -> f32 {
    rl.GuiSetStyle(rl.GuiControl.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), i32(text_size))
    return text_size
}

// Perform a division, except if the division would result in NaN, instead return an infinity
divide_replace_nan_with_inf :: proc(a: f32, b: f32, inf: f32) -> f32 {
	is_nan := a == 0 && b == 0
	is_not_nan_f := f32(i32(!is_nan))
    // Multiplying infinity by zero as floats results in NaN
    // so instead we multiply with infinity reinterpreted as an int
    inf_or_zero := transmute(f32)(transmute(i32)inf * i32(is_nan))
	return (is_not_nan_f * a + inf_or_zero) / b
}

// TODO: there must be a function for this already
rotate :: proc(v: vec2, degrees: f32) -> vec2 {
    rad := math.to_radians(degrees)
    c := math.cos(rad)
    s := math.sin(rad)
    return {
        v.x * c - v.y * s,
        v.x * s + v.y * c,
    }
}
