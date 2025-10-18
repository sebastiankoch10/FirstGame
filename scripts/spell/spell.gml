/// spell.gml
// IDs & Helper zentral

enum SPELL_TYPE {
    ACTIVE = 1,
    PASSIVE = 2
}

enum SPELL {
    // Aktive
    FIREBALL   = 101,
    ICEBALL    = 102,
    LIGHTNING  = 103,

    // Passive
    SHIELD     = 201,
    POWER_UP   = 202,
    MOVE_SPEED = 203
}

/// @func name_to_spell_id(name)
/// @desc Mappt UI-Namen auf SPELL-ID
function name_to_spell_id(_name) {
    switch (string(_name)) {
        case "Fireball":  return SPELL.FIREBALL;
        case "Iceball":
        case "IceBall":   return SPELL.ICEBALL;
        case "Lightning": return SPELL.LIGHTNING;

        case "Orbit Shield":  return SPELL.SHIELD;
        case "Power Up":      return SPELL.POWER_UP;
        case "Fleet Footed":  return SPELL.MOVE_SPEED;

        default: return undefined;
    }
}
