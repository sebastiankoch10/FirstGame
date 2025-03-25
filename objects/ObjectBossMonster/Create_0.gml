/// Create Event von ObjectMonster
max_hp = 100 * global.monster_hp_multiplier;
hp = max_hp;
damage = 10 * global.monster_damage_multiplier;
speed = 1; // Geschwindigkeit bleibt konstant

// Spieler-Koordinaten abrufen, falls vorhanden
if (instance_exists(ObjectPlayer)) {
    var player_x = ObjectPlayer.x;
    var player_y = ObjectPlayer.y;

    // Richtung berechnen
    var dir = point_direction(x, y, player_x, player_y);

    // Bewegungskomponenten berechnen
    var move_x = lengthdir_x(speed, dir);
    var move_y = lengthdir_y(speed, dir);

    // Bewegung anwenden
    x += move_x;
    y += move_y;
}

// Debugging
show_debug_message("Monster erstellt mit HP: " + string(hp) + "/" + string(max_hp));


