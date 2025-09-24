package game

import rl "vendor:raylib"
import "core:math"
import "core:math/linalg/glsl"

// Axis aligned bounding box
Box :: distinct struct {
    center: vec2,
    size: vec2,
}

top_left :: proc(box: Box) -> vec2 {
    return box.center - box.size / 2
}

bottom_right :: proc(box: Box) -> vec2 {
    return box.center + box.size / 2
}

box_to_rect :: proc(box: Box) -> rl.Rectangle {
    top_left := top_left(box)
    return { top_left.x, top_left.y, box.size.x, box.size.y }
}

box_to_scissor :: proc(box: Box) -> (i32, i32, i32, i32) {
    top_left := top_left(box)
    return i32(top_left.x), i32(top_left.y), i32(box.size.x), i32(box.size.y)
}

find_aabb_overlap_center :: proc(a: Box, b: Box) -> vec2 {
    a_min := top_left(a)
    a_max := bottom_right(a)
    b_min := top_left(b)
    b_max := bottom_right(b)
    overlap_min: vec2 = { max(a_min.x, b_min.x), max(a_min.y, b_min.y) }
    overlap_max: vec2 = { min(a_max.x, b_max.x), min(a_max.y, b_max.y) }
    return (overlap_min + overlap_max) * 0.5
}

check_aabb_collision :: proc(a: Box, b: Box) -> bool {
    a_min := top_left(a)
    a_max := bottom_right(a)
    b_min := top_left(b)
    b_max := bottom_right(b)
    return a_min.x < b_max.x &&
           a_max.x > b_min.x &&
           a_min.y < b_max.y &&
           a_max.y > b_min.y
}

Swept_Aabb_Hit :: struct {
    hit: bool,
    time: f32,
    normal: vec2,
    exit_time: f32,
}

// Branchless axis aligned bounding box shapecast
swept_aabb_collision :: proc(static: Box, moving: Box, movement: vec2) -> Swept_Aabb_Hit {

    movement_sign: vec2 = { math.copy_sign(1, movement.x), math.copy_sign(1, movement.y), }

    axes_entry_dist := (static.center - moving.center) - movement_sign * (static.size/2 + moving.size/2)
    axes_exit_dist  := (static.center - moving.center) + movement_sign * (static.size/2 + moving.size/2)
    axes_entry_time: vec2 = {
        divide_replace_nan_with_inf(axes_entry_dist.x, movement.x, math.NEG_INF_F32),
        divide_replace_nan_with_inf(axes_entry_dist.y, movement.y, math.NEG_INF_F32),
    }
    axes_exit_time: vec2 = {
        divide_replace_nan_with_inf(axes_exit_dist.x, movement.x, math.INF_F32),
        divide_replace_nan_with_inf(axes_exit_dist.y, movement.y, math.INF_F32),
    }

    entry_time := max(axes_entry_time.x, axes_entry_time.y)
    exit_time := min(axes_exit_time.x, axes_exit_time.y)

    hit := entry_time <= exit_time && entry_time >= 0 && entry_time <= 1

    normal := glsl.normalize(-movement_sign * {
        f32(i32(axes_entry_time.x >= axes_entry_time.y)),
        f32(i32(axes_entry_time.y >= axes_entry_time.x)),
    })

    return {
        hit = hit,
        time = entry_time,
        normal = normal,
        exit_time = exit_time,
    }
}
