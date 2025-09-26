package game

import "core:reflect"
import "core:mem"
import "core:math/linalg/glsl"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

// COLOR :: 0x085447FF
COLOR :: 0x1A1A20FF
MAX_ENTITIES :: 16
MAX_PLAYERS :: 4
MAX_MOVE_ITERATIONS :: 4
MAX_PADDLE_BOUNCE_ANGLE :: 75
RANDOM_SERVE_ANGLE_DEVIATION :: 15
BALL_START_SPEED :: 0.4
BALL_SPEED_SCALE_PER_HIT :: 1.1
MAX_BALL_SPEED :: 2
BALL_SIZE :: 0.035

Pong_State :: struct {
    mode: Pong_Mode,
    entities: [MAX_ENTITIES]Maybe(Entity),
    score: [MAX_PLAYERS]i32,
}

Pong_Mode :: enum {
    None,
    Singleplayer,
    Twoplayer,
    Fourplayer,
}

Entity :: struct {
    using box: Box,
    variant: Entity_Variant,
}

Entity_Variant :: union #no_nil {
    Ent_Dummy,
    Ent_Paddle,
    Ent_Ball,
    Ent_Goal,
    Ent_Wall,
}

// Must be identicaly to Entity_Variant
Entity_Variant_Name :: enum {
    Ent_Dummy,
    Ent_Paddle,
    Ent_Ball,
    Ent_Goal,
    Ent_Wall,
}

// Used to pointer cast variants to insert the Entity pointer
Ent_Dummy :: struct {
    using entity: ^Entity,
}

Ent_Paddle :: struct {
    using entity: ^Entity,
    control_axis: vec2,
    direction: vec2,
    player: i32,
}

Ent_Ball :: struct {
    using entity: ^Entity,
    velocity: vec2,
    last_hit_player: Maybe(i32),
}

Ent_Goal :: struct {
    using entity: ^Entity,
    player: i32,
}

Ent_Wall :: struct {
    using entity: ^Entity,
}

pong_state: Pong_State

color_field  := rl.GetColor(COLOR)
color_net    := rl.ColorLerp(color_field, rl.WHITE, 0.2)
color_paddle := rl.ColorLerp(color_field, rl.WHITE, 0.7)
color_ball   := color_paddle
color_wall   := color_paddle
color_score  := color_net

touch_input := false

pong_init :: proc() {



}

pong_update :: proc(dt: f32) {

    field_box: Box = pong_get_field_box()
    field_top_left := top_left(field_box)

    player_inputs: [MAX_PLAYERS]Maybe(vec2)
    touch_count := rl.GetTouchPointCount()
    if (touch_count > 0) {
        touch_input = true
        for i in 0..<touch_count {
            touch_pos := rl.GetTouchPosition(i)
            touch_field_pos := glsl.saturate((touch_pos - field_top_left) / field_box.size)
            player := pong_get_input_player_from_field_pos(touch_field_pos)
            if player != -1 { player_inputs[player] = touch_field_pos }
        }
    } else if !touch_input {
        mouse_pos := rl.GetMousePosition()
        mouse_field_pos := glsl.saturate((mouse_pos - field_top_left) / field_box.size)
        player := pong_get_input_player_from_field_pos(mouse_field_pos)
        if player != -1 { player_inputs[player] = mouse_field_pos }
    }

    for &entity in pong_state.entities {
        if entity == nil { continue }
        #partial switch &e in (&entity.?).variant {

            case Ent_Paddle:
                pong_control_paddle(&e, player_inputs)

            case Ent_Ball:
	            pong_move_ball(&e, dt)
        }
    }

}

pong_draw :: proc() {
	rl.ClearBackground(rl.BLACK)

    field_box: Box = pong_get_field_box()
    field_top_left := top_left(field_box)

    {
        rl.BeginScissorMode(box_to_scissor(field_box))
        defer rl.EndScissorMode()
        rlgl.PushMatrix()
        defer rlgl.PopMatrix()
        rlgl.Translatef(field_top_left.x, field_top_left.y, 0)
        rlgl.Scalef(field_box.size.x, field_box.size.y, 1)
        
        pong_draw_field()
    }
}

