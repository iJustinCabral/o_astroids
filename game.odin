package game

import    "core:fmt"
import    "core:math"
import    "core:math/rand"
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
    {-0.4, -0.5},
    {0.0, 0.5},
    {0.4, -0.5},
    {0.3, -0.4},
    {-0.3, -0.4}
}
THRUST_LINES ::[]rl.Vector2 {
    {-0.3, -0.4},
    {-0.0, -1.0},
    {0.3, -0.4}
}


// Define Types & Structures
Scene :: enum {
    Menu,
    Start,
    GameOver,
}

Entity :: struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    id: int,
}

Ship :: struct {
    using entity: Entity,
    rotation: f32,
    is_dead: bool,
    death_time: f64,
}

Asteroid :: struct {
    using entity: Entity,
    type: AsteroidType,
    size: f32,
    score: int,
    speed: int,
    did_remove: bool,
    vertices: [dynamic]rl.Vector2
}

AsteroidType :: enum {
    BIG,
    MEDIUM,
    SMALL
}

Projectile :: struct {
    using entity: Entity,
    ttl: f64,
    spawn_t: f64,
    did_remove: bool,
}

Sound :: struct {
    blaster: rl.Sound,
    thrust: rl.Sound,
    explode: rl.Sound
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
    frame: int,
    ship: Ship,
    asteroids: [dynamic] Asteroid,
    projectiles: [dynamic] Projectile,
}

mem   := GameMemory{}
sound := Sound{}

main :: proc() {
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Asteroids")
    rl.SetTargetFPS(60)
    rl.InitAudioDevice()

    defer rl.CloseWindow()
    defer rl.CloseAudioDevice()
    defer free_all(context.temp_allocator)

    // Init game state
    reset_game(&mem)
    sound.blaster = rl.LoadSound("blaster.wav")
    sound.thrust = rl.LoadSound("thrust.wav")
    sound.explode = rl.LoadSound("explode.wav")
    

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

// -------------- Misc. Functions ------------------
reset_game :: proc(mem: ^GameMemory) {
    mem.scene = .Menu
    mem.score = 0
    mem.high_score = max(mem.high_score, mem.score)
    mem.lives = 3
    mem.game_over = true
    mem.ship = Ship{position = {CENTER_X, CENTER_Y}, rotation = math.PI, velocity = {0,0}}
    mem.ship.is_dead = false
    mem.ship.death_time = 0
   
    clear_dynamic_array(&mem.asteroids)

    for i in 0..<7 {
	asteroid := create_asteroid({rand.float32_range(10, WINDOW_WIDTH), rand.float32_range(10, WINDOW_HEIGHT)}, .BIG)
	append(&mem.asteroids, asteroid)
    }
}

shoot_projectile :: proc(mem: ^GameMemory) {
    angle := mem.ship.rotation + (math.PI * 0.5)
    direction := rl.Vector2{math.cos(angle), math.sin(angle)}
    velocity := direction * SHIP_SPEED * 40.0

    projectile := Projectile {
	position = mem.ship.position,
	velocity = velocity,
	ttl = 1.5,
	spawn_t = rl.GetTime(),
	did_remove = false 
    }

    append(&mem.projectiles, projectile) 
}

// --------------- Game Scenes (Our game loops) -------------------
scene_menu :: proc(mem: ^GameMemory) -> Scene {

    delay_time : f32 = 2.0
    timer : f32 = 0.0
    show_player1 := false
    reset_game(mem)

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
	if !mem.ship.is_dead {
	    if rl.IsKeyDown(.W) {
		mem.ship.velocity += (direction * (rl.GetFrameTime() * SHIP_SPEED))
		
		if mem.frame % 2 == 0 {
		    rl.PlaySound(sound.thrust)	
		}
	    }

	    if rl.IsKeyDown(.A) {
		mem.ship.rotation -= rl.GetFrameTime() * math.TAU * ROT_SPEED
	    }

	    if rl.IsKeyDown(.D) {
		mem.ship.rotation += rl.GetFrameTime() * math.TAU * ROT_SPEED
	    }

	    if rl.IsKeyPressed(.SPACE) {
		shoot_projectile(mem)
		rl.PlaySound(sound.blaster)
	    }

	}
	else if mem.ship.is_dead && mem.lives == 0 {
	    mem.high_score = mem.score
	    return .GameOver
	}

	update_ship(mem)
	update_projectile(mem)
	update_asteroids(mem)


	// Drawing
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.BLACK)

	score_str := fmt.ctprintf("%02d", mem.score)
	score_str_width := rl.MeasureText(score_str, 24)
	rl.DrawText(score_str, WINDOW_WIDTH * 0.2 - (score_str_width / 2), 10, 24, rl.WHITE)

	high_score_str := fmt.ctprintf("%02d", mem.high_score)
	hs_str_width := rl.MeasureText(high_score_str, 14)
	rl.DrawText(high_score_str, CENTER_X - (hs_str_width / 2), 10, 14, rl.WHITE)

	draw_remaining_lives(mem)
	draw_ship(mem)
	draw_projectile(mem)
	draw_asteroids(mem)	
	

	mem.frame += 1
    }

    return .Start
}

