/// Visible equipment on the character (base model + layered pieces).
/// Every layer is drawn with the base sprite's current frame: the frame is mapped to a shared "cell" index, and each
/// equipment piece stores one pre-rendered image per cell (packed atlas spr_eqv_<actor>_<piece>, rect table in
/// equipment_visual_data). So all pieces follow the body pixel-exactly in every animation; there is one clock only.
/// Draw order: base -> feet -> chest -> hands -> head -> weapon (pieces are cut from the visible body, so the
/// order only matters at their borders). Accent layers (trims, guards, gems) are tinted with the rarity colour.

/// Build the lookup tables once (sprite index -> cell array, piece -> {sprite, rect buffer}).
function eqv_init() {
    if (variable_global_exists("eqv") && is_struct(global.eqv)) return global.eqv;
    var d = equipment_visual_data(), out = {}, actors = variable_struct_get_names(d.actors);
    for (var i = 0; i < array_length(actors); i++) {
        var a = actors[i], src = d.actors[$ a], map = ds_map_create(), names = variable_struct_get_names(src.sprites);
        for (var k = 0; k < array_length(names); k++) {
            var spr = asset_get_index(names[k]);
            if (sprite_exists(spr)) map[? spr] = src.sprites[$ names[k]];
        }
        var pieces = {}, pn = variable_struct_get_names(src.rects);
        for (var k = 0; k < array_length(pn); k++) {
            var ps = asset_get_index("spr_eqv_" + a + "_" + pn[k]);
            if (sprite_exists(ps)) pieces[$ pn[k]] = {spr: ps, buf: buffer_base64_decode(src.rects[$ pn[k]]), cells: src.cells};
        }
        out[$ a] = {map: map, pieces: pieces, cells: src.cells};
    }
    global.eqv = out;
    return out;
}

/// Tier of an item's look (same rule as equipment_base_name): 0..3 from the item level.
function eqv_item_tier(_item) {
    if (variable_struct_exists(_item, "tier")) return clamp(_item.tier, 0, 3);
    return clamp(floor((_item.ilvl - 1) / 4), 0, 3);
}

/// Trim/gem colour per rarity (common = dull bronze, magic blue, rare gold, epic violet).
function eqv_accent_color(_rarity) {
    switch (clamp(_rarity, 0, 3)) {
        case 0: return make_color_rgb(176, 138, 92);
        case 1: return make_color_rgb(110, 170, 255);
        case 2: return make_color_rgb(242, 200, 92);
        default: return make_color_rgb(196, 124, 255);
    }
}

/// Piece names that would be drawn for an equipment struct (slot order = draw order). Used by draw and tests.
function eqv_pieces_for(_equip) {
    var out = [], slots = ["feet", "chest", "hands", "head"];
    for (var i = 0; i < 4; i++) {
        var it = is_struct(_equip) && variable_struct_exists(_equip, slots[i]) ? _equip[$ slots[i]] : undefined;
        if (is_struct(it)) array_push(out, {key: slots[i] + string(eqv_item_tier(it)), rarity: it.rarity});
    }
    var w = is_struct(_equip) && variable_struct_exists(_equip, "weapon") ? _equip.weapon : undefined;
    if (is_struct(w)) array_push(out, {key: "wpn" + string(eqv_item_tier(w)), rarity: w.rarity});
    else array_push(out, {key: "wpn_s", rarity: -1});
    return out;
}

/// Draw one cell of a packed piece; offsets are relative to the frame origin from the generated data (frame.ox/oy).
function eqv_piece_draw(_pc, _cell, _x, _y, _xs, _ys, _col, _alpha, _rot = 0) {
    if (!is_struct(_pc) || _cell < 0 || _cell >= _pc.cells) return false;
    var o = _cell * 8, b = _pc.buf, w = buffer_peek(b, o + 4, buffer_u8);
    if (w == 0) return false;
    var ax = buffer_peek(b, o, buffer_u16), ay = buffer_peek(b, o + 2, buffer_u16);
    var h = buffer_peek(b, o + 5, buffer_u8), ox = buffer_peek(b, o + 6, buffer_u8), oy = buffer_peek(b, o + 7, buffer_u8);
    var F = eqv_frame(), dx = (ox - F.ox) * _xs, dy = (oy - F.oy) * _ys;
    if (_rot != 0) {
        // Rotate the piece corner about the feet like draw_sprite_ext rotates the base about its origin.
        var cs = dcos(_rot), sn = dsin(_rot), rx = dx * cs + dy * sn, ry = -dx * sn + dy * cs;
        dx = rx; dy = ry;
    }
    draw_sprite_general(_pc.spr, 0, ax, ay, w, h, _x + dx, _y + dy, _xs, _ys, _rot, _col, _col, _col, _col, _alpha);
    return true;
}

/// Cell index of a base sprite frame (-1 if the sprite has no layered art, e.g. non-player sprites).
function eqv_cell(_actor, _spr, _frame) {
    var E = eqv_init();
    if (!variable_struct_exists(E, _actor)) return -1;
    var arr = E[$ _actor].map[? _spr];
    if (is_undefined(arr)) return -1;
    return arr[clamp(floor(_frame), 0, array_length(arr) - 1)];
}

/// Base model + all visible equipment. _equip defaults to the run's equipment (no struct = start weapon only).
/// Returns the number of equipment layers drawn.
function player_layers_draw(_actor, _spr, _frame, _x, _y, _xs, _ys, _col, _alpha, _equip = undefined, _rot = 0) {
    draw_sprite_ext(_spr, _frame, _x, _y, _xs, _ys, _rot, _col, _alpha);
    var cell = eqv_cell(_actor, _spr, _frame);
    if (cell < 0) return 0;
    if (is_undefined(_equip)) _equip = variable_global_exists("equipment") ? global.equipment : {};
    var P = global.eqv[$ _actor].pieces, list = eqv_pieces_for(_equip), drawn = 0, flash = _col != c_white;
    for (var i = 0; i < array_length(list); i++) {
        var key = list[i].key;
        if (variable_struct_exists(P, key)) drawn += eqv_piece_draw(P[$ key], cell, _x, _y, _xs, _ys, _col, _alpha, _rot);
        if (list[i].rarity >= 0 && variable_struct_exists(P, key + "_acc"))
            eqv_piece_draw(P[$ key + "_acc"], cell, _x, _y, _xs, _ys, flash ? _col : eqv_accent_color(list[i].rarity), _alpha, _rot);
    }
    return drawn;
}
/// Frame spec of the layered character art (size and foot origin), from equipment_visual_data (96/48/88 before 25.11.2026).
function eqv_frame() {
    static f = undefined;
    if (is_undefined(f)) {var d = equipment_visual_data(); f = variable_struct_exists(d, "frame") ? d.frame : {size: 96, ox: 48, oy: 88};}
    return f;
}
