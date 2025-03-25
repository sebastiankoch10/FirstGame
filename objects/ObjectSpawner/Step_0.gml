spawn_timer -= 1; // Timer herunterzählen

if (spawn_timer <= 0) {
    // Kamera-Position ermitteln
    var cam_x = camera_get_view_x(view_camera[0]);
    var cam_y = camera_get_view_y(view_camera[0]);
    var cam_width = camera_get_view_width(view_camera[0]);
    var cam_height = camera_get_view_height(view_camera[0]);

    // Zufällige Seite der Kamera wählen
    var spawn_x, spawn_y;
    var side = choose(0, 1, 2, 3); // 0 = oben, 1 = rechts, 2 = unten, 3 = links

    switch (side) {
        case 0: // Oben
            spawn_x = irandom_range(cam_x, cam_x + cam_width); // Innerhalb der Breite
            spawn_y = cam_y; // Am oberen Rand
            break;

        case 1: // Rechts
            spawn_x = cam_x + cam_width; // Am rechten Rand
            spawn_y = irandom_range(cam_y, cam_y + cam_height); // Innerhalb der Höhe
            break;

        case 2: // Unten
            spawn_x = irandom_range(cam_x, cam_x + cam_width); // Innerhalb der Breite
            spawn_y = cam_y + cam_height; // Am unteren Rand
            break;

        case 3: // Links
            spawn_x = cam_x; // Am linken Rand
            spawn_y = irandom_range(cam_y, cam_y + cam_height); // Innerhalb der Höhe
            break;
    }

    // Monster erstellen
    spawn_monster(spawn_x, spawn_y);

    // Überprüfen, ob genug Zeit vergangen ist (z. B. 60 Sekunden nach Start)
    var elapsed_time = (current_time - global.start_time) div 1000; // Zeit in Sekunden

    // Alle 60 Sekunden ein Bossmonster spawnen
    if (elapsed_time > 0 && elapsed_time % 2 == 0) { // Jede 60. Sekunde
        if (!instance_exists(ObjectBossMonster)) {
            spawn_boss();
        }
    }

    // Dynamische Skalierung basierend auf der Zeit
    var elapsed_minutes = elapsed_time div 60; // Zeit in Minuten
    global.monster_hp_multiplier = 1 + (elapsed_minutes * 0.2); // HP steigt jede Minute um 20%
    global.monster_damage_multiplier = 1 + (elapsed_minutes * 0.1); // Schaden steigt jede Minute um 10%

  
    // Timer zurücksetzen
    spawn_timer = spawn_interval;
}

/// Funktion zum Erstellen eines normalen Monsters
function spawn_monster(spawn_x, spawn_y) {
    var monster = instance_create_layer(spawn_x, spawn_y, "Instances", ObjectMonster);
    if (instance_exists(monster)) {
        monster.max_hp = 100 * global.monster_hp_multiplier;
        monster.hp = monster.max_hp;
        monster.damage = 10 * global.monster_damage_multiplier;

       
                          
	}
}

/// Funktion zum Erstellen eines Bossmonsters
function spawn_boss() {
    var boss_x = irandom_range(100, room_width - 100);
    var boss_y = irandom_range(100, room_height - 100);

    var boss = instance_create_layer(boss_x, boss_y, "Instances", ObjectBossMonster);
    if (instance_exists(boss)) {
        boss.max_hp = 1000 * global.monster_hp_multiplier;
        boss.hp = boss.max_hp;
        boss.damage = 50 * global.monster_damage_multiplier;

        global.boss_exists = true; // Flag setzen, dass ein Boss existiert

        show_debug_message("Bossmonster erstellt bei X: " + string(boss_x) + ", Y: " + string(boss_y) +
                           " mit HP: " + string(boss.hp) + ", Schaden: " + string(boss.damage));
    } else {
        show_debug_message("Fehler beim Erstellen des Bossmonsters!");
    }
}

if (global.game_paused) {
    return; // Keine Bewegung oder Aktionen, wenn pausiert
}