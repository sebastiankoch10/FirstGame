/// Step Event von ObjectBossMonster

if (instance_exists(ObjectPlayer)) {
    // Spielerposition abrufen
    var target_x = ObjectPlayer.x;
    var target_y = ObjectPlayer.y;

    // In Richtung des Spielers bewegen
    move_towards_point(target_x, target_y, speed);
}

// Bossmonster stirbt, wenn HP <= 0
if (hp <= 0) {
    // Prüfen, ob die Truhe noch nicht erstellt wurde
    if (!variable_instance_exists(self, "chest_spawned")) {
        chest_spawned = true; // Markieren, dass die Truhe gespawnt wurde

        // Schatztruhe erstellen
        var chest = instance_create_layer(x, y, "Instances", ObjectChest);

 

        // Boss-Existenz-Flag zurücksetzen
        global.boss_exists = false;

        
    }

    // Bossmonster zerstören (wird einmalig ausgeführt)
    instance_destroy();
    show_debug_message("Bossmonster wurde zerstört.");
}
