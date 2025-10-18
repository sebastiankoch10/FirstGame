/// ObjectController: Draw GUI – Spell-Auswahl (3 Boxen, Icons, Namen über .id)

if (!global.game_paused) exit;
if (!(global.chest_collected || global.levelup_active)) exit;

// Defaults
if (is_undefined(global.spell_options))        global.spell_options = [];
if (is_undefined(global.selected_spell_index)) global.selected_spell_index = 0;

var options = global.spell_options;
var count   = array_length(options);

// Layout (GUI-Koordinaten)
var bx = 64;           // Box X
var by = 120;          // Box Y Start
var bw = 520;          // Box Breite
var bh = 72;          // Box Höhe
var gap = 14;          // Abstand zwischen Boxen
var pad = 10;          // Innenabstand
var icon_size = 48;    // Icongröße
var title_y = 64;

// semitransparenter Hintergrund
draw_set_alpha(0.35);
draw_rectangle(32, 48, 32 + 560, 48 + 3 * (bh + gap) + 40, false);
draw_set_alpha(1);

draw_set_halign(fa_left);
draw_set_valign(fa_top);

// Titel
var title = global.levelup_active ? "Level Up" : "Chest Reward";
draw_text(bx, title_y, title);

// Maus (GUI)
var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

// Auswahl
var sel = clamp(global.selected_spell_index, 0, max(0, count - 1));
var hover_index = -1;

// Optionen zeichnen
for (var i = 0; i < count; i++) {
    var opt = options[i];
    if (!is_struct(opt)) continue;

    var y1 = by + i * (bh + gap);
    var x1 = bx;
    var x2 = bx + bw;
    var y2 = y1 + bh;

    var is_hover = point_in_rectangle(mx, my, x1, y1, x2, y2);
    if (is_hover) hover_index = i;

    // Highlight
    var alpha_to_use = 0.22;
    if (sel == i) alpha_to_use = 0.36; else if (is_hover) alpha_to_use = 0.30;
    draw_set_alpha(alpha_to_use);
    draw_rectangle(x1, y1, x2, y2, false);
    draw_set_alpha(1);

    // --- Name/Typ/Lvl robust ---
    var s_name = "Unknown";
    var s_type = "active";
    var s_lvl  = 0;
    var sid    = undefined;
    var rt     = undefined;

    // 1) Bevorzugt: option.id -> Runtime-Daten -> echter Name
    if (variable_struct_exists(opt, "id") && is_real(opt.id)) {
        sid = opt.id;
        rt  = GetSpellData(sid);
        if (is_struct(rt) && !is_undefined(rt.name)) s_name = string(rt.name);
        if (is_struct(rt) && !is_undefined(rt.type)) s_type = (rt.type == SPELL_TYPE.PASSIVE) ? "passive" : "active";
    }

    // 2) Fallback: option.name existiert
    if (s_name == "Unknown" && variable_struct_exists(opt, "name")) {
        var raw = opt.name;
        if (is_string(raw)) {
            s_name = string(raw);
            var tmp = name_to_spell_id(s_name);
            if (!is_undefined(tmp)) { sid = tmp; rt = GetSpellData(sid); }
        } else if (is_real(raw)) {
            // evtl. bereits eine ID
            sid = raw;
            rt  = GetSpellData(sid);
            if (is_struct(rt) && !is_undefined(rt.name)) s_name = string(rt.name);
        }
    }

    // Typ ggf. aus opt.type überschreiben
    if (variable_struct_exists(opt, "type") && is_string(opt.type)) {
        s_type = string(opt.type);
    }

    if (variable_struct_exists(opt, "level")) s_lvl = opt.level;
    var next_level = max(1, s_lvl + 1);

    // Preview (optional)
    var dmg_txt = "";
    var cd_txt  = "";
    var preview = GetSpellData(s_name, next_level);
    if (is_struct(preview)) {
        if (!is_undefined(preview.damage))   dmg_txt = "  DMG:" + string(preview.damage);
        if (!is_undefined(preview.cooldown)) cd_txt  = "  CD:"  + string(preview.cooldown);
    }

    // Icon
    var icon_spr = noone;
    if (!is_undefined(sid)) {
        if (is_undefined(rt)) rt = GetSpellData(sid);
        if (is_struct(rt)) {
            if (!is_undefined(rt.icon_sprite) && rt.icon_sprite != noone) {
                icon_spr = rt.icon_sprite;
            } else if (!is_undefined(rt.icon_sprite_name)) {
                var idx = asset_get_index(rt.icon_sprite_name);
                if (idx != -1) icon_spr = idx;
            }
        }
    }

    // Icon zeichnen (links)
    var icon_x = x1 + pad;
    var icon_y = y1 + (bh - icon_size) * 0.5;
    if (icon_spr != noone) {
        var irw = sprite_get_width(icon_spr);
        var irh = sprite_get_height(icon_spr);
        var sx = icon_size / max(1, irw);
        var sy = icon_size / max(1, irh);
        draw_sprite_ext(icon_spr, 0, icon_x + icon_size * 0.5, icon_y + icon_size * 0.5, sx, sy, 0, c_white, 1);
    } else {
        draw_set_alpha(0.2);
        draw_rectangle(icon_x, icon_y, icon_x + icon_size, icon_y + icon_size, false);
        draw_set_alpha(1);
    }

    // Text (rechts)
    var tx = icon_x + icon_size + pad;
    var ty = y1 + pad;
    draw_text(tx, ty, s_name + "  [" + s_type + "]");
    draw_text(tx, ty + 18, "→ Level " + string(next_level) + dmg_txt + cd_txt);
}

// Hover an Step übergeben
global._ui_hover_index = hover_index;
