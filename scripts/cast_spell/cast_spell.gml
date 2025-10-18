/// @func cast_spell(spell_struct)
/// @desc Wirkt einen aktiven Zauber aus deinem Pool (struct mit .name etc.)
function cast_spell(_spell_struct)
{
    if (!is_struct(_spell_struct)) return false;

    var caster = (variable_global_exists("player")) ? global.player : noone;
    if (!instance_exists(caster)) return false;
    var ang = (variable_instance_exists(caster, "aim_angle")) ? caster.aim_angle : 0;

    var spell_id = name_to_spell_id(_spell_struct.name);
    if (is_undefined(spell_id)) return false;

    var data = GetSpellData(spell_id);
    if (!is_struct(data)) return false;
    if (data.type != SPELL_TYPE.ACTIVE) return false;

    // Mana / Cooldown
    if (variable_instance_exists(caster, "mana")) {
        if (caster.mana < data.mana_cost) return false;
    }
    if (is_undefined(caster.cooldown_map)) caster.cooldown_map = ds_map_create();
    var key = string(spell_id);
    if (ds_map_exists(caster.cooldown_map, key)) {
        var cd = ds_map_find_value(caster.cooldown_map, key);
        if (cd > 0) return false;
    }

    // Schaden
    var base = data.base_damage;
    var pow  = variable_instance_exists(caster, "power") ? caster.power : 0;
    var lvl  = variable_instance_exists(caster, "level") ? caster.level : 1;

    var pow_scale = (is_struct(data.scaling) && !is_undefined(data.scaling.power)) ? data.scaling.power : 0;
    var lvl_scale = (is_struct(data.scaling) && !is_undefined(data.scaling.level)) ? data.scaling.level : 0;

    var dmg = base + pow * pow_scale + (max(1, lvl) - 1) * lvl_scale;

    // ----- Objekt-Ressource robust ermitteln -----
    var proj_obj = noone;

    if (!is_undefined(data.projectile_object) && data.projectile_object != noone) {
        // falls du irgendwann doch eine direkte Objekt-Referenz einträgst
        proj_obj = data.projectile_object;
    } else if (!is_undefined(data.projectile_object_name)) {
        var idx = asset_get_index(data.projectile_object_name);
        if (idx != -1) proj_obj = idx; // erfolgreich aufgelöst
    }

    if (proj_obj == noone) {
        show_debug_message("cast_spell: Projektil-Objekt nicht gefunden für " + string(_spell_struct.name));
        return false;
    }

    // Spawn & Instanz
    var dist = data.spawn_offset;
    var sx = caster.x + lengthdir_x(dist, ang);
    var sy = caster.y + lengthdir_y(dist, ang);

    var proj = instance_create_layer(sx, sy, "Instances", proj_obj);
    proj.direction   = ang;
    proj.speed       = data.projectile_speed;
    proj.image_angle = ang;
    proj.lifetime    = data.projectile_lifetime;
    proj.damage      = dmg;
    proj.owner       = caster;

    if (data.ignite) {
        proj.ignite      = true;
        proj.ignite_dps  = data.ignite_dps;
        proj.ignite_time = data.ignite_time;
    }
    if (data.slow_on_hit) {
        proj.slow_on_hit = true;
        proj.slow_factor = data.slow_factor;
        proj.slow_time   = data.slow_time;
    }

    // Kosten & Cooldown
    if (variable_instance_exists(caster, "mana")) {
        caster.mana = max(0, caster.mana - data.mana_cost);
    }
    ds_map_replace(caster.cooldown_map, key, data.cooldown);

    return true;
}
