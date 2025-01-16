package game

import    "core:fmt"
import    "core:math"
import rl "vendor:raylib"

// Constants
WINDOW_WIDTH  :: 640 * 2
WINDOW_HEIGHT :: 480 * 2
CENTER_X      :: WINDOW_WIDTH / 2
CENTER_Y      :: WINDOW_HEIGHT / 2
THICKNESS     :: 2.5
SCALE         :: 28
DRAG          :: 0.02
SHIP_SPEED    :: 20
ROT_SPEED     :: 2
SHIP_LINES    :: []rl.Vector2 {
    rl.Vector2{-0.4, -0.5},
    rl.Vector2{0.0, 0.5},
    rl.Vector2{0.4, -0.5},
    rl.Vector2{0.3, -0.4},
    rl.Vector2{-0.3, -0.4}
}


// Define Types & Structures
Scene :: enum {
    Menu,
    Start,
    GameOver,
}

Entity :: struct {
    pos: rl.Vector2,
    velocity: rl.Vector2,
    id: int,
}

Ship :: struct {
    using entity: Entity,
    rotation: f32,
    is_dead: bool,
}

Astroid :: struct {
   using entity: Entity, 
}

Alien :: struct {
    using entity: Entity,    
}

Particle :: struct {
    using entity: Entity,
}

Projectile :: struct {
    using entity: Entity,
}

LineBuilder :: struct {
    origin: rl.Vector2,
    scale: f32,
    rotation: f32,
}

GameMemory :: struct {
    scene: Scene,
    score: int,
    high_score: int,
    lives: int,
    game_over: bool,
    ship: Ship,
    alien: Alien,
    asteroids: [dynamic] Astroid,
    projectiles: [dynamic] Projectile,
}

mem : GameMemory = GameMemory{}

main :: proc() {
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Astroids")
    defer rl.CloseWindow()
    defer free_all(context.temp_allocator)

    // Init game state
    reset_game(&mem)

    for !rl.WindowShouldClose() {
	switch mem.scene {
	case .Menu:
	    mem.scene = scene_menu(&mem)
	case .Start:
	    mem.scene = scene_start(&mem)
	case .GameOver:
	    mem.scene = scene_game_over(&mem)
	}	
    }
}

// Reset State
reset_game :: proc(mem: ^GameMemory) {
    mem.scene = .Menu
    mem.score = 0
    mem.high_score = 0
    mem.lives = 3
    mem.game_over = true
    mem.ship = Ship{pos = {CENTER_X, CENTER_Y}, rotation = 0.0, velocity = {0,0}}
}

// --------------- Game Scenes (Our game loops) -------------------
scene_menu :: proc(mem: ^GameMemory) -> Scene {

    delay_time : f32 = 2.0
    timer : f32 = 0.0
    show_player1 := false

    for !rl.WindowShouldClose() {

	// Input handling here
	if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
	    timer = delay_time
	    show_player1 = true
	}

	if timer > 0 {
	    timer -= rl.GetFrameTime()
	    if timer <= 0 {
		return .Start
	    }
	}

	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.BLACK)

	score_str := fmt.ctprintf("%02d", mem.score)
	score_str_width := rl.MeasureText(score_str, 24)
	rl.DrawText(score_str, WINDOW_WIDTH * 0.2 - (score_str_width / 2), 10, 24, rl.WHITE)

	high_score_str := fmt.ctprintf("%02d", mem.high_score)
	hs_str_width := rl.MeasureText(high_score_str, 14)
	rl.DrawText(high_score_str, CENTER_X - (hs_str_width / 2), 10, 14, rl.WHITE)

	if show_player1 {
	    player_str := cstring("Player 1")
	    player_str_width := rl.MeasureText(player_str, 36)
	    rl.DrawText("Player 1", CENTER_X - (player_str_width / 2), CENTER_Y, 36, rl.WHITE)
	}
	else {
	    rl.DrawText("00", WINDOW_WIDTH * 0.8, 10, 24, rl.WHITE)

	    coin_str := fmt.ctprintf("1  COIN  1  PLAY")
	    coin_str_width := rl.MeasureText(coin_str, 36)
	    rl.DrawText(coin_str, CENTER_X - (coin_str_width / 2), WINDOW_HEIGHT * 0.8, 36, rl.WHITE)
	}

	company_str := fmt.ctprintf("2025 MOCKTARI")
	company_str_width := rl.MeasureText(company_str, 24)
	rl.DrawText(company_str, CENTER_X - (company_str_width / 2) + 8, WINDOW_HEIGHT * 0.95, 24, rl.WHITE)

	copyright_str := fmt.ctprintf("©")
	copy_str_width := rl.MeasureText(copyright_str, 24)
	rl.DrawText(copyright_str, CENTER_X - company_str_width / 2 - copy_str_width, WINDOW_HEIGHT - 50, 24, rl.WHITE)

    }

    return .Menu
}