pong_draw_field :: proc() {
    
	rl.DrawRectangleRec({0, 0, 1, 1}, color_field)

    // Net
    #partial switch pong_state.mode {
        case .Twoplayer:
	        rl.DrawRectangleRec(box_to_rect({ {0.5, 0.5}, {1, 0.02} }), color_net)
        case .Fourplayer:
	        rl.DrawRectanglePro(box_to_rect({ {1.25, 0.51}, {1.5, 0.02} }), { 0.75, 0.01 }, +45, color_net)
	        rl.DrawRectanglePro(box_to_rect({ {1.25, 0.51}, {1.5, 0.02} }), { 0.75, 0.01 }, -45, color_net)
    }

    // Entities
    for &entity in pong_state.entities {
        if entity == nil { continue } 
        #partial switch &e in (&entity.?).variant {
            case Ent_Paddle:
	            rl.DrawRectangleRec(box_to_rect(e.box), color_paddle)
                pong_draw_paddle_score(&e)
            case Ent_Ball:
	            rl.DrawRectangleRec(box_to_rect(e.box), color_ball)
            case Ent_Wall:
	            rl.DrawRectangleRec(box_to_rect(e.box), color_wall)
            case Ent_Goal:
	            rl.DrawRectangleRec(box_to_rect(e.box), color_net)
        }
    }

}

pong_draw_paddle_score :: proc(paddle: ^Ent_Paddle) {
    score := pong_state.score[paddle.player]
    pos: vec2

    #partial switch pong_state.mode {
        case .Singleplayer:
            pos = { 0.5, 0.5 }
        case .Twoplayer: fallthrough
        case .Fourplayer:
            pos =  { 0.5, 0.5 } - paddle.direction * 0.1
    }

    font_size: f32 = 0.1
    spacing: f32 = font_size/4
    rotation: f32 = rotation_between({0, -1}, paddle.direction)
    font := rl.GetFontDefault()
    text := rl.TextFormat("%i", score)
    text_size := rl.MeasureTextEx(font, text, font_size, spacing)
    top_left_pos := pos - text_size/2 // TODO: not correct for rotated for some reason
    rl.DrawTextPro(font, text, top_left_pos, {}, rotation, font_size, spacing, color_score)
}

pong_ui :: proc() {

    font_text_size := f32(rl.GuiGetStyle(rl.GuiControl.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE)))
    gui_scale := max(math.floor(f32(rl.GetRenderHeight()) / 640), 1)
    base_text_size := font_text_size * gui_scale
    text_size := set_raygui_text_size(base_text_size*2)

    background_color := rl.GetColor(u32(rl.GuiGetStyle(rl.GuiControl.DEFAULT, i32(rl.GuiDefaultProperty.BACKGROUND_COLOR))))
    background_color = rl.ColorAlpha(background_color, 0.7)

    y: f32 = 0
	rl.DrawRectangleRec({0, 0, 22*base_text_size, text_size*9}, background_color)
    y += base_text_size
    rl.GuiLabel({base_text_size, y, 20*base_text_size, text_size+4}, "P O N G")
    // rl.GuiLabel({base_text_size*10, y, 20*base_text_size, text_size+4}, rl.TextFormat("fps: %i", i32(1/rl.GetFrameTime())))
    y += text_size * 1.3

	if rl.GuiButton({base_text_size, y, 20*base_text_size, text_size+4}, "1 Players")  {
		pong_start_singleplayer()
	}
    y += text_size * 1.3

	if rl.GuiButton({base_text_size, y, 20*base_text_size, text_size+4}, "2 Players") {
		pong_start_twoplayer()
	}
    y += text_size * 1.3

	if rl.GuiButton({base_text_size, y, 20*base_text_size, text_size+4}, "4 Players") {
		pong_start_fourplayer()
	}
    y += text_size * 1.3

	if rl.GuiButton({base_text_size, y, 20*base_text_size, text_size+4}, "Add Ball") {
		pong_serve({0, 1})
	}
    y += text_size * 1.3

    text_size = set_raygui_text_size(base_text_size)

    rl.GuiLabel({base_text_size, y, 20*base_text_size, text_size+4}, "Multiplayer requires touch input")
    y += text_size * 1.3

    rl.GuiLabel({base_text_size, y, 20*base_text_size, text_size+4}, "Made with Odin and Raylib")
    y += text_size * 1.3

    set_raygui_text_size(font_text_size)

}

