/// @func GetSpellData(arg1, [level])
/// @desc Dual: (id) => Runtime-Daten | (name, level) => UI-Vorschau

function GetSpellData(_a, _level)
{
    // -----------------------------
    // UI-VORSCHAU: (name, level)
    // -----------------------------
    if (is_string(_a)) {
        var _id = name_to_spell_id(_a);
        if (is_undefined(_id)) return undefined;

        var base = GetSpellData(_id); // rekurrierend: Runtime-Struct holen
        if (!is_struct(base)) return undefined;

        var lvl = max(1, _level);

        // Felder nur lesen, wenn sie existieren (sonst 0)
        var base_dmg = 0;
        if (variable_struct_exists(base, "base_damage")) {
            base_dmg = base.base_damage;
        }
        var preview_damage = base_dmg + (lvl - 1) * (base_dmg * 0.20);

        var preview_cd = 0;
        if (variable_struct_exists(base, "cooldown")) {
            preview_cd = base.cooldown;
        }

        // Passive sauber behandeln
        var is_passive = false;
        if (variable_struct_exists(base, "type")) {
            is_passive = (base.type == SPELL_TYPE.PASSIVE);
        }

        if (is_passive) {
            // Gib nur Felder zurück, die das UI erwartet
            if (variable_struct_exists(base, "id")) {
                switch (base.id) {
                    case SPELL.SHIELD:
                        // Shield-Damage als „damage“-Preview anzeigen
                        var sh_dmg = 0;
                        if (variable_struct_exists(base, "shield_damage")) sh_dmg = base.shield_damage;
                        return { damage: sh_dmg, cooldown: 0 };
                    case SPELL.POWER_UP:
                    case SPELL.MOVE_SPEED:
                        return { damage: 0, cooldown: 0 };
                }
            }
            // Generischer Fallback
            return { damage: 0, cooldown: 0 };
        }

        // Aktive (Standard)
        return { damage: preview_damage, cooldown: preview_cd };
    }

    // -----------------------------
    // RUNTIME-DATEN: (id)
    // -----------------------------
    var _id = _a;
    switch (_id) {
        // ===== AKTIVE =====
        case SPELL.FIREBALL:
            return {
                type: SPELL_TYPE.ACTIVE,
                id: SPELL.FIREBALL,
                name: "Fireball",
                desc: "Schießt einen Feuerball nach vorn.",
                // Name als String – an deine Ressource anpassen!
                projectile_object_name: "ObjectFireball",
                projectile_speed: 11,
                projectile_lifetime: 60,
                spawn_offset: 22,
                cooldown: 20,
                mana_cost: 5,
                base_damage: 6,
                scaling: { power: 0.25, level: 0.5 },
                ignite: true,
                ignite_dps: 1,
                ignite_time: 60,

                icon_sprite: noone,
                icon_sprite_name: "spr_fireball_1"
            };

        case SPELL.ICEBALL:
            return {
                type: SPELL_TYPE.ACTIVE,
                id: SPELL.ICEBALL,
                name: "Iceball",
                desc: "Schießt einen frostigen Eisball.",
                projectile_object_name: "ObjectIceBall", // <- String!
                projectile_speed: 10,
                projectile_lifetime: 65,
                spawn_offset: 22,
                cooldown: 22,
                mana_cost: 5,
                base_damage: 5,
                scaling: { power: 0.20, level: 0.4 },
                slow_on_hit: true,
                slow_factor: 0.5,
                slow_time: 60,

                icon_sprite: noone,
                icon_sprite_name: "spr_iceball_1"
            };

        case SPELL.LIGHTNING:
            return {
                type: SPELL_TYPE.ACTIVE,
                id: SPELL.LIGHTNING,
                name: "Lightning",
                desc: "Ein schneller Blitzball.",
                projectile_object_name: "LightningBall", // <- String!
                projectile_speed: 14,
                projectile_lifetime: 50,
                spawn_offset: 22,
                cooldown: 16,
                mana_cost: 6,
                base_damage: 4,
                scaling: { power: 0.30, level: 0.4 },

                icon_sprite: noone,
                icon_sprite_name: "spr_lightning_1"
            };

        // ===== PASSIVE =====
        case SPELL.SHIELD:
            return {
                type: SPELL_TYPE.PASSIVE,
                id: SPELL.SHIELD,
                name: "Orbit Shield",
                desc: "Ein schützendes Schild kreist um den Spieler.",
                // Nur String-Name; apply_passives löst ihn mit asset_get_index auf
                shield_object_name: "ObjectShield",
                shield_count: 1,
                shield_radius: 50,
                shield_damage: 2,
                shield_speed: 4,

                icon_sprite: noone,
                icon_sprite_name: "spr_orbit_shield_1"
            };

        case SPELL.POWER_UP:
            return {
                type: SPELL_TYPE.PASSIVE,
                id: SPELL.POWER_UP,
                name: "Power Up",
                desc: "+2 Power.",
                add_power: 2,

                icon_sprite: noone,
                icon_sprite_name: "spr_power_up_1"
            };

        case SPELL.MOVE_SPEED:
            return {
                type: SPELL_TYPE.PASSIVE,
                id: SPELL.MOVE_SPEED,
                name: "Fleet Footed",
                desc: "+0.5 Bewegungsgeschwindigkeit.",
                add_move_speed: 0.5,

                icon_sprite: noone,
                icon_sprite_name: "spr_fleet_footed_1"
            };

        default:
            return undefined;
    }
}
