/// Step Event for ObjectController

// Safety: Hover-Index immer initialisiert halten
if (is_undefined(global._ui_hover_index)) global._ui_hover_index = -1;

// === PAUSE & ZAUBERAUSWAHL ===
if (global.game_paused) {
    if (!global.pause_initialized) {
        global.pause_initialized = true;
        instance_deactivate_all(true);
        instance_activate_object(ObjectController);
        instance_activate_layer("GUI");
    }

    if (global.chest_collected || global.levelup_active) {
        if (array_length(global.spell_options) == 0) {
            show_debug_message("WARNUNG: Keine Spell-Optionen vorhanden!");
        }

        // --- Tastatur-Navigation (optional) ---
        if (keyboard_check_pressed(vk_up)) {
            global.selected_spell_index =
                (global.selected_spell_index - 1 + array_length(global.spell_options)) % array_length(global.spell_options);
        }
        if (keyboard_check_pressed(vk_down)) {
            global.selected_spell_index =
                (global.selected_spell_index + 1) % array_length(global.spell_options);
        }

        // --- Maus-Hover übernehmen (vom Draw berechnet) ---
        if (global._ui_hover_index >= 0) {
            global.selected_spell_index = global._ui_hover_index;
        }

        // --- Auswahl bestätigen (Space ODER Linksklick) ---
        var confirm = keyboard_check_pressed(vk_space) || mouse_check_button_pressed(mb_left);

		if (confirm) {
    if (array_length(global.spell_options) > 0) {
        var selected_spell = global.spell_options[global.selected_spell_index];

        // --- Name/Typ aus ID erzwingen, wenn möglich ---
        if (is_struct(selected_spell)) {
            var sid_norm = undefined;
            var rt_norm  = undefined;

            // id bevorzugt
            if (variable_struct_exists(selected_spell, "id") && is_real(selected_spell.id)) {
                sid_norm = selected_spell.id;
            } else if (variable_struct_exists(selected_spell, "name") && is_real(selected_spell.name)) {
                // 'name' ist Zahl -> als id interpretieren
                sid_norm = selected_spell.name;
            }

            if (!is_undefined(sid_norm)) {
                rt_norm = GetSpellData(sid_norm);
                if (is_struct(rt_norm)) {
                    selected_spell.name = string(rt_norm.name); // String-Name erzwingen
                    selected_spell.type = (rt_norm.type == SPELL_TYPE.PASSIVE) ? "passive" : "active";
                    if (!variable_struct_exists(selected_spell, "cooldown") && !is_undefined(rt_norm.cooldown)) {
                        selected_spell.cooldown = rt_norm.cooldown;
                    }
                }
            } else {
                // Falls doch string, sicherstellen, dass es wirklich ein String ist
                if (variable_struct_exists(selected_spell, "name")) {
                    selected_spell.name = string(selected_spell.name);
                }
                if (!variable_struct_exists(selected_spell, "type") || !is_string(selected_spell.type)) {
                    var _sid2 = name_to_spell_id(selected_spell.name);
                    var _rt2  = is_undefined(_sid2) ? undefined : GetSpellData(_sid2);
                    selected_spell.type = (is_struct(_rt2) && _rt2.type == SPELL_TYPE.PASSIVE) ? "passive" : "active";
                }
            }
        }

        show_debug_message("Ausgewählter Zauber: " + selected_spell.name + ", Typ: " + selected_spell.type);

        if (selected_spell.type != "info") {
            if (is_undefined(global.active_spells))  global.active_spells  = [];
            if (is_undefined(global.passive_spells)) global.passive_spells = [];

            var spell_list = (selected_spell.type == "active") ? global.active_spells : global.passive_spells;
            var max_spells = 6;
            var found = false;

            // Leveln / hinzufügen (Vergleich über String-Namen)
            for (var i = 0; i < array_length(spell_list); i++) {
                if (is_struct(spell_list[i]) && variable_struct_exists(spell_list[i], "name")) {
                    if (string(spell_list[i].name) == selected_spell.name) {
                        if (!variable_struct_exists(spell_list[i], "level")) spell_list[i].level = 1;
                        if (spell_list[i].level < 9) {
                            spell_list[i].level += 1;
                            show_debug_message("Zauberlevel erhöht auf " + string(spell_list[i].level));
                        } else {
                            show_debug_message("Zauber ist bereits auf Level 9.");
                        }
                        found = true;
                        break;
                    }
                }
            }

            if (!found && array_length(spell_list) < max_spells) {
                selected_spell.level = 1;
                array_push(spell_list, selected_spell);
                show_debug_message("Neuer Zauber hinzugefügt zu " + selected_spell.type);
                if (selected_spell.type == "active") {
                    global.active_spells = spell_list;
                } else {
                    global.passive_spells = spell_list;
                }
            }
        }

        // Zustand zurücksetzen
        global.chest_collected = false;
        global.levelup_active  = false;
        global.game_paused     = false;
        instance_activate_all();
        global.pause_initialized = false;
        global._ui_hover_index = -1;

        show_debug_message("Auswahl abgeschlossen und Zustand zurückgesetzt.");
    }
    return; // nach Auswahl-Processing Step beenden
}


        return; // solange Auswahl ansteht, restlichen Step nicht ausführen
    }
}

// === MAINTENANCE: COOLDOWNS & PASSIVES PFLEGEN ===
var pl = (variable_global_exists("player")) ? global.player : noone;
if (instance_exists(pl)) {
    if (!is_undefined(pl.cooldown_map)) {
        var _keys = ds_map_keys(pl.cooldown_map);
        var _cnt  = array_length(_keys);
        for (var ci = 0; ci < _cnt; ci++) {
            var k = _keys[ci];
            var v = ds_map_find_value(pl.cooldown_map, k);
            v = max(0, v - 1);
            ds_map_replace(pl.cooldown_map, k, v);
        }
    }
    apply_passives(pl);
}

// === AUTOSPELL CASTING ===
if (is_undefined(global.active_spells)) global.active_spells = [];
for (var i2 = 0; i2 < array_length(global.active_spells); i2++) {
    var s = global.active_spells[i2];
    if (!is_struct(s)) continue;
    if (!variable_struct_exists(s, "name"))     continue;
    if (!variable_struct_exists(s, "cooldown")) continue;

    if (!variable_struct_exists(s, "cooldown_timer")) s.cooldown_timer = 0;

    if (s.cooldown_timer > 0) {
        s.cooldown_timer = max(0, s.cooldown_timer - 1);
    } else {
        show_debug_message("Zauber gewirkt: " + s.name);
        cast_spell(s);
        s.cooldown_timer = s.cooldown;
    }
}

// === LEVEL-UP CHECK ===
if (global.coins >= global.coins_needed) {
    show_debug_message("Münzen: " + string(global.coins) + ", Nötig: " + string(global.coins_needed));
    global.current_level += 1;

    var base = 10;
    var multiplier = 1.7;
    global.coins_needed = ceil(base * power(multiplier, global.current_level - 1));

    show_debug_message("Level-Up! Neues Level: " + string(global.current_level) +
                       ", Nächste Münzen benötigt: " + string(global.coins_needed));

    global.levelup_active = true;
    global.game_paused = true;
    handle_chest_selection("levelup");
    show_debug_message("Level-Up Auswahl gestartet.");
}
