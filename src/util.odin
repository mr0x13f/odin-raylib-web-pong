package game

import "base:intrinsics"
import "core:reflect"
import "core:math/linalg/glsl"
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

rotation_between :: proc(a, b: vec2) -> f32 {
    cross := a.x*b.y - a.y*b.x
    return math.to_degrees(math.atan2(cross, glsl.dot(a, b)))
}

Variant_Filter :: struct(Union: typeid) {
    bit_mask: bit_set[0..<128],
}

create_variant_filter :: proc($Union: typeid, variants: []typeid) -> (filter: Variant_Filter(Union)) {
    for variant in variants {
        union_variant: Union
        reflect.set_union_variant_typeid(union_variant, variant)
        tag := reflect.get_union_variant_raw_tag(union_variant)
        filter.bit_mask += { int(tag) }
    }
    return
}

is_variant_in_filter :: proc(variant: $U, filter: Variant_Filter(U)) -> bool {
    tag := reflect.get_union_variant_raw_tag(variant)
    return int(tag) in filter.bit_mask
}
