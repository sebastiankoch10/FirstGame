/// Native visual checks for the layered characters (base model + visible equipment), all three classes.
/// Injected only into the isolated copy built by tests/tools/run_native_harness.py visual (prefix vh, tag VISUAL).
/// Saves contact sheets (8 directions x 11 states x 5 equipment sets) and a live world shot per class.
function gp_key_down(_key) {return false;}
function gp_key_pressed(_key) {return false;}
function gp_mouse_down(_button) {return false;}
function gp_mouse_pressed(_button) {return false;}
function gp_mouse_x() {return instance_exists(ObjectPlayer) ? ObjectPlayer.x + 200 : 0;}
function gp_mouse_y() {return instance_exists(ObjectPlayer) ? ObjectPlayer.y : 0;}
function gp_gui_x(_device) {return -100;}
function gp_gui_y(_device) {return -100;}

function vh_check(_ok, _msg) {
    global.vh_checks++;
    var tag = global.vh_classes[min(global.vh_class, 2)];
    if (!_ok) {global.vh_failed = true; array_push(global.vh_failures, tag + " " + _msg); show_debug_message("VISUAL FAIL " + tag + " " + _msg);}
}
function vh_init() {
    if (variable_global_exists("vh_ready")) return;
    global.vh_ready = true; global.vh_checks = 0; global.vh_failed = false; global.vh_failures = []; global.vh_metrics = {};
    global.vh_classes = ["Sword", "Mage", "Ranger"]; global.vh_actors = ["swordsmanv3", "magev3", "rangerv3"];
    global.vh_class = 0; global.vh_stage = 0; global.vh_frame = 0; global.vh_render = false; global.vh_world_shot = ""; global.vh_done = false;
}
function vh_show_error(_msg, _abort = false) {show_debug_message("VISUAL_EXCEPTION show_error " + string(_msg)); throw string(_msg);}
function vh_menu_tick() {
    vh_init();
    if (global.vh_done) {
        show_debug_message("VISUAL_RESULT " + json_stringify({passed: !global.vh_failed, checks: global.vh_checks, failures: global.vh_failures, metrics: global.vh_metrics}));
        game_end(); return;
    }
    if (global.vh_stage != 0) return;
    menu_mode = "main"; menu_activate(0); menu_activate(global.vh_class);
    global.vh_stage = 1; global.vh_frame = 0; menu_activate(0);
}
/// Test item of a slot with the look of tier _t (item level picks the tier, like equipment_base_name).
function vh_item(_slot, _t, _rarity) {return {slot: _slot, rarity: _rarity, ilvl: 1 + _t * 4, stats: {}, name: "Test", order: []};}
function vh_set(_t) {
    if (_t < 0) return {};
    var s = {}, slots = ["weapon", "head", "chest", "hands", "feet"];
    for (var i = 0; i < 5; i++) s[$ slots[i]] = vh_item(slots[i], _t, _t);
    return s;
}
function vh_keys(_list) {var out = []; for (var i = 0; i < array_length(_list); i++) array_push(out, _list[i].key); return out;}
function vh_has(_arr, _v) {for (var i = 0; i < array_length(_arr); i++) if (_arr[i] == _v) return true; return false;}

