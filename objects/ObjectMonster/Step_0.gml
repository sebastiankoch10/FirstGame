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