scene_game_over :: proc(mem: ^GameMemory) -> Scene {

    for !rl.WindowShouldClose() {

	if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) {
	    reset_game(mem)
	    return .Menu
	}


	update_asteroids(mem)

	rl.BeginDrawing()
	defer rl.EndDrawing()

	gameover_str := cstring("Game Over")
	gameover_width := rl.MeasureText(gameover_str, 36)
	rl.DrawText("Game Over", CENTER_X - (gameover_width / 2), CENTER_Y, 36, rl.WHITE)

	menu_str := cstring("Press Enter To Restart")
	menu_width := rl.MeasureText(menu_str, 26)
	rl.DrawText("Press Enter To Restart", CENTER_X - (menu_width / 2), CENTER_Y + 40, 26, rl.WHITE)
	
	score_str := fmt.ctprintf("%02d", mem.score)
	score_str_width := rl.MeasureText(score_str, 24)
	rl.DrawText(score_str, WINDOW_WIDTH * 0.2 - (score_str_width / 2), 10, 24, rl.WHITE)

	high_score_str := fmt.ctprintf("%02d", mem.high_score)
	hs_str_width := rl.MeasureText(high_score_str, 14)
	rl.DrawText(high_score_str, CENTER_X - (hs_str_width / 2), 10, 14, rl.WHITE)
    }
    return .GameOver
}

gen_asteroid_verticies :: proc(size: f32, vertex_count: int) -> [dynamic]rl.Vector2 {
    vertices := make([dynamic]rl.Vector2, context.temp_allocator)
    for i in 0..<vertex_count {
	angle := (f32(i) / f32(vertex_count)) * math.TAU
	radius := size + rand.float32_range(-size / 4, size / 4)
	x := math.cos(angle) * radius
	y := math.sin(angle) * radius
	append(&vertices, rl.Vector2{x, y})
    }

    return vertices
}

create_asteroid :: proc(position: rl.Vector2, type: AsteroidType) -> Asteroid {
    asteroid : Asteroid
    asteroid.position = position
    asteroid.type = type 

    switch type {
    case .BIG:
	asteroid.size = 8.0
	asteroid.vertices = gen_asteroid_verticies(8.0, 12)
	asteroid.speed = 50
    case .MEDIUM:
	asteroid.size = 5.0
	asteroid.vertices = gen_asteroid_verticies(5.0, 8)
	asteroid.speed = 75
    case . SMALL:
	asteroid.size = 3.0
	asteroid.vertices = gen_asteroid_verticies(3.0, 5)
	asteroid.speed = 100
    }

    angle := rand.float32_range(0, math.TAU)
    asteroid.velocity = rl.Vector2 {math.cos(angle) * f32(asteroid.speed), math.sin(angle) * f32(asteroid.speed)}

    return asteroid
}

split_asteroid :: proc(mem: ^GameMemory, idx: int) {
    asteroid := mem.asteroids[idx]
    
    switch asteroid.type {
    case .BIG:
	mem.score += 50
        for _ in 0..<2 {
            new_asteroid := create_asteroid(asteroid.position, .MEDIUM)
            append(&mem.asteroids, new_asteroid)
        }
    case .MEDIUM:
	mem.score += 100
        for _ in 0..<2 {
            new_asteroid := create_asteroid(asteroid.position, .SMALL)
            append(&mem.asteroids, new_asteroid)
        }
    case .SMALL:
	mem.score += 200
        break
    }
    
    ordered_remove(&mem.asteroids, idx)
}

