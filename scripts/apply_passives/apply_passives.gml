/// @func apply_passives(player)
/// @desc Passive anwenden/aktualisieren (idempotent)
function apply_passives(_player)
{
    if (!instance_exists(_player)) return;
    if (is_undefined(_player.learned_passives)) return;
    var list = _player.learned_passives;

    if (is_undefined(_player._passive_applied)) {
        _player._passive_applied = ds_map_create();
    }

    var need_shield   = false;
    var shield_cfg    = undefined; // Runtime-Struct des Schild-Passivs
    var add_power_sum = 0;
    var add_spd_sum   = 0;

    var n = array_length(list);
    for (var i = 0; i < n; i++) {
        var spell_id = list[i];
        var data = GetSpellData(spell_id);
        if (!is_struct(data)) continue;
        if (data.type != SPELL_TYPE.PASSIVE) continue;

        switch (spell_id) {
            case SPELL.SHIELD:
                need_shield = true;
                shield_cfg  = data;
                break;

            case SPELL.POWER_UP:
                add_power_sum += data.add_power;
                break;

            case SPELL.MOVE_SPEED:
                add_spd_sum += data.add_move_speed;
                break;
        }
    }

    // Einmalige Additionen
    if (add_power_sum != 0 && !ds_map_exists(_player._passive_applied, "POWER_UP")) {
        _player.power = (variable_instance_exists(_player, "power") ? _player.power : 0) + add_power_sum;
        ds_map_set(_player._passive_applied, "POWER_UP", true);
    }
    if (add_spd_sum != 0 && !ds_map_exists(_player._passive_applied, "MOVE_SPEED")) {
        _player.moveSpeed = (variable_instance_exists(_player, "moveSpeed") ? _player.moveSpeed : 0) + add_spd_sum;
        ds_map_set(_player._passive_applied, "MOVE_SPEED", true);
    }

    // ---- Schild(e) managen ----
    // Ziel-Objekt per Name (oder direkter Referenz) ermitteln
    var sh_obj = noone;
    if (is_struct(shield_cfg)) {
        if (!is_undefined(shield_cfg.shield_object) && shield_cfg.shield_object != noone) {
            // Falls du irgendwo direkt eine Objekt-Referenz setzen willst
            sh_obj = shield_cfg.shield_object;
        } else if (!is_undefined(shield_cfg.shield_object_name)) {
            var idx = asset_get_index(shield_cfg.shield_object_name);
            if (idx != -1) sh_obj = idx;
        }
    }

    if (need_shield && sh_obj != noone) {
        // existierende Schilde dieses Typs zählen (die diesem Player gehören)
        var existing = 0;
        var cnt = instance_number(sh_obj);
        for (var ii = 0; ii < cnt; ii++) {
            var inst = instance_find(sh_obj, ii);
            if (instance_exists(inst) && inst.owner == _player) {
                existing += 1;
            }
        }

        var want = shield_cfg.shield_count;
        for (var s = existing; s < want; s++) {
            var sh = instance_create_layer(_player.x, _player.y, "Instances", sh_obj);
            sh.owner       = _player;
            sh.radius      = shield_cfg.shield_radius;
            sh.orbit_speed = shield_cfg.shield_speed;
            sh.damage      = shield_cfg.shield_damage;
            sh.orbit_angle = (360 / max(1, want)) * s;
        }
    } else {
        // alle Schilde dieses Typs, die dem Player gehören, entfernen
        if (sh_obj != noone) {
            var cnt2 = instance_number(sh_obj);
            for (var jj = cnt2 - 1; jj >= 0; jj--) {
                var inst2 = instance_find(sh_obj, jj);
                if (instance_exists(inst2) && inst2.owner == _player) {
                    with (inst2) instance_destroy();
                }
            }
        }
    }
}
