// Bewegung in die gesetzte Richtung
x += lengthdir_x(speed, direction);
y += lengthdir_y(speed, direction);

// Zerstören, wenn außerhalb des Raums
if (x < 0 || x > room_width || y < 0 || y > room_height) {
    instance_destroy();
    return; // Verhindert weitere Verarbeitung
}

// Kollision mit einem Monster
if (place_meeting(x, y, ObjectMonster)) {
    var hit_monster = instance_place(x, y, ObjectMonster);
    if (instance_exists(hit_monster)) {
        if (!variable_instance_exists(hit_monster, "hp")) {           
        } else {
            hit_monster.hp -= damage; // Schaden zufügen     
        }
        instance_destroy(); // Feuerball zerstören
    }
}