/// Data integrity: every base sprite maps every frame to a valid cell; every rect lies inside its atlas and frame.
function vh_data_checks(_actor) {
    var E = eqv_init(), d = equipment_visual_data();
    vh_check(variable_struct_exists(E, _actor), "layer tables exist");
    if (!variable_struct_exists(E, _actor)) return;
    var A = E[$ _actor], src = d.actors[$ _actor], names = variable_struct_get_names(src.sprites), bad_map = 0, frames = 0;
    for (var i = 0; i < array_length(names); i++) {
        var spr = asset_get_index(names[i]), arr = src.sprites[$ names[i]];
        if (!sprite_exists(spr) || array_length(arr) != sprite_get_number(spr)) {bad_map++; continue;}
        for (var k = 0; k < array_length(arr); k++) {frames++; if (arr[k] < 0 || arr[k] >= A.cells) bad_map++;}
    }
    vh_check(bad_map == 0 && array_length(names) >= 120, "every base sprite frame maps to a layer cell (" + string(frames) + " frames)");
    var pieces = d.pieces, missing = 0, bad_rect = 0, filled = {};
    for (var p = 0; p < array_length(pieces); p++) {
        var keys = [pieces[p]]; if (pieces[p] != "wpn_s") array_push(keys, pieces[p] + "_acc");
        for (var q = 0; q < array_length(keys); q++) {
            if (!variable_struct_exists(A.pieces, keys[q])) {if (q == 0) missing++; continue;}
            var pc = A.pieces[$ keys[q]], sw = sprite_get_width(pc.spr), sh = sprite_get_height(pc.spr), n = 0;
            for (var c = 0; c < A.cells; c++) {
                var o = c * 8, w = buffer_peek(pc.buf, o + 4, buffer_u8); if (w == 0) continue; n++;
                var ax = buffer_peek(pc.buf, o, buffer_u16), ay = buffer_peek(pc.buf, o + 2, buffer_u16), h = buffer_peek(pc.buf, o + 5, buffer_u8);
                var ox = buffer_peek(pc.buf, o + 6, buffer_u8), oy = buffer_peek(pc.buf, o + 7, buffer_u8);
                if (ax + w > sw || ay + h > sh || ox + w > eqv_frame().size || oy + h > eqv_frame().size) bad_rect++;
            }
            if (q == 0) filled[$ keys[q]] = n;
        }
    }
    vh_check(missing == 0, "all 21 equipment pieces have atlas sprites");
    vh_check(bad_rect == 0, "every layer rect lies inside its atlas and inside the 96x96 frame");
    var need = ["head1", "chest1", "hands1", "feet1", "wpn_s", "wpn1"];
    for (var i = 0; i < array_length(need); i++)
        vh_check(variable_struct_exists(filled, need[i]) && filled[$ need[i]] >= A.cells * (need[i] == "hands1" ? .25 : .55), need[i] + " visible in most frames (" + string(variable_struct_exists(filled, need[i]) ? filled[$ need[i]] : 0) + "/" + string(A.cells) + ")");
    global.vh_metrics[$ _actor] = {cells: A.cells, frames: frames, filled: filled};
}