scene_start :: proc(mem: ^GameMemory) -> Scene {

    for !rl.WindowShouldClose() {

	angle := mem.ship.rotation + (math.PI * 0.5)
	direction : rl.Vector2 = {math.cos(angle), math.sin(angle)}

	// Input 
	if rl.IsKeyDown(.W) {
	    mem.ship.velocity = mem.ship.velocity + (direction * (rl.GetFrameTime() * SHIP_SPEED))
	    // TODO: Play Sound when the ship moves
	}

	if rl.IsKeyDown(.A) {
	    mem.ship.rotation -= rl.GetFrameTime() * math.TAU * ROT_SPEED
	}

	if rl.IsKeyDown(.D) {
	    mem.ship.rotation += rl.GetFrameTime() * math.TAU * ROT_SPEED
	}
	
	mem.ship.velocity = mem.ship.velocity * (1.0 - DRAG)
	mem.ship.pos = mem.ship.pos + mem.ship.velocity
	// Update



	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.BLACK)

	// Score UI
	score_str := fmt.ctprintf("%02d", mem.score)
	score_str_width := rl.MeasureText(score_str, 24)
	rl.DrawText(score_str, WINDOW_WIDTH * 0.2 - (score_str_width / 2), 10, 24, rl.WHITE)

	high_score_str := fmt.ctprintf("%02d", mem.high_score)
	hs_str_width := rl.MeasureText(high_score_str, 14)
	rl.DrawText(high_score_str, CENTER_X - (hs_str_width / 2), 10, 14, rl.WHITE)

	draw_remaining_lives(mem)
	draw_ship(mem)
    }

    return .Start
}

scene_game_over :: proc(mem: ^GameMemory) -> Scene {
    return .GameOver
}

// -------- Rendering ----------
draw_line :: proc(lb: ^LineBuilder, point: rl.Vector2) -> rl.Vector2 {
    return (rl.Vector2Rotate(point, lb.rotation) * lb.scale) + lb.origin
}

draw_lines :: proc(o: rl.Vector2, s: f32, r: f32, points: []rl.Vector2, connect: bool) {
    lb := LineBuilder{origin = o, scale = s, rotation = r}
    
    bounds := len(points) if connect else len(points) - 1
    for i in 0..<bounds {
	rl.DrawLineEx(
	    draw_line(&lb, points[i]),
	    draw_line(&lb, points[(i + 1) % len(points)]),
	    THICKNESS,
	    rl.WHITE
	)
    }
}

draw_remaining_lives :: proc(mem: ^GameMemory) {
    for i in 0..<mem.lives {
	draw_lines(
	    {WINDOW_WIDTH * 0.8 + f32(i) * SCALE, SCALE},
	    SCALE,
	    math.PI,
	    SHIP_LINES,
	    true,
	)
    }
}

draw_ship :: proc(mem: ^GameMemory) {
    if !mem.ship.is_dead {
	draw_lines(
	    mem.ship.pos,
	    SCALE,
	    mem.ship.rotation,
	    SHIP_LINES,
	    true
	)
    }
}
