 if (global.game_paused) return; // Bei Pause nichts tun

spawn_timer -= 1;

if (spawn_timer <= 0) {
    // Zufällige Position am Rand des Kamera-Sichtfelds
    var cam_x = camera_get_view_x(view_camera[0]);
    var cam_y = camera_get_view_y(view_camera[0]);
    var cam_w = camera_get_view_width(view_camera[0]);
    var cam_h = camera_get_view_height(view_camera[0]);

    var side = choose(0, 1, 2, 3);
    var spawn_x = (side == 0 || side == 2) ? irandom_range(cam_x, cam_x + cam_w) : (side == 1 ? cam_x + cam_w : cam_x);
    var spawn_y = (side == 1 || side == 3) ? irandom_range(cam_y, cam_y + cam_h) : (side == 0 ? cam_y : cam_y + cam_h);

    spawn_monster(spawn_x, spawn_y);

    // Zeit in Sekunden seit Spielstart
    var elapsed = (current_time - global.start_time) div 1000;

    // Boss-Spawn nach festen Zeitpunkten (einmalig)
    if (global.boss_index < array_length(global.boss_spawn_times)) {
        var next_spawn = global.boss_spawn_times[global.boss_index];
        if (elapsed >= next_spawn && !instance_exists(ObjectBossMonster)) {
            spawn_boss();
            global.boss_index += 1;
        }
    }

    // Gegner skalieren mit Zeit
    var minutes = elapsed div 60;
    global.monster_hp_multiplier = 1 + (minutes * 0.2);
    global.monster_damage_multiplier = 1 + (minutes * 0.1);

    spawn_timer = spawn_interval;
}

// === FUNKTIONEN ===

function spawn_monster(x, y) {
    var m = instance_create_layer(x, y, "Instances", ObjectMonster);
    if (instance_exists(m)) {
        m.max_hp = 100 * global.monster_hp_multiplier;
        m.hp = m.max_hp;
        m.damage = 10 * global.monster_damage_multiplier;
    }
}

function spawn_boss() {
    var boss_x = irandom_range(100, room_width - 100);
    var boss_y = irandom_range(100, room_height - 100);
    var b = instance_create_layer(boss_x, boss_y, "Instances", ObjectBossMonster);

    if (instance_exists(b)) {
        b.max_hp = 1000 * global.monster_hp_multiplier;
        b.hp = b.max_hp;
        b.damage = 50 * global.monster_damage_multiplier;
        global.boss_exists = true;
        show_debug_message("Bossmonster gespawnt bei X: " + string(boss_x) + ", Y: " + string(boss_y));
    }
}