pong_get_input_player_from_field_pos :: proc(field_pos: vec2) -> i32 {

    #partial switch (pong_state.mode) {
        case .Singleplayer:
            return 0
        case .Twoplayer:
            //   1
            // -----
            //   0
            return i32(field_pos.y < 0.5)
        case .Fourplayer:
            // \ 1 /
            // 3 X 2
            // / 0 \
            top  := i32(field_pos.y < 0.5)
            left := i32(field_pos.x < 0.5)
            is_vertical := i32(math.abs(field_pos.x-0.5) < math.abs(field_pos.y-0.5))
            return is_vertical * top + (1-is_vertical) * (left + 2)
        case:
            return -1
    }
}

pong_get_field_box :: proc() -> Box {
    field_size: f32 = min(f32(rl.GetRenderWidth()), f32(rl.GetRenderHeight()))
    field_box: Box = {get_render_size() / 2, field_size}
    return field_box
}

pong_control_paddle :: proc(paddle: ^Ent_Paddle, player_inputs: [MAX_PLAYERS]Maybe(vec2)) {
    if (player_inputs[paddle.player] == nil) { return }

    new_pos := paddle.center * (1 - paddle.control_axis) + paddle.control_axis * player_inputs[paddle.player].(vec2)
    initial_movement := new_pos - paddle.center
    remaining_movement := initial_movement
    iteration := 0

    for iteration < MAX_MOVE_ITERATIONS {

        hit, hit_ent := shapecast(paddle, remaining_movement, { .Ent_Wall })

        // No hit, stop early
        if (!hit.hit) {
            paddle.center += remaining_movement
            return
        }

        // Move until hit
        paddle.center += remaining_movement * hit.time
        paddle.center += hit.normal * math.F32_EPSILON

        // Resolve collision
        #partial switch &e in hit_ent.?.variant {
            case Ent_Wall:
                // Just stop
                return
        }

        // Do another swept iteration for the remaining movement
        remaining_movement *= 1 - hit.time
        iteration += 1
    }
}

pong_move_ball :: proc(ball: ^Ent_Ball, dt: f32) {

    iteration: i32 = 0
    movement := ball.velocity * dt

    for iteration < MAX_MOVE_ITERATIONS {

        hit, hit_ent := shapecast(ball, movement)

        // No hit, stop early
        if (!hit.hit) {
            ball.center += movement
            return
        }

        // Move until hit
        ball.center += movement * hit.time

        // Resolve collision
        #partial switch &e in hit_ent.?.variant {
            case Ent_Paddle:
                // Bounce off at angle depending on position on paddle
                pong_paddle_bounce_ball(ball, &e)
                ball.last_hit_player = e.player
                if pong_state.mode == .Singleplayer {
                    pong_state.score[0] += 1
                }
            case Ent_Wall:
                // Bounce off
                ball.velocity = glsl.reflect(ball.velocity, hit.normal)
            case Ent_Ball:
                // Bounce both balls
                // Use speed of fastest ball
                fastest_ball_speed := max(glsl.length(ball.velocity), glsl.length(e.velocity))
                ball.velocity = glsl.normalize(glsl.reflect(ball.velocity, hit.normal)) * fastest_ball_speed
                e.velocity = glsl.normalize(glsl.reflect(e.velocity, hit.normal)) * fastest_ball_speed
            case Ent_Goal:
                pong_goal(ball, &e)
        }

        // Do another swept iteration for the remaining movement
        remaining_time := 1 - hit.time
        movement = ball.velocity * dt * remaining_time
        iteration += 1

    }
}

pong_paddle_bounce_ball :: proc(ball: ^Ent_Ball, paddle: ^Ent_Paddle) {
    // Bounce ball at angle depending on where on the paddle it hit
    hit_point := find_aabb_overlap_center(ball.box, paddle.box)
    hit_point_on_paddle: vec2 = (hit_point - paddle.center) / paddle.size * 2 // -1..1
    hit_point_on_paddle_axis: f32 = hit_point_on_paddle.x * -paddle.direction.y + hit_point_on_paddle.y * paddle.direction.x
    bounce_angle := MAX_PADDLE_BOUNCE_ANGLE * hit_point_on_paddle_axis
    bounce_direction := rotate(paddle.direction, bounce_angle)
    new_speed := min(glsl.length(ball.velocity) * BALL_SPEED_SCALE_PER_HIT, MAX_BALL_SPEED)
    ball.velocity = bounce_direction * new_speed
}

