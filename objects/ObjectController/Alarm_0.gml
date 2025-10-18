/// ObjectController: Alarm[0]
// Player referenzieren
if (!instance_exists(global.player)) {
    var p = instance_find(ObjectPlayer, 0);
    if (p != noone) global.player = p;
}

// Player initialisieren, ohne bestehende Werte zu überschreiben
if (instance_exists(global.player)) {
    var pl = global.player;

    if (is_undefined(pl.learned_actives))  pl.learned_actives  = [ spell.FIREBALL, spell.ICEBALL, spell.LIGHTNING ];
    if (is_undefined(pl.learned_passives)) pl.learned_passives = [ spell.SHIELD, spell.POWER_UP, spell.MOVE_SPEED ];

    if (is_undefined(pl.cooldown_map)) pl.cooldown_map = ds_map_create();
    if (!variable_instance_exists(pl, "power"))     pl.power     = 0;
    if (!variable_instance_exists(pl, "level"))     pl.level     = 1;
    if (!variable_instance_exists(pl, "mana"))      pl.mana      = 100;
    if (!variable_instance_exists(pl, "moveSpeed")) pl.moveSpeed = 3;

    // Passives anwenden/aktualisieren (Schild spawnen etc.)
    apply_passives(pl);
}
