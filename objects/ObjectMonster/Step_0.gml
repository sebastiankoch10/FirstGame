 if (instance_exists(ObjectPlayer)) {
    // Spielerposition abrufen
    var target_x = ObjectPlayer.x;
    var target_y = ObjectPlayer.y;

    // In Richtung des Spielers bewegen
    move_towards_point(target_x, target_y, speed);
}

// Monster stirbt, wenn HP <= 0
if (hp <= 0) {
  
    // Münze erstellen
    var coin = instance_create_layer(x, y, "Instances", ObjectCoin);

    // Monster zerstören
    instance_destroy();
}

// === Sanfte Abstoßung von anderen Monstern ===
var separation_strength = 0.5;  // Stärke des Zurückstoßens (je kleiner, desto weicher)
var min_distance = 40;          // Ab wann sie sich abstoßen (in Pixel)

with (ObjectMonster) {
    if (id != other.id) {
        var dx = other.x - x;
        var dy = other.y - y;
        var dist = point_distance(other.x, other.y, x, y);

        if (dist < min_distance && dist > 0) {
            var push = (min_distance - dist) / min_distance * separation_strength;
            other.x += dx / dist * push;
            other.y += dy / dist * push;
        }
    }
}