/// Equip / unequip / swap through the real equipment API.
function vh_api_checks(_actor) {
    var k0 = vh_keys(eqv_pieces_for(global.equipment));
    vh_check(array_length(k0) == 1 && k0[0] == "wpn_s", "run starts with the base model + start weapon only");
    equipment_equip(vh_item("chest", 2, 2));
    var k = vh_keys(eqv_pieces_for(global.equipment));
    vh_check(vh_has(k, "chest2") && vh_has(k, "wpn_s"), "equipping a chest piece shows chest2 and keeps the start weapon");
    equipment_equip(vh_item("chest", 0, 1));
    k = vh_keys(eqv_pieces_for(global.equipment));
    vh_check(vh_has(k, "chest0") && !vh_has(k, "chest2"), "swapping replaces the visible chest piece immediately (no stale layer)");
    equipment_equip(vh_item("weapon", 3, 3));
    k = vh_keys(eqv_pieces_for(global.equipment));
    vh_check(vh_has(k, "wpn3") && !vh_has(k, "wpn_s"), "weapon item replaces the start weapon (no double weapon)");
    var pl = ObjectPlayer;
    vh_check(pl.weapon_cooldown >= 0 && weapon_definition(global.selected_character).kind != "", "start weapon mechanics untouched by the weapon item look");
    global.equipment[$ "chest"] = undefined; global.equipment[$ "weapon"] = undefined; equipment_rebuild_cache();
    k = vh_keys(eqv_pieces_for(global.equipment));
    vh_check(array_length(k) == 1 && k[0] == "wpn_s", "unequipping removes the layers again");
    var cell = eqv_cell(_actor, pl.visual_sprite_index, pl.visual_frame_index);
    vh_check(pl.visual_actor == _actor && cell >= 0, "live player sprite has layered art (" + sprite_get_name(pl.visual_sprite_index) + ")");
    // attachment points: most cells carry a grip inside the frame, mirrored frames mirror the grip
    var rows = equipment_attach_data()[$ _actor], have = 0, inside = 0;
    for (var c = 0; c < array_length(rows); c++) if (is_array(rows[c])) {have++; if (rows[c][0] >= 0 && rows[c][0] < eqv_frame().size && rows[c][1] >= 0 && rows[c][1] < eqv_frame().size) inside++;}
    vh_check(have >= array_length(rows) * .8 && inside == have, "weapon attachment points for " + string(have) + " of " + string(array_length(rows)) + " cells, all inside the frame");
    var at = eqv_attach(_actor, pl.visual_sprite_index, pl.visual_frame_index, 100, 100, 1, 1), am = eqv_attach(_actor, pl.visual_sprite_index, pl.visual_frame_index, 100, 100, -1, 1);
    vh_check(eqv_attach_draw(pl.visual_sprite_index, 0, _actor, pl.visual_sprite_index, pl.visual_frame_index, -9000, -9000, 1, 1) == (at.ok && at.conf >= 1), "eqv_attach_draw draws exactly when the hand anchor is reliable");
    vh_check(!at.ok || (abs((at.x - 100) + (am.x - 100)) < .01 && abs(angle_difference(at.angle, 180 - am.angle)) < .01), "eqv_attach mirrors grip and angle with the facing");
    if (_actor == "swordsmanv3") { // hitstop (combat_feedback): physical base-weapon hits freeze the enemy picture, visual only
        var e = instance_create_layer(pl.x + 60, pl.y, "Instances", ObjectMonster), keep = global.selected_character, ok_pic = false, ok_back = false;
        global.selected_character = "Sword"; hit_reaction(e, pl, 0);
        var hs_set = variable_instance_exists(e, "hitstop_t") && abs(e.hitstop_t - HITSTOP_FRAMES / 60) < .001;
        with (e) {var rx = x, s = enemy_hitstop_begin(); ok_pic = is_struct(s) && abs(x - hitstop_x) <= 1 && image_index == hitstop_img; enemy_hitstop_end(s); ok_back = x == rx;}
        vh_check(hs_set && ok_pic && ok_back, "hitstop: a sword hit freezes the enemy picture for 2 frames and restores the real state");
        var m = instance_create_layer(pl.x - 60, pl.y, "Instances", ObjectMonster); global.selected_character = "Mage"; hit_reaction(m, pl, 0);
        vh_check(!variable_instance_exists(m, "hitstop_t"), "hitstop: never for the arcanist's magic base weapon");
        global.selected_character = keep; with (e) instance_destroy(); with (m) instance_destroy();
    }
}

