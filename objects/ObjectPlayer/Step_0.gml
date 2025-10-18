// ===================================================================
// OBJECT: Player  |  EVENT: Step
// Steuerung, Angriff, Bewegung, Blickrichtung (Maus) – mit WASD + Pfeilen
// Angriff/Hitbox via LINKER MAUSKLICK (mb_left)
// ===================================================================

// --- 1) Blickrichtung & Aim-Winkel (Sprite NICHT drehen, nur flippen)
var mx = mouse_x;
var my = mouse_y;
aim_angle   = point_direction(x, y, mx, my); // Für Skills & Hitboxen
image_angle = 0;                             // Sprite bleibt gerade
image_xscale = (mx >= x) ? 1 : -1;           // nur L/R-Flip nach Mausseite

// --- 2) Input sammeln (WASD + Pfeile)
var left_down  = keyboard_check(vk_left)  || keyboard_check(ord("A"));
var right_down = keyboard_check(vk_right) || keyboard_check(ord("D"));
var up_down    = keyboard_check(vk_up)    || keyboard_check(ord("W"));
var down_down  = keyboard_check(vk_down)  || keyboard_check(ord("S"));

// --- 3) Angriff prüfen (LINKER MAUSKLICK)
if (mouse_check_button_pressed(mb_left)) {
    if (state == player_state.attacking) {
        buffered_attack = true;
    } else {
        switch (attack_stage) {
            case 1: sprite_index = attack_sprite_1; break;
            case 2: sprite_index = attack_sprite_2; break;
            case 3: sprite_index = attack_sprite_3; break;
        }
        image_index  = 0;
        image_speed  = 1;
        state        = player_state.attacking;
        attack_timer = attack_delay;
    }
}

// --- 4) Angriffszustand überwachen + Bewegung während Angriff (halbe Speed)
if (state == player_state.attacking) {
    // Animation fertig?
    if (image_index >= sprite_get_number(sprite_index) - 1) {
        if (buffered_attack) {
            attack_stage += 1;
            if (attack_stage > 3) attack_stage = 1;
            buffered_attack = false;

            switch (attack_stage) {
                case 1: sprite_index = attack_sprite_1; break;
                case 2: sprite_index = attack_sprite_2; break;
                case 3: sprite_index = attack_sprite_3; break;
            }
            image_index = 0;
            image_speed = 1;
        } else {
            state = player_state.idle;
            attack_stage = 1;
        }
    }

    // Bewegung bei Angriff (WASD + Pfeile) – halbe Geschwindigkeit
    var reducedSpeed = moveSpeed / 2;
    if (left_down)  x -= reducedSpeed;
    if (right_down) x += reducedSpeed;
    if (up_down)    y -= reducedSpeed;
    if (down_down)  y += reducedSpeed;
}

// --- 5) Bewegung wenn NICHT im Angriff
if (state != player_state.attacking) {
    var moving = false;

    if (left_down)  { x -= moveSpeed; moving = true; }
    if (right_down) { x += moveSpeed; moving = true; }
    if (up_down)    { y -= moveSpeed; moving = true; }
    if (down_down)  { y += moveSpeed; moving = true; }

    state = moving ? player_state.running : player_state.idle;

    // Raumgrenzen
    if (x < 0) x = 0;
    if (x > room_width  - sprite_width)  x = room_width  - sprite_width;
    if (y < 0) y = 0;
    if (y > room_height - sprite_height) y = room_height - sprite_height;
}

// --- 6) Angriffstimer
if (attack_timer > 0) attack_timer -= 1;

// --- 7) Animations-Zustände
switch (state) {
    case player_state.idle:
        if (sprite_index != spr_adventurer_idle) sprite_index = spr_adventurer_idle;
        break;
    case player_state.running:
        if (sprite_index != spr_adventurer_run) sprite_index = spr_adventurer_run;
        break;
    case player_state.attacking:
        // Sprite wird im Angriffsblock gesetzt
        break;
}

// --- 8) Kamera folgt Spieler
var cam_x = x - 400; // halbe Kamerabreite
var cam_y = y - 300; // halbe Kamerahöhe
camera_set_view_pos(camera, cam_x, cam_y);

// --- 9) Hitbox-Handling (immer in Aim-Richtung, nicht über image_xscale)
// Sofort-Hitbox, wenn linker Mausklick und NICHT im Angriff
if (mouse_check_button_pressed(mb_left) && state != player_state.attacking) {
    var dist = 20;
    var hx = x + lengthdir_x(dist, aim_angle);
    var hy = y + lengthdir_y(dist, aim_angle);
    var hitbox = instance_create_layer(hx, hy, "Instances", ObjectSwordHitbox);
    hitbox.image_angle = aim_angle;
    hitbox.lifetime = 10;
}

// Im Angriff: Hitbox erzeugen (falls noch nicht vorhanden)
if (state == player_state.attacking) {
    if (!instance_exists(ObjectSwordHitbox)) {
        var distA = 20;
        var hxA = x + lengthdir_x(distA, aim_angle);
        var hyA = y + lengthdir_y(distA, aim_angle);
        var hitboxA = instance_create_layer(hxA, hyA, "Instances", ObjectSwordHitbox);
        hitboxA.image_angle = aim_angle;
    }
} else {
    with (ObjectSwordHitbox) instance_destroy();
}

