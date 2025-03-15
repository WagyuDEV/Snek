package main

import "core:c"
import "core:fmt"
import "core:math"
import "core:os"
import "core:math/rand"

import rl "vendor:raylib"

ASPECT_RATIO :f32: 16/9
WINDOW_WIDTH :c.int: 1280
WINDOW_HEIGHT :c.int: 720

TILE_SIZE :: 20

// delta time
dt: f32

Camera := rl.Camera2D{
    offset = rl.Vector2{0,0},
    target = rl.Vector2{0,0},
    rotation = 0,
    zoom = 1
}

Dir :: enum{
    NORTH,
    EAST,
    SOUTH,
    WEST
}

GAME_STATE :: enum{
    MENU,
    PAUSED,
    GAMEPLAY
}

DEBUG :: false

// snake butt
tail: [dynamic]rl.Vector2
dir: Dir

alive: bool

move_timer :f32 = 0.0

gs := GAME_STATE.MENU

fruit : rl.Vector2

main :: proc(){
    // window init
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "snek")
    rl.SetWindowState(rl.ConfigFlags{.WINDOW_RESIZABLE})
    // rl.SetTargetFPS(10)

    // game init
    tail = make([dynamic]rl.Vector2, 1, WINDOW_WIDTH*WINDOW_HEIGHT/TILE_SIZE)
    dir = .SOUTH
    alive = true

    fruit = rl.Vector2{math.floor(rand.float32()*f32(WINDOW_WIDTH)), math.floor(rand.float32()*f32(WINDOW_HEIGHT))}

    for contains(tail, fruit) || int(fruit.x) % TILE_SIZE != 0 || int(fruit.y) % TILE_SIZE != 0{
        fruit = rl.Vector2{math.floor(rand.float32()*f32(WINDOW_WIDTH)), math.floor(rand.float32()*f32(WINDOW_HEIGHT))}
    }

    rl.SetExitKey(nil)

    for !rl.WindowShouldClose(){
    
        rl.BeginDrawing()
        rl.BeginMode2D(Camera)
        if DEBUG do rl.DrawFPS(0,0)

        rl.ClearBackground(rl.Color{100,240,99,255})
            switch gs{
                case .MENU:
                    menu_loop(false)
                case .GAMEPLAY:
                    game_loop(false)
                case .PAUSED:
                    menu_loop(true)
        }

        rl.EndMode2D()
        rl.EndDrawing()
    }

    rl.CloseWindow()
}


handleKeys :: proc(){
    if (rl.IsKeyDown(.W) || rl.IsKeyDown(.UP)) && dir != .SOUTH{
        dir = .NORTH
    }
    if (rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT)) && dir != .EAST{
        dir = .WEST
    }
    if (rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN)) && dir != .NORTH{
        dir = .SOUTH
    }
    if (rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT)) && dir != .WEST{
        dir = .EAST
    }

    if rl.IsKeyDown(.ESCAPE) && gs == .GAMEPLAY{
        gs = .PAUSED
    }
}

handleMove :: proc(body: ^[dynamic]rl.Vector2, direction: Dir){
    if body[0].x < 0{
        body[0].x = f32(WINDOW_WIDTH)
    }
    if body[0].x > f32(WINDOW_WIDTH){
        body[0].x = 0
    }
    if body[0].y < 0 {
        body[0].y = f32(WINDOW_HEIGHT)
    }
    if body[0].y > f32(WINDOW_HEIGHT){
        body[0].y = 0
    }

    // update body
    for i := len(body)-1; i > 0; i -= 1{
        body[i] = body[i-1]
    }

    // update head
    switch direction{
        case .NORTH:
            body[0].y -= TILE_SIZE
        case .SOUTH:
            body[0].y += TILE_SIZE
        case .EAST:
            body[0].x += TILE_SIZE
        case .WEST:
            body[0].x -= TILE_SIZE
    }

    // debug add length
    if DEBUG{
        if rl.IsKeyDown(.SPACE){
            switch direction{
                case .NORTH:
                    append(body, body[len(body)-1] + rl.Vector2{0, TILE_SIZE})
                    fmt.println(body[len(body)-1] + rl.Vector2{0, TILE_SIZE})
                case .SOUTH:
                    append(body, body[len(body)-1] + rl.Vector2{0, -TILE_SIZE})
                    fmt.println(body[len(body)-1] + rl.Vector2{0, -TILE_SIZE})
                case .EAST:
                    append(body, body[len(body)-1] + rl.Vector2{-TILE_SIZE, 0})
                    fmt.println(body[len(body)-1] + rl.Vector2{-TILE_SIZE, 0})
                case .WEST:
                    append(body, body[len(body)-1] + rl.Vector2{TILE_SIZE, 0})
                    fmt.println(body[len(body)-1] + rl.Vector2{TILE_SIZE, 0})
            }
        }
    }
}