/// Contact sheet: rows = 8 directions, columns = 11 states, one sheet per equipment set. Returns a buffer of the pixels.
function vh_sheet(_actor, _set, _name) {
    var dirs = ["right", "up_right", "up", "up_left", "left", "down_left", "down", "down_right"];
    var acts = [["idle", 0], ["walk", 2], ["run", 5], ["attack1", 1], ["attack2", 1], ["attack3", 1], ["jump", 1], ["slide", 1], ["dodge", 1], ["hurt", 1], ["death", 4]];
    var cw = 120, chh = 120, W = cw * array_length(acts), H = chh * 8;   // cells fit the 1:1 figures (density switch)
    var s = surface_create(W, H);
    surface_set_target(s); draw_clear(make_color_rgb(44, 54, 46));
    for (var r = 0; r < 8; r++) for (var c = 0; c < array_length(acts); c++) {
        var spr = asset_get_index("spr_fg_" + _actor + "_" + acts[c][0] + "_" + dirs[r]);
        if (!sprite_exists(spr)) continue;
        player_layers_draw(_actor, spr, min(acts[c][1], sprite_get_number(spr) - 1), c * cw + 60, r * chh + 110, 1, 1, c_white, 1, _set);
    }
    surface_reset_target();
    if (_name != "") surface_save(s, "vhcapture-" + _name + ".png");
    var b = buffer_create(W * H * 4, buffer_fixed, 1); buffer_get_surface(b, s, 0); surface_free(s);
    return b;
}
/// Differing pixels (every 2nd pixel sampled, scaled back); equality is checked exactly with md5.
function vh_diff(_a, _b) {
    var n = buffer_get_size(_a), d = 0;
    for (var i = 0; i < n; i += 8) if (buffer_peek(_a, i, buffer_u32) != buffer_peek(_b, i, buffer_u32)) d++;
    return d * 2;
}
function vh_same(_a, _b) {return buffer_md5(_a, 0, buffer_get_size(_a)) == buffer_md5(_b, 0, buffer_get_size(_b));}
/// Rendering checks (called from the GUI draw hook so surfaces are legal everywhere).
function vh_render_checks(_actor, _cls) {
    var none = vh_sheet(_actor, {}, _cls + "-base"), sets = [];
    for (var t = 0; t < 4; t++) array_push(sets, vh_sheet(_actor, vh_set(t), _cls + "-tier" + string(t)));
    if (EQUIPMENT_ARMOR_VISIBLE) {
        for (var t = 0; t < 4; t++) {
            var d = vh_diff(none, sets[t]);
            vh_check(d > 3000, "tier " + string(t) + " set visibly changes the character (" + string(d) + " px differ)");
            global.vh_metrics[$ _actor + "_diff_t" + string(t)] = d;
        }
        vh_check(vh_diff(sets[1], sets[2]) > 1500, "tier 1 and tier 2 sets look different");
    } else {
        // armour hidden (user decision 26.11.): a full armour set without weapon draws exactly the figure without gear,
        // a weapon item still shows its own look
        var armour = vh_set(3); armour[$ "weapon"] = undefined;
        var arm = vh_sheet(_actor, armour, "");
        vh_check(vh_same(arm, none), "armour layers hidden: a full tier-3 armour set leaves the figure pixel-identical");
        var d = vh_diff(none, sets[3]);global.vh_metrics[$ _actor + "_diff_weapon_t3"] = d;
        vh_check(d > 0, "weapon items stay visible while armour is hidden (" + string(d) + " px differ)");
        buffer_delete(arm);
    }
    var again = vh_sheet(_actor, vh_set(2), "");
    vh_check(vh_same(again, sets[2]), "rendering is deterministic (same set -> identical pixels)");
    var after = vh_sheet(_actor, {}, "");
    vh_check(vh_same(after, none), "after removing all gear the base model is pixel-identical (no stale layers)");
    buffer_delete(none); buffer_delete(again); buffer_delete(after);
    for (var t = 0; t < 4; t++) buffer_delete(sets[t]);
}

function vh_controller_tick() {
    vh_init();
    if (!instance_exists(ObjectPlayer)) return;
    var pl = ObjectPlayer, actor = global.vh_actors[global.vh_class], cls = global.vh_classes[global.vh_class];
    global.vh_frame++;
    pl.hp = pl.max_hp; global.next_levelup_time = 999999;
    with (ObjectMonster) instance_destroy();
    switch (global.vh_stage) {
        case 1:
            if (global.vh_frame < 20) return;
            vh_check(global.selected_character == cls, "class selected");
            vh_data_checks(actor);
            vh_api_checks(actor);
            global.vh_render = true; global.vh_stage = 2; global.vh_frame = 0; break;
        case 2:
            if (global.vh_render) return;
            // live game look: full epic set on the real player, lit world
            var s = vh_set(3), slots = ["weapon", "head", "chest", "hands", "feet"];
            for (var i = 0; i < 5; i++) equipment_equip(s[$ slots[i]]);
            global.vh_stage = 3; global.vh_frame = 0; break;
        case 3:
            if (global.vh_frame == 30) global.vh_world_shot = cls + "-world-epic";
            if (global.vh_frame < 40) return;
            global.vh_stage = 0; global.vh_class++;
            if (global.vh_class >= 3) global.vh_done = true;
            round_end_to_title(); break;
    }
}
function vh_world_capture() {
    if (!variable_global_exists("vh_ready")) return;
    if (global.vh_world_shot != "" && surface_exists(application_surface)) {surface_save(application_surface, "vhcapture-" + global.vh_world_shot + ".png"); global.vh_world_shot = "";}
    if (global.vh_render) {
        global.vh_render = false;
        vh_render_checks(global.vh_actors[global.vh_class], global.vh_classes[global.vh_class]);
    }
}
function vh_gui_capture_begin() {}
function vh_gui_capture_end() {}
