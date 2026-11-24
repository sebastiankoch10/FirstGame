/// ObjectController: Alarm[0]
// Player referenzieren
if (!instance_exists(global.player)) {
    var p = instance_find(ObjectPlayer, 0);
    if (p != noone) global.player = p;
}

// Player initialisieren, ohne bestehende Werte zu überschreiben
if (instance_exists(global.player)) {
    var pl = global.player;

    if (!variable_instance_exists(pl, "player_power")) pl.player_power = 0;
    if (!variable_instance_exists(pl, "level"))     pl.level     = 1;
    if (!variable_instance_exists(pl, "mana"))      pl.mana      = 100;
    if (!variable_instance_exists(pl, "moveSpeed")) pl.moveSpeed = 3;

    // Passives anwenden/aktualisieren (Schild spawnen etc.)
    apply_passives(pl);
}
