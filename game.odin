package game

import    "core:fmt"
import rl "vendor:raylib"

// Constants
WINDOW_WIDTH  :: 640 * 2
WINDOW_HEIGHT :: 480 * 2
CENTER_X      :: WINDOW_WIDTH / 2
CENTER_Y      :: WINDOW_HEIGHT / 2

// Define Types & Structures
Scene :: enum {
    Menu,
    Start,
    GameOver,
}

Ship :: struct {

}

Astroid :: struct {

}

Alien :: struct {

}

Particle :: struct {

}

GameMemory :: struct {
    scene: Scene,
    score: int,
    high_score: int,
    lives: int,
    game_over: bool,
    ship: Ship,
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
}

// Game Scenes (Our game loops)
scene_menu :: proc(mem: ^GameMemory) -> Scene {

    for !rl.WindowShouldClose() {

	// Input handling here
	if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
	    return .Start
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

	rl.DrawText("00", WINDOW_WIDTH * 0.8, 10, 24, rl.WHITE)

	coin_str := fmt.ctprintf("1  COIN  1  PLAY")
	coin_str_width := rl.MeasureText(coin_str, 36)
	rl.DrawText(coin_str, CENTER_X - (coin_str_width / 2), WINDOW_HEIGHT * 0.8, 36, rl.WHITE)

	company_str := fmt.ctprintf("2025 BLUE TEAM")
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

	rl.DrawText("00", WINDOW_WIDTH * 0.8, 10, 24, rl.WHITE)

    }

    return .Start
}

scene_game_over :: proc(mem: ^GameMemory) -> Scene {
    return .GameOver
}

