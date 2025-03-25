/// @description Executes a spell
function cast_spell(spell) {
    if (!is_struct(spell)) {
        show_debug_message("Fehler: Ungültiger Zauber!");
        return;
    }
    
    // Hol die Daten des Zaubers
    var spell_data = scr_get_spell_data(spell.name);
    if (spell_data == undefined) {
        //show_debug_message("Fehler: Spell-Daten nicht gefunden für: " + spell.name);
        return;
    }
    
    // Spielerposition holen
    var player = instance_find(ObjectPlayer, 0); // Finde den Spieler
    if (!instance_exists(player)) {
        show_debug_message("Fehler: Kein Spieler vorhanden!");
        return;
    }

    switch (spell.name) {
        case "Feuerball":
            // Feuerball erstellen und Eigenschaften setzen
            var fireball = instance_create_layer(player.x, player.y, "instances", ObjectFireball);
            fireball.direction = player.image_angle; // Spielerblickrichtung
            fireball.damage = spell_data.damage;    // Skalierter Schaden
            fireball.speed = spell_data.speed;      // Geschwindigkeit des Feuerballs
            fireball.owner = player.id;             // Referenz auf den Spieler
            show_debug_message("Feuerball gewirkt: Schaden = " + string(fireball.damage) + ", Richtung = " + string(fireball.direction));
            break;
        
        default:
            show_debug_message("Zauber nicht implementiert: " + spell.name);
    }
}