check_collision_asteroid_projectile :: proc(asteroid: ^Asteroid, projectile: ^Projectile) -> bool {
    world_vertices := make([dynamic]rl.Vector2, context.temp_allocator)
    for v in asteroid.vertices {
        append(&world_vertices, asteroid.position + v)
    }

    projectile_next_pos := projectile.position + (projectile.velocity * rl.GetFrameTime())

    for i in 0..<len(world_vertices) {
        v1 := world_vertices[i]
        v2 := world_vertices[(i + 1) % len(world_vertices)]
        if line_segment_intersection(projectile.position, projectile_next_pos, v1, v2) {
            return true
        }
    }

    return false
}

check_collision_ship_asteroid :: proc(ship: ^Ship, asteroid: ^Asteroid) -> bool {
    ship_vertices := make([dynamic]rl.Vector2, context.temp_allocator)
    for v in SHIP_LINES {
        append(&ship_vertices, ship.position + rl.Vector2Rotate(v * SCALE, ship.rotation))
    }

    asteroid_vertices := make([dynamic]rl.Vector2, context.temp_allocator)
    for v in asteroid.vertices {
        append(&asteroid_vertices, asteroid.position + (v * asteroid.size))
    }

    // Check if any vertex of one shape is inside the other
    for v in ship_vertices {
        if point_in_polygon(v, asteroid_vertices[:]) {
            return true
        }
    }
    for v in asteroid_vertices {
        if point_in_polygon(v, ship_vertices[:]) {
            return true
        }
    }

    // Check for edge intersections
    for i in 0..<len(ship_vertices) {
        for j in 0..<len(asteroid_vertices) {
            if line_segment_intersection(
                ship_vertices[i],
                ship_vertices[(i + 1) % len(ship_vertices)],
                asteroid_vertices[j],
                asteroid_vertices[(j + 1) % len(asteroid_vertices)]
            ) {
                return true
            }
        }
    }

    return false
}

point_in_polygon :: proc(point: rl.Vector2, vertices: []rl.Vector2) -> bool {
    c := false
    nvert := len(vertices)
    j := nvert - 1
    for i in 0..<nvert {
        if ((vertices[i].y > point.y) != (vertices[j].y > point.y)) &&
           (point.x < (vertices[j].x - vertices[i].x) * (point.y - vertices[i].y) / (vertices[j].y - vertices[i].y) + vertices[i].x) {
            c = !c
        }
        j = i
    }
    return c
}

line_segment_intersection :: proc(a1, a2, b1, b2: rl.Vector2) -> bool {
    cross :: proc(v1, v2: rl.Vector2) -> f32 {
        return v1.x * v2.y - v1.y * v2.x
    }

    d1 := cross(b2 - b1, a1- b1)
    d2 := cross(b2 - b1, a2 - b1)
    d3 := cross(a2 - a1, b1 - a1)
    d4 := cross(a2 - a1, b2 - a1)

    return (d1 * d2 < 0) && (d3 * d4 < 0)
}

update_ship :: proc(mem: ^GameMemory) {
    mem.ship.velocity *= (1.0 - DRAG)
    mem.ship.position += mem.ship.velocity - DRAG

    // Screen wrap the ship when it leaves the bounds
    if mem.ship.position.x < 0 {
	mem.ship.position.x = WINDOW_WIDTH
    } 
    else if mem.ship.position.x > WINDOW_WIDTH {
	mem.ship.position.x = 0
    }

    if mem.ship.position.y < 0 {
	mem.ship.position.y = WINDOW_HEIGHT
    }
    else if mem.ship.position.y > WINDOW_HEIGHT {
	mem.ship.position.y = 0
    }

    // Check if ship should be respawned
    if mem.ship.is_dead {
        current_time := rl.GetTime()
        if mem.ship.death_time == 0 {
	    if mem.lives >= 0 { mem.lives -= 1 }
            mem.ship.death_time = current_time // Record the time of death
	    rl.PlaySound(sound.explode)
        } else if current_time - mem.ship.death_time >= 3.0 {
            // Respawn after 3 seconds
            mem.ship.position = {CENTER_X, CENTER_Y}
            mem.ship.velocity = {0, 0}
            mem.ship.rotation = math.PI
            mem.ship.is_dead = false
            mem.ship.death_time = 0 
        }
    }
}