check_health :: proc(){
    if DEBUG{
        if rl.IsKeyDown(.BACKSPACE){
            alive = false
        }
    }
    for t in 1..<len(tail){
        if tail[0] == tail[t]{
            alive = false
            gs = .MENU
        }
    }

    if tail[0] == fruit{
        switch dir{
            case .NORTH:
                append(&tail, tail[len(tail)-1] + rl.Vector2{0, TILE_SIZE})
                // fmt.println(body[len(body)-1] + rl.Vector2{0, TILE_SIZE})
            case .SOUTH:
                append(&tail, tail[len(tail)-1] + rl.Vector2{0, -TILE_SIZE})
                // fmt.println(body[len(body)-1] + rl.Vector2{0, -TILE_SIZE})
            case .EAST:
                append(&tail, tail[len(tail)-1] + rl.Vector2{-TILE_SIZE, 0})
                // fmt.println(body[len(body)-1] + rl.Vector2{-TILE_SIZE, 0})
            case .WEST:
                append(&tail, tail[len(tail)-1] + rl.Vector2{TILE_SIZE, 0})
                // fmt.println(body[len(body)-1] + rl.Vector2{TILE_SIZE, 0})
        }

        fruit = rl.Vector2{math.floor(rand.float32()*f32(WINDOW_WIDTH)), math.floor(rand.float32()*f32(WINDOW_HEIGHT))}

        for contains(tail, fruit) || int(fruit.x) % TILE_SIZE != 0 || int(fruit.y) % TILE_SIZE != 0{
            fruit = rl.Vector2{math.floor(rand.float32()*f32(WINDOW_WIDTH)), math.floor(rand.float32()*f32(WINDOW_HEIGHT))}
        }
    }
}

game_loop :: proc(paused: bool){
    dt = rl.GetFrameTime()
    move_timer += dt
    
    // draw head
    {
        x:= i32(tail[0].x)
        y:= i32(tail[0].y)
        rl.DrawRectangle(x, y, TILE_SIZE, TILE_SIZE, rl.RED)
    }
    // draw body
    for i := 1; i < len(tail); i+=1{
        x := i32(tail[i].x)
        y := i32(tail[i].y)
        rl.DrawRectangle(x, y, TILE_SIZE, TILE_SIZE, rl.Color{ 25, 200, 48, 255 })
    }

    // draw fruit
    rl.DrawRectangle(c.int(fruit.x), c.int(fruit.y), TILE_SIZE, TILE_SIZE, rl.PURPLE)

    if !alive && DEBUG{
        if rl.IsKeyDown(.R){
            clear(&tail)
            append(&tail, rl.Vector2{1280.0/2.0, 720.0/2.0})
            // tail[0] = rl.Vector2{1280.0/2.0, 720.0/2.0}
            dir = .SOUTH
            alive = true
        }
        return
    }

    handleKeys()
    if move_timer >= 0.1 && !paused{
        move_timer = 0.0
        handleMove(&tail, dir)
        check_health()
    }
    
    // if DEBUG{
    //     fmt.println(tail)
    // }
}

menu_loop :: proc(paused: bool){
    game_loop(true)

    menu_width := (WINDOW_WIDTH/3)
    menu_height := c.int(f32(WINDOW_HEIGHT)*f32(0.8))
    button_width := (WINDOW_WIDTH/3)
    button_height := c.int(f32(WINDOW_HEIGHT)*f32(0.2))

    // menu box
    rl.DrawRectangle((WINDOW_WIDTH/2)-(WINDOW_WIDTH/6), c.int(f32(WINDOW_HEIGHT)*f32(0.1)), menu_width, menu_height, rl.Color{10,10,10,100})

    rl.DrawText("Snek", (WINDOW_WIDTH/2)-(WINDOW_WIDTH/12), c.int(f32(WINDOW_HEIGHT)*f32(0.2)), 100, rl.WHITE)

    // play?
    rl.DrawRectangle((WINDOW_WIDTH/2)-(WINDOW_WIDTH/6), c.int(f32(WINDOW_HEIGHT)*f32(0.4)), button_width, button_height, rl.Color{20,20,20,160})
    rl.DrawText("Play", (WINDOW_WIDTH/2)-(WINDOW_WIDTH/18), c.int(f32(WINDOW_HEIGHT)*f32(0.45)), 75, rl.WHITE)
    if rl.IsMouseButtonPressed(.LEFT){
        if (WINDOW_WIDTH/2)-(WINDOW_WIDTH/6) <= rl.GetMouseX() && rl.GetMouseX() <= (WINDOW_WIDTH/2)-(WINDOW_WIDTH/6)+button_width && c.int(f32(WINDOW_HEIGHT)*f32(0.4)) <= rl.GetMouseY() && rl.GetMouseY() <= c.int(f32(WINDOW_HEIGHT)*f32(0.4))+button_height{
            if paused{
                gs = .GAMEPLAY
            }
            if !paused{
                setup()
            }
        }
    }

    // exit
    rl.DrawRectangle((WINDOW_WIDTH/2)-(WINDOW_WIDTH/6), c.int(math.ceil(f32(WINDOW_HEIGHT)*f32(0.7))), button_width, button_height, rl.Color{20,20,20,160})
    rl.DrawText("Exit", (WINDOW_WIDTH/2)-(WINDOW_WIDTH/18), c.int(f32(WINDOW_HEIGHT)*f32(0.75)), 75, rl.WHITE)
    if rl.IsMouseButtonPressed(.LEFT){
        if (WINDOW_WIDTH/2)-(WINDOW_WIDTH/6) <= rl.GetMouseX() && rl.GetMouseX() <= (WINDOW_WIDTH/2)-(WINDOW_WIDTH/6)+button_width && c.int(math.ceil(f32(WINDOW_HEIGHT)*f32(0.7))) <= rl.GetMouseY() && rl.GetMouseY() <= c.int(math.ceil(f32(WINDOW_HEIGHT)*f32(0.7)))+button_height{
            rl.CloseWindow()
            os.exit(0)
        }
    }

}

setup :: proc(){
        // game init
        tail = make([dynamic]rl.Vector2, 0, WINDOW_WIDTH*WINDOW_HEIGHT/TILE_SIZE)
        dir = .SOUTH
        alive = true
        clear(&tail)
        append(&tail, rl.Vector2{1280.0/2.0, 720.0/2.0})
        gs = .GAMEPLAY
}

contains :: proc(array: $T/[dynamic]$E, val: E) -> bool{
    for i in array{
        if i == val do return true
    }
    return false
}