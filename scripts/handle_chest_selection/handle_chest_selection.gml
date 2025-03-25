/// @description Generiert Zauberoptionen (Truhe oder Level-Up)
/// @param source_type: Gibt an, woher die Auswahl kommt ("chest" oder "levelup")
function handle_chest_selection(source_type) {
    global.spell_options = []; // Leere Liste für Zauberoptionen
    var max_active = 6; // Maximale aktive Zauber
    var max_passive = 6; // Maximale passive Zauber
    
    // Zähle die vorhandenen aktiven und passiven Zauber
    var active_count = array_length(global.active_spells);
    var passive_count = array_length(global.passive_spells);

    // Debugging: Zeige aktuellen Stand der Zauber
    show_debug_message("Aktive Zauber: " + string(active_count) + " / " + string(max_active));
    show_debug_message("Passive Zauber: " + string(passive_count) + " / " + string(max_passive));
    
    // Zauberoptionen generieren
    while (array_length(global.spell_options) < 3) {
        var random_spell = global.abilities_pool[irandom(array_length(global.abilities_pool) - 1)];

        // Prüfen, ob der Zauber gültig ist
        if (!is_struct(random_spell)) continue;
        if (!variable_struct_exists(random_spell, "name") || !variable_struct_exists(random_spell, "type")) continue;

        // Prüfen, ob der Zauber hinzugefügt werden darf (Limit prüfen)
        if (random_spell.type == "active" && active_count >= max_active) continue;
        if (random_spell.type == "passive" && passive_count >= max_passive) continue;

        // Verhindere Duplikate in der Auswahl
        if (!array_contains(global.spell_options, random_spell)) {
            array_push(global.spell_options, random_spell);
        }
    }

    // Initialisiere Auswahlindex
    global.selected_spell_index = 0;

    // Debugging: Zeige die generierten Optionen
    for (var i = 0; i < array_length(global.spell_options); i++) {
        var spell = global.spell_options[i];
        show_debug_message(source_type + " Option " + string(i) + ": Name = " + spell.name + ", Typ = " + spell.type);
    }
    
    // Spiel pausieren, um die Auswahl anzuzeigen
    global.game_paused = true;

    // Zustand je nach Quelle setzen
    if (source_type == "levelup") {
        global.levelup_active = true; // Level-Up Auswahl aktivieren
    } else if (source_type == "chest") {
        global.chest_collected = true; // Truhen-Auswahl aktivieren
    }
}
