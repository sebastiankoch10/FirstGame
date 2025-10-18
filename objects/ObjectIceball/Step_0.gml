/// ObjectIceBall: Step
// Bewegung
x += lengthdir_x(speed, direction);
y += lengthdir_y(speed, direction);

// Out-of-bounds kill
if (x < 0 || x > room_width || y < 0 || y > room_height) {
    instance_destroy();
    exit;
}

// Kollision mit Monster (analog zu Fireball)
if (place_meeting(x, y, ObjectMonster)) {
    var m = instance_place(x, y, ObjectMonster);
    if (instance_exists(m)) {
        if (variable_instance_exists(m, "hp")) m.hp -= damage;

        // Slow-Effekt (falls per Spawner gesetzt)
        if (variable_instance_exists(self, "slow_on_hit") && slow_on_hit) {
            m.slow_time   = slow_time;   // z. B. 60 Frames
            m.slow_factor = slow_factor; // z. B. 0.5
        }
    }
    instance_destroy();
}
