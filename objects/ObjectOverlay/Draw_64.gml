/// ObjectOverlay: Draw GUI

draw_set_halign(fa_left);
draw_set_valign(fa_top);

var x0 = 16;
var y0 = 16;
var gx = x0; // GUI-X (nicht "x")
var gy = y0; // GUI-Y (nicht "y")

// HUD: Coins & Level
var coins         = (variable_global_exists("coins"))         ? global.coins         : 0;
var coins_needed  = (variable_global_exists("coins_needed"))  ? global.coins_needed  : 0;
var current_level = (variable_global_exists("current_level")) ? global.current_level : 1;

draw_text(gx, gy, "Level: " + string(current_level));     gy += 18;
draw_text(gx, gy, "Coins: " + string(coins) + " / " + string(coins_needed)); gy += 24;

// Aktive Spells
draw_text(gx, gy, "Active Spells:"); gy += 18;
if (is_undefined(global.active_spells)) global.active_spells = [];

for (var i = 0; i < array_length(global.active_spells); i++) {
    var spell_entry = global.active_spells[i];
    if (!is_struct(spell_entry)) continue;

    var lvl = (variable_struct_exists(spell_entry, "level")) ? spell_entry.level : 1;
    draw_text(gx, gy, string(i+1) + ". " + string(spell_entry.name) + " (" + string(lvl) + "/9)");
    gy += 16;
}

gy += 10;

// Passive Spells
draw_text(gx, gy, "Passive Spells:"); gy += 18;
if (is_undefined(global.passive_spells)) global.passive_spells = [];

for (var j = 0; j < array_length(global.passive_spells); j++) {
    var spell_entry_p = global.passive_spells[j];
    if (!is_struct(spell_entry_p)) continue;

    var lvlp = (variable_struct_exists(spell_entry_p, "level")) ? spell_entry_p.level : 1;
    draw_text(gx, gy, string(j+1) + ". " + string(spell_entry_p.name) + " (" + string(lvlp) + "/9)");
    gy += 16;
}