pong_goal :: proc(ball: ^Ent_Ball, goal: ^Ent_Goal) {
    destroy_entity(ball)
    serve_direction := - find_player_paddle(goal.player).direction
    pong_serve(serve_direction)

    #partial switch pong_state.mode {
        case .Singleplayer:
            pong_state.score[goal.player] = 0
        case .Twoplayer:
            pong_state.score[1 - goal.player] += 1
        case .Fourplayer:
            if ball.last_hit_player != nil {
                pong_state.score[ball.last_hit_player.?] += 1
            } else {
                pong_state.score[goal.player] -= 1
                pong_state.score[goal.player] = max(0, pong_state.score[goal.player])
            }
    }
}

shapecast :: proc(shape: ^Entity, movement: vec2, variant_filter: bit_set[Entity_Variant_Name] = ~bit_set[Entity_Variant_Name]{} ) -> (hit: Swept_Aabb_Hit, hit_ent: Maybe(^Entity)) {
    first_hit_entity: Maybe(^Entity) = nil
    first_hit: Swept_Aabb_Hit = {
        hit = false,
        time = 2,
    }

    // Find first colliding entity
    for &entity in pong_state.entities {
        if entity == nil || &entity.? == shape { continue }
        if variant_of(&entity.?) not_in variant_filter { continue }

        new_hit := swept_aabb_collision(entity.?.box, shape.box, movement)

        if (new_hit.hit && new_hit.time < first_hit.time) {
            first_hit = new_hit
            first_hit_entity = &entity.?
        }
    }

    return first_hit, first_hit_entity
}

find_player_paddle :: proc(player: i32) -> ^Ent_Paddle {
    for &entity in pong_state.entities {
        if entity == nil { continue }
        paddle := (&(&entity.(Entity)).variant.(Ent_Paddle)) or_continue
        if paddle.player == player { return paddle }
    }
    panic("")
}

pong_start_singleplayer :: proc() {
    pong_state.mode = .Singleplayer
    mem.zero_slice(pong_state.entities[:])
    mem.zero_slice(pong_state.score[:])
    
    // Paddles
    summon_entity(Entity {
        center = { 0.5, 0.9, },
        size = { 0.2, BALL_SIZE, },
        variant = Ent_Paddle {
            control_axis = { 1, 0 },
            direction = { 0, -1 },
            player = 0,
        },
    })
    // Walls
    summon_entity(Entity {
        center = { 0.5, 0.05, },
        size = { 1, 0.1, },
        variant = Ent_Wall { },
    })
    summon_entity(Entity {
        center = { -0.1, 0.5, },
        size = { 0.2, 1.2, },
        variant = Ent_Wall { },
    })
    summon_entity(Entity {
        center = { 1.1, 0.5, },
        size = { 0.2, 1.2, },
        variant = Ent_Wall { },
    })
    // Goals
    summon_entity(Entity {
        center = { 0.5, 1.1, },
        size = { 1, 0.1, },
        variant = Ent_Goal {
            player = 0,
        },
    })

    pong_serve({0, 1})
}

pong_start_twoplayer :: proc() {
    pong_state.mode = .Twoplayer
    mem.zero_slice(pong_state.entities[:])
    mem.zero_slice(pong_state.score[:])

    // Paddles
    summon_entity(Entity {
        center = { 0.5, 0.9, },
        size = { 0.2, BALL_SIZE, },
        variant = Ent_Paddle {
            control_axis = { 1, 0 },
            direction = { 0, -1 },
            player = 0,
        },
    })
    summon_entity(Entity {
        center = { 0.5, 0.1 },
        size = { 0.2, BALL_SIZE, },
        variant = Ent_Paddle {
            control_axis = { 1, 0 },
            direction = { 0, 1 },
            player = 1,
        },
    })
    // Walls
    summon_entity(Entity {
        center = { -0.1, 0.5, },
        size = { 0.2, 1.2, },
        variant = Ent_Wall { },
    })
    summon_entity(Entity {
        center = { 1.1, 0.5, },
        size = { 0.2, 1.2, },
        variant = Ent_Wall { },
    })
    // Goals
    summon_entity(Entity {
        center = { 0.5, 1.1, },
        size = { 1, 0.1, },
        variant = Ent_Goal {
            player = 0,
        },
    })
    summon_entity(Entity {
        center = { 0.5, -0.1, },
        size = { 1, 0.1, },
        variant = Ent_Goal {
            player = 1,
        },
    })

    pong_serve({0, 1})
}

