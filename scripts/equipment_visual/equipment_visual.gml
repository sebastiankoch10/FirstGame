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
        out[$ a] = {map: map, pieces: pieces, cells: src.cells, bones: variable_struct_exists(src, "bones") ? buffer_base64_decode(src.bones) : -1,
            hcut: variable_struct_exists(src, "hcut") ? buffer_base64_decode(src.hcut) : -1};
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
/// _pose (optional): {hair, cape} screen angles in degrees from player_motion_life; bends hair and cape of the base
/// model through the shared rig (bones per cell from the generated data). Without a pose the base is drawn as is.
function player_layers_draw(_actor, _spr, _frame, _x, _y, _xs, _ys, _col, _alpha, _equip = undefined, _rot = 0, _pose = undefined) {
    var cell = eqv_cell(_actor, _spr, _frame), bones = (is_struct(_pose) && cell >= 0 && vfx_secondary_motion()) ? eqv_bones(_actor, cell) : [];
    if (is_undefined(_equip)) _equip = variable_global_exists("equipment") ? global.equipment : {};
    var list = eqv_pieces_for(_equip), cut = 0;
    // A helmet piece is head and helmet in one: the base's rows above the brow are left out (no hair around it).
    if (cell >= 0) for (var h = 0; h < array_length(list); h++) if (string_copy(list[h].key, 1, 4) == "head") cut = eqv_hcut(_actor, cell);
    if (array_length(bones) > 0) {
        // Angles are given on screen; mirrored frames turn the other way in sprite space.
        var s = sign(_xs), p = {hair: _pose.hair * s, cape: _pose.cape * s};
        rig_draw_frame(_spr, _frame, bones, p, "plr_" + _actor, eqv_frame().oy - 6, _x, _y, _xs, _ys, _col, _alpha, 8, _rot, cut);
    } else if (cut > 0) eqv_draw_base_cut(_spr, _frame, _x, _y, _xs, _ys, _rot, _col, _alpha, cut);
    else draw_sprite_ext(_spr, _frame, _x, _y, _xs, _ys, _rot, _col, _alpha);
    if (cell < 0) return 0;
    var P = global.eqv[$ _actor].pieces, drawn = 0, flash = _col != c_white;
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
/// Secondary-motion bones of a cell (10 bytes: hair px,py,tx,ty,r then cape px,py,tx,ty,r; r=0 = none).
function eqv_bones(_actor, _cell) {
    var E = eqv_init();
    if (!variable_struct_exists(E, _actor) || E[$ _actor].bones < 0) return [];
    var b = E[$ _actor].bones, o = _cell * 10, out = [];
    if (o + 10 > buffer_get_size(b)) return [];
    var ids = ["hair", "cape"];
    for (var k = 0; k < 2; k++) {
        var r = buffer_peek(b, o + k * 5 + 4, buffer_u8);
        if (r == 0) continue;
        array_push(out, {id: ids[k], x: buffer_peek(b, o + k * 5, buffer_u8), y: buffer_peek(b, o + k * 5 + 1, buffer_u8),
            ex: buffer_peek(b, o + k * 5 + 2, buffer_u8), ey: buffer_peek(b, o + k * 5 + 3, buffer_u8), r: r * 1.2, parent: -1});
    }
    return out;
}
/// First base row covered by the head-and-helmet piece of a cell (0 = this frame has no helmet piece).
function eqv_hcut(_actor, _cell) {
    var E = eqv_init();
    if (!variable_struct_exists(E, _actor) || E[$ _actor].hcut < 0) return 0;
    var b = E[$ _actor].hcut;
    return (_cell >= 0 && _cell < buffer_get_size(b)) ? buffer_peek(b, _cell, buffer_u8) : 0;
}
/// Base frame without its top _cut rows; same placement, mirroring and rotation (about the origin) as draw_sprite_ext.
function eqv_draw_base_cut(_spr, _frame, _x, _y, _xs, _ys, _rot, _col, _alpha, _cut) {
    var ox = sprite_get_xoffset(_spr), oy = sprite_get_yoffset(_spr), w = sprite_get_width(_spr), h = sprite_get_height(_spr);
    var dx = -ox * _xs, dy = (_cut - oy) * _ys, cs = dcos(_rot), sn = dsin(_rot);
    draw_sprite_general(_spr, _frame, 0, _cut, w, h - _cut, _x + dx * cs + dy * sn, _y - dx * sn + dy * cs, _xs, _ys, _rot, _col, _col, _col, _col, _alpha);
}
/// Weapon attachment point of a frame (Phase 1, 7.3): grip in world coordinates and the direction from the grip to the
/// tip, following the body's own per-frame pose (generated equipment_attach_data, tests/tools/characters/
/// build_attach_points.py). ok=false when no weapon is visible in the frame; conf=0 when the hand is hidden (back
/// views): callers keep an attached item hidden there. Any future weapon type, off-hand item or shield is drawn here
/// instead of at an approximate floating position. Mirroring follows _xs like draw_sprite_ext.
function eqv_attach(_actor, _spr, _frame, _x, _y, _xs, _ys) {
    var cell = eqv_cell(_actor, _spr, _frame), d = equipment_attach_data();
    if (cell < 0 || !variable_struct_exists(d, _actor)) return {ok: false};
    var rows = d[$ _actor]; if (cell >= array_length(rows)) return {ok: false};
    var a = rows[cell]; if (!is_array(a)) return {ok: false};
    var F = eqv_frame();
    return {ok: true, x: _x + (a[0] - F.ox) * _xs, y: _y + (a[1] - F.oy) * _ys, angle: _xs < 0 ? 180 - a[2] : a[2], length: a[3] * abs(_xs), conf: a[4]};
}
