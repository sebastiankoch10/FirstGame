/// @description Generiert Zauberoptionen (Truhe oder Level-Up)
/// @param source_type: "chest" oder "levelup"
function handle_chest_selection(source_type)
{
    if (is_undefined(global.active_spells))  global.active_spells  = [];
    if (is_undefined(global.passive_spells)) global.passive_spells = [];

    // --- Hilfsfunktionen -----------------------------------------------------

    function __runtime(_id) {
        var r = GetSpellData(_id);
        return is_struct(r) ? r : undefined;
    }

    function __get_level_by_name(_list, _name_str) {
        var n = array_length(_list);
        for (var i = 0; i < n; i++) {
            var e = _list[i];
            if (!is_struct(e)) continue;
            if (!variable_struct_exists(e, "name")) continue;
            if (string(e.name) == _name_str) {
                return (variable_struct_exists(e, "level")) ? e.level : 1;
            }
        }
        return 0;
    }

    function __already_learned_level(_id) {
        var rt = __runtime(_id);
        if (!is_struct(rt)) return 0;
        var nm = string(rt.name);
        if (rt.type == SPELL_TYPE.PASSIVE) {
            return __get_level_by_name(global.passive_spells, nm);
        } else {
            return __get_level_by_name(global.active_spells, nm);
        }
    }

    function __can_offer(_id) {
        var rt = __runtime(_id);
        if (!is_struct(rt)) return false;

        var is_passive = (rt.type == SPELL_TYPE.PASSIVE);
        var max_spells = 6;

        if (!is_passive) {
            if (__get_level_by_name(global.active_spells, string(rt.name)) == 0
                && array_length(global.active_spells) >= max_spells) return false;
        } else {
            if (__get_level_by_name(global.passive_spells, string(rt.name)) == 0
                && array_length(global.passive_spells) >= max_spells) return false;
        }

        if (__already_learned_level(_id) >= 9) return false;

        return true;
    }

    // --- Kandidatenpool ------------------------------------------------------
    var pool = [
        SPELL.FIREBALL,
        SPELL.ICEBALL,
        SPELL.LIGHTNING,
        SPELL.SHIELD,
        SPELL.POWER_UP,
        SPELL.MOVE_SPEED
    ];

    // nur erlaubte Spells
    var filtered = [];
    for (var i = 0; i < array_length(pool); i++) {
        var pid = pool[i];
        if (__can_offer(pid)) array_push(filtered, pid);
    }

    // Fallback: wenn alles rausgefiltert wurde, nimm den Grundpool
    if (array_length(filtered) == 0) {
        filtered = array_create(0);
        array_copy(filtered, 0, pool, 0, array_length(pool));
    }

    // --- 3 eindeutige Optionen ziehen ---------------------------------------
    var options = [];
    var to_pick = min(3, array_length(filtered));
    var tmp = array_create(0);
    array_copy(tmp, 0, filtered, 0, array_length(filtered));

    repeat (to_pick) {
        if (array_length(tmp) <= 0) break;
        var pick_index = irandom(array_length(tmp) - 1);
        var spell_id = tmp[pick_index];
        tmp = array_delete(tmp, pick_index, 1);

        var rt = __runtime(spell_id);
        if (!is_struct(rt)) continue;

        var learned_lvl = __already_learned_level(spell_id);

        var opt = {
            id:    spell_id,
            name:  string(rt.name),
            type:  (rt.type == SPELL_TYPE.PASSIVE) ? "passive" : "active",
            level: learned_lvl
        };
        array_push(options, opt);
    }

    // Wenn weniger als 3, auffüllen
    var guard = 0;
    while (array_length(options) < 3 && guard < 20) {
        guard++;
        var sid = pool[irandom(array_length(pool) - 1)];
        var exists = false;
        for (var k = 0; k < array_length(options); k++) {
            if (options[k].id == sid) { exists = true; break; }
        }
        if (exists) continue;

        var rt2 = __runtime(sid);
        if (!is_struct(rt2)) continue;

        var lvl2 = __already_learned_level(sid);
        var opt2 = {
            id:    sid,
            name:  string(rt2.name),
            type:  (rt2.type == SPELL_TYPE.PASSIVE) ? "passive" : "active",
            level: lvl2
        };
        array_push(options, opt2);
    }

    // --- Globale Auswahl setzen ---------------------------------------------
    global.spell_options        = options;
    global.selected_spell_index = 0;

    for (var d = 0; d < array_length(global.spell_options); d++) {
        var se = global.spell_options[d];
        show_debug_message(source_type + " Option " + string(d) + ": id=" + string(se.id)
            + " name=" + string(se.name) + " type=" + string(se.type) + " lvl=" + string(se.level));
    }

    global.game_paused = true;
    if (source_type == "levelup") {
        global.levelup_active = true;
    } else {
        global.chest_collected = true;
    }
}