pong_start_fourplayer :: proc() {
    pong_state.mode = .Fourplayer
    mem.zero_slice(pong_state.entities[:])
    mem.zero_slice(pong_state.score[:])

    corner_wall_size: f32 = 0.1 + BALL_SIZE/2

    // Paddles
    summon_entity(Entity {
        center = { 0.5, 0.9, },
        size = { 0.2, BALL_SIZE, },
        variant = Ent_Paddle {
            control_axis = { 1, 0 },
            direction = { 0, -1 },
            player = 0,
        },
    })
    summon_entity(Entity {
        center = { 0.5, 0.1 },
        size = { 0.2, BALL_SIZE, },
        variant = Ent_Paddle {
            control_axis = { 1, 0 },
            direction = { 0, 1 },
            player = 1,
        },
    })
    summon_entity(Entity {
        center = { 0.9, 0.5 },
        size = { BALL_SIZE, 0.2, },
        variant = Ent_Paddle {
            control_axis = { 0, 1 },
            direction = { -1, 0 },
            player = 2,
        },
    })
    summon_entity(Entity {
        center = { 0.1, 0.5, },
        size = { BALL_SIZE, 0.2, },
        variant = Ent_Paddle {
            control_axis = { 0, 1 },
            direction = { 1, 0 },
            player = 3,
        },
    })
    // Walls
    summon_entity(Entity {
        center = { corner_wall_size/2, corner_wall_size/2 },
        size = { corner_wall_size, corner_wall_size },
        variant = Ent_Wall { },
    })
    summon_entity(Entity {
        center = { 1-corner_wall_size/2, corner_wall_size/2 },
        size = { corner_wall_size, corner_wall_size },
        variant = Ent_Wall { },
    })
    summon_entity(Entity {
        center = { corner_wall_size/2, 1-corner_wall_size/2 },
        size = { corner_wall_size, corner_wall_size },
        variant = Ent_Wall { },
    })
    summon_entity(Entity {
        center = { 1-corner_wall_size/2, 1-corner_wall_size/2 },
        size = { corner_wall_size, corner_wall_size },
        variant = Ent_Wall { },
    })
    // Goals
    summon_entity(Entity {
        center = { 0.5, 1.1, },
        size = { 1, 0.1, },
        variant = Ent_Goal {
            player = 0,
        },
    })
    summon_entity(Entity {
        center = { 0.5, -0.1, },
        size = { 1, 0.1, },
        variant = Ent_Goal {
            player = 1,
        },
    })
    summon_entity(Entity {
        center = { 1.1, 0.5, },
        size = { 0.1, 1, },
        variant = Ent_Goal {
            player = 2,
        },
    })
    summon_entity(Entity {
        center = { -0.1, 0.5, },
        size = { 0.1, 1, },
        variant = Ent_Goal {
            player = 3,
        },
    })

    pong_serve({0, 1})
}

pong_serve :: proc(direction: vec2) {
    if pong_state.mode == .None { return }

    serve_angle := rand.float32_range(-1, 1) * RANDOM_SERVE_ANGLE_DEVIATION
    serve_direction := rotate(direction, serve_angle)
    
    summon_entity(Entity {
        center = vec2 { 0.5, 0.5 } - direction*0.2,
        size = { BALL_SIZE, BALL_SIZE},
        variant = Ent_Ball {
            velocity = serve_direction * BALL_START_SPEED,
        },
    })
}

variant_of :: proc(entity: ^Entity) -> Entity_Variant_Name {
    when size_of(Entity_Variant_Name) == 4 {
        tag := u32(reflect.get_union_variant_raw_tag(entity.variant))
    }
    when size_of(Entity_Variant_Name) == 8 {
        tag := u64(reflect.get_union_variant_raw_tag(entity.variant))
    }
    return transmute(Entity_Variant_Name)tag
}

destroy_entity :: proc(entity: ^Entity) {
    for i in 0..<len(pong_state.entities) {
        ent_at_idx := (&pong_state.entities[i].(Entity)) or_continue
        if ent_at_idx == entity {
            pong_state.entities[i] = nil
            return
        }
    }
}

summon_entity :: proc(entity: Entity) -> (ent: ^Entity, ok: bool) {
    for i in 0..<len(pong_state.entities) {
        if pong_state.entities[i] == nil {
            pong_state.entities[i] = entity
            entptr := &pong_state.entities[i].?
            ((^Ent_Dummy)(&entptr.variant)).entity = &pong_state.entities[i].?
            return entptr, true
        }
    }
    return nil, false
}