update_projectile :: proc(mem: ^GameMemory) {
    to_remove := make([dynamic]int, context.temp_allocator)
    current_time := rl.GetTime()

    for i in 0..<len(mem.projectiles) {
        p := &mem.projectiles[i]
        old_position := p.position // Store old position for path calculation
        p.position += p.velocity * rl.GetFrameTime()

        // Screen wrapping
        if p.position.x < 0 { p.position.x = WINDOW_WIDTH }
        else if p.position.x > WINDOW_WIDTH { p.position.x = 0 }
        
        if p.position.y < 0 { p.position.y = WINDOW_HEIGHT }
        else if p.position.y > WINDOW_HEIGHT { p.position.y = 0 }

        // Check if projectile should be removed
        if current_time - p.spawn_t >= p.ttl {
            append(&to_remove, i)
        }
	else {
	    for &a, idx in mem.asteroids {
	    	if !p.did_remove && check_collision_asteroid_projectile(&a, p) {
		    p.did_remove = true
		    split_asteroid(mem, idx)
		    break
		}
	    }
	}
    }

    // Remove expired projectiles
    for i in 0..<len(to_remove) {
        ordered_remove(&mem.projectiles, to_remove[len(to_remove) - i - 1])
    }
}

update_asteroids :: proc(mem: ^GameMemory) {
    for &asteroid, idx in &mem.asteroids {
	// Update position based on velocity
	asteroid.position.x += asteroid.velocity.x * rl.GetFrameTime()
	asteroid.position.y += asteroid.velocity.y * rl.GetFrameTime()

	// Screen wrapping considering asteroid size
        half_size := asteroid.size / 2  // Half of the asteroid's size as its radius
        
        // Check if the asteroid has moved off-screen
        if asteroid.position.x + half_size < 0 {
            asteroid.position.x = WINDOW_WIDTH + half_size - (0 - (asteroid.position.x + half_size))
        } else if asteroid.position.x - half_size > WINDOW_WIDTH {
            asteroid.position.x = -half_size + (asteroid.position.x - half_size - WINDOW_WIDTH)
        }
        
        if asteroid.position.y + half_size < 0 {
            asteroid.position.y = WINDOW_HEIGHT + half_size - (0 - (asteroid.position.y + half_size))
        } else if asteroid.position.y - half_size > WINDOW_HEIGHT {
            asteroid.position.y = -half_size + (asteroid.position.y - half_size - WINDOW_HEIGHT)
        }

	if !mem.ship.is_dead && check_collision_ship_asteroid(&mem.ship, &asteroid) {
	    mem.ship.is_dead = true
	    split_asteroid(mem, idx)
	}
    }

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
	    mem.ship.position,
	    SCALE,
	    mem.ship.rotation,
	    SHIP_LINES,
	    true
	)
    }

    if rl.IsKeyDown(.W) && mem.frame % 2 == 0 {
	draw_lines(
	    mem.ship.position,
	    SCALE,
	    mem.ship.rotation,
	    THRUST_LINES,
	    true
	)  
    }
}

draw_projectile :: proc(mem: ^GameMemory) {
    for projectile in mem.projectiles {
	rl.DrawCircleV(projectile.position, 2, rl.WHITE)
    }
}

draw_asteroids :: proc(mem: ^GameMemory) {
    for asteroid in mem.asteroids {
        half_size := asteroid.size / 2
        positions := [2]rl.Vector2{asteroid.position, asteroid.position}  // Default to current position

        // Check for wrapping on X-axis
        if asteroid.position.x + half_size < 0 {
            // Only draw on the opposite side if fully off-screen
            positions[0].x = WINDOW_WIDTH + 1  // Out of view
            positions[1].x = asteroid.position.x + WINDOW_WIDTH
        } else if asteroid.position.x - half_size > WINDOW_WIDTH {
            positions[0].x = asteroid.position.x - WINDOW_WIDTH
            positions[1].x = -WINDOW_WIDTH - 1  // Out of view
        }

        // Check for wrapping on Y-axis
        if asteroid.position.y + half_size < 0 {
            positions[0].y = WINDOW_HEIGHT + 1  // Out of view
            positions[1].y = asteroid.position.y + WINDOW_HEIGHT
        } else if asteroid.position.y - half_size > WINDOW_HEIGHT {
            positions[0].y = asteroid.position.y - WINDOW_HEIGHT
            positions[1].y = -WINDOW_HEIGHT - 1  // Out of view
        }

        // Draw at both positions if necessary
        for pos in positions {
            // Only draw if the asteroid is fully on-screen or just entering from the other side
            if (pos.x + half_size >= 0 && pos.x - half_size <= WINDOW_WIDTH) && 
               (pos.y + half_size >= 0 && pos.y - half_size <= WINDOW_HEIGHT) {
                draw_lines(
                    pos,
                    asteroid.size,
                    0,
                    asteroid.vertices[:],
                    true
                )
            }
        }
    }
}

