/// Step Event for ObjectController



// Handle pause logic
if (global.game_paused) {
    if (!global.pause_initialized) {
        global.pause_initialized = true;
        instance_deactivate_all(true);
        instance_activate_object(ObjectController);
        instance_activate_layer("GUI");
    }

    // Handle chest selection or level-up selection logic
    if (global.chest_collected || global.levelup_active) {

        // Debug: Spell-Optionen prüfen
        if (array_length(global.spell_options) == 0) {
            show_debug_message("WARNUNG: Keine Spell-Optionen vorhanden!");
        }

        // Navigation der Zauberauswahl
        if (keyboard_check_pressed(vk_up)) {
            global.selected_spell_index = (global.selected_spell_index - 1 + array_length(global.spell_options)) % array_length(global.spell_options);
        }
        if (keyboard_check_pressed(vk_down)) {
            global.selected_spell_index = (global.selected_spell_index + 1) % array_length(global.spell_options);           
        }

        // Auswahl bestätigen
        if (keyboard_check_pressed(vk_space)) {
            if (array_length(global.spell_options) > 0) {
                var selected_spell = global.spell_options[global.selected_spell_index];
                show_debug_message("Ausgewählter Zauber: " + selected_spell.name + ", Typ: " + selected_spell.type);

                if (selected_spell.type == "active" && array_length(global.active_spells) < 6) {
                    array_push(global.active_spells, selected_spell);
                    show_debug_message("Zauber hinzugefügt zu ACTIVE.");
                } else if (selected_spell.type == "passive" && array_length(global.passive_spells) < 6) {
                    array_push(global.passive_spells, selected_spell);
                    show_debug_message("Zauber hinzugefügt zu PASSIVE.");
                } else {
                    show_debug_message("FEHLER: Zauber konnte nicht hinzugefügt werden (Limit erreicht).");
                }

                // Zurücksetzen des Zustands nach Auswahl
                global.chest_collected = false;
                global.levelup_active = false; // Reset Level-Up Zustand
                global.game_paused = false;
                instance_activate_all();
                global.pause_initialized = false;

                show_debug_message("Zauber erfolgreich ausgewählt und Zustand zurückgesetzt.");
            }
        }
        return;
    }
}

// Handle automatic spell casting
for (var i = 0; i < array_length(global.active_spells); i++) {
    var spell = global.active_spells[i];
    if (!variable_struct_exists(spell, "cooldown_timer")) spell.cooldown_timer = 0;
    if (spell.cooldown_timer > 0) {
        spell.cooldown_timer -= 1;
    } else {
        show_debug_message("Zauber gewirkt: " + spell.name);
        cast_spell(spell); // Centralized casting
        spell.cooldown_timer = spell.cooldown; // Reset cooldown
    }
}

// Prüfen, ob genug Münzen für ein Level-Up gesammelt wurden
if (global.coins >= global.coins_needed) {
    // Debug: Zeige Münzstatus
    show_debug_message("Münzen: " + string(global.coins) + ", Nötig: " + string(global.coins_needed));

    // Level-Up durchführen
    global.current_level += 1; // Level erhöhen
    global.coins -= global.coins_needed; // Münzen abziehen

    // Münzanforderung erhöhen (z.B. 1.5x für das nächste Level)
    global.coins_needed = ceil(global.coins_needed * 1.5);

    // Debugging: Zeige Level-Up-Info
    show_debug_message("Level-Up! Neues Level: " + string(global.current_level) +
                       ", Nächste Münzen benötigt: " + string(global.coins_needed));

    // Generiere Zauberoptionen für Level-Up
    global.levelup_active = true; // Setzt Level-Up aktiv
    global.game_paused = true;    // Pausiere das Spiel für die Auswahl
    handle_chest_selection("levelup"); // Generiere die Zauberoptionen
    show_debug_message("Level-Up Auswahl gestartet.");
}