// --- 10) Pause
if (global.game_paused) {
    show_debug_message("Spiel pausiert in ObjectPlayer");
    return;
}
// ===================================================================
// OBJECT: Player  |  EVENT: Step
// Steuerung, Angriff, Bewegung, Blickrichtung (Maus) – mit WASD + Pfeilen
// Angriff/Hitbox via LINKER MAUSKLICK (mb_left)
// ===================================================================

// --- 1) Blickrichtung & Aim-Winkel (Sprite NICHT drehen, nur flippen)
var mx = mouse_x;
var my = mouse_y;
aim_angle   = point_direction(x, y, mx, my); // Für Skills & Hitboxen
image_angle = 0;                             // Sprite bleibt gerade
image_xscale = (mx >= x) ? 1 : -1;           // nur L/R-Flip nach Mausseite

// --- 2) Input sammeln (WASD + Pfeile)
var left_down  = keyboard_check(vk_left)  || keyboard_check(ord("A"));
var right_down = keyboard_check(vk_right) || keyboard_check(ord("D"));
var up_down    = keyboard_check(vk_up)    || keyboard_check(ord("W"));
var down_down  = keyboard_check(vk_down)  || keyboard_check(ord("S"));

// --- 3) Angriff prüfen (LINKER MAUSKLICK)
if (mouse_check_button_pressed(mb_left)) {
    if (state == player_state.attacking) {
        buffered_attack = true;
    } else {
        switch (attack_stage) {
            case 1: sprite_index = attack_sprite_1; break;
            case 2: sprite_index = attack_sprite_2; break;
            case 3: sprite_index = attack_sprite_3; break;
        }
        image_index  = 0;
        image_speed  = 1;
        state        = player_state.attacking;
        attack_timer = attack_delay;
    }
}

// --- 4) Angriffszustand überwachen + Bewegung während Angriff (halbe Speed)
if (state == player_state.attacking) {
    // Animation fertig?
    if (image_index >= sprite_get_number(sprite_index) - 1) {
        if (buffered_attack) {
            attack_stage += 1;
            if (attack_stage > 3) attack_stage = 1;
            buffered_attack = false;

            switch (attack_stage) {
                case 1: sprite_index = attack_sprite_1; break;
                case 2: sprite_index = attack_sprite_2; break;
                case 3: sprite_index = attack_sprite_3; break;
            }
            image_index = 0;
            image_speed = 1;
        } else {
            state = player_state.idle;
            attack_stage = 1;
        }
    }

    // Bewegung bei Angriff (WASD + Pfeile) – halbe Geschwindigkeit
    var reducedSpeed = moveSpeed / 2;
    if (left_down)  x -= reducedSpeed;
    if (right_down) x += reducedSpeed;
    if (up_down)    y -= reducedSpeed;
    if (down_down)  y += reducedSpeed;
}

// --- 5) Bewegung wenn NICHT im Angriff
if (state != player_state.attacking) {
    var moving = false;

    if (left_down)  { x -= moveSpeed; moving = true; }
    if (right_down) { x += moveSpeed; moving = true; }
    if (up_down)    { y -= moveSpeed; moving = true; }
    if (down_down)  { y += moveSpeed; moving = true; }

    state = moving ? player_state.running : player_state.idle;

    // Raumgrenzen
    if (x < 0) x = 0;
    if (x > room_width  - sprite_width)  x = room_width  - sprite_width;
    if (y < 0) y = 0;
    if (y > room_height - sprite_height) y = room_height - sprite_height;
}

// --- 6) Angriffstimer
if (attack_timer > 0) attack_timer -= 1;

// --- 7) Animations-Zustände
switch (state) {
    case player_state.idle:
        if (sprite_index != spr_adventurer_idle) sprite_index = spr_adventurer_idle;
        break;
    case player_state.running:
        if (sprite_index != spr_adventurer_run) sprite_index = spr_adventurer_run;
        break;
    case player_state.attacking:
        // Sprite wird im Angriffsblock gesetzt
        break;
}

// --- 8) Kamera folgt Spieler
var cam_x = x - 400; // halbe Kamerabreite
var cam_y = y - 300; // halbe Kamerahöhe
camera_set_view_pos(camera, cam_x, cam_y);

// --- 9) Hitbox-Handling (immer in Aim-Richtung, nicht über image_xscale)
// Sofort-Hitbox, wenn linker Mausklick und NICHT im Angriff
if (mouse_check_button_pressed(mb_left) && state != player_state.attacking) {
    var dist = 20;
    var hx = x + lengthdir_x(dist, aim_angle);
    var hy = y + lengthdir_y(dist, aim_angle);
    var hitbox = instance_create_layer(hx, hy, "Instances", ObjectSwordHitbox);
    hitbox.image_angle = aim_angle;
    hitbox.lifetime = 10;
}

// Im Angriff: Hitbox erzeugen (falls noch nicht vorhanden)
if (state == player_state.attacking) {
    if (!instance_exists(ObjectSwordHitbox)) {
        var distA = 20;
        var hxA = x + lengthdir_x(distA, aim_angle);
        var hyA = y + lengthdir_y(distA, aim_angle);
        var hitboxA = instance_create_layer(hxA, hyA, "Instances", ObjectSwordHitbox);
        hitboxA.image_angle = aim_angle;
    }
} else {
    with (ObjectSwordHitbox) instance_destroy();
}

// --- 10) Pause
if (global.game_paused) {
    show_debug_message("Spiel pausiert in ObjectPlayer");
    return;
}
