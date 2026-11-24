if(global.game_paused || !instance_exists(ObjectPlayer)) exit;
// Prüfen, ob der Spieler die Truhe berührt
if (place_meeting(x, y, ObjectPlayer)) {
    // Spiel pausieren
    global.game_paused = true;

    // Aktiviere Auswahlmodus
    global.chest_collected = true;

    // Generiere Zauberoptionen für die Auswahl
    handle_chest_selection("chest");

    // Debugging: Zeige generierte Optionen
    show_debug_message("Zauberoptionen durch Truhe generiert: " + string(global.spell_options));

    // Truhe zerstören
    instance_destroy();
}


