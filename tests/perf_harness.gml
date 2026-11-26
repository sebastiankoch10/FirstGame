// Load measurement (prefix pf, tag PERF): python tests/tools/run_native_harness.py perf
// Real frame time (no fixed dt). Three scenarios, each 120 warm-up + 600 sampled frames with an invulnerable player:
//   horde        forest, minute 15 build, 150 enemies
//   twins_adds   Zwillingshexen minute 20, phase 3 rotation (overlapping mechanics), 60 enemies
//   dragon_adds  Drache minute 20, phase 3 rotation, 60 enemies
// Metrics per scenario: fps_real (uncapped fps from the frame's CPU work), frame time (delta_time) mean/p95/max,
// enemies, hostile bullets, bv2 hazards, spell particles, hazard-fx particles, light sources and light pass time,
// instances. GameMaker exposes neither draw calls nor process memory to GML: fps_real, the light pass time and the
// instance count are the substitute indicators (documented in docs/Systeme/Tests & QA.md).
function gp_key_down(_key) {return false;}
function gp_key_pressed(_key) {return false;}
function gp_mouse_down(_button) {return false;}
function gp_mouse_pressed(_button) {return false;}
function gp_mouse_x() {return instance_exists(ObjectPlayer) ? ObjectPlayer.x + 200 : 0;}
function gp_mouse_y() {return instance_exists(ObjectPlayer) ? ObjectPlayer.y : 0;}
function gp_gui_x(_device) {return -100;}
function gp_gui_y(_device) {return -100;}
function pf_show_error(_msg, _abort = false) {show_debug_message("PERF_EXCEPTION show_error " + string(_msg)); throw string(_msg);}
function pf_init() {
    if (variable_global_exists("pf_ready")) return;
    global.pf_ready = true; global.pf_i = 0; global.pf_frame = 0; global.pf_started = false; global.pf_metrics = {}; global.pf_done = false;
    // horde_coins: the horde plus 2500 coins left on the ground beyond the pickup radius (about 3 minutes of ranged
    // kills from minute 10 on, bot cohorts: ~900 kills per minute; coins stay until a boss magnet collects them)
    global.pf_scn = [{name: "horde", boss: "", enemies: 150, coins: 0}, {name: "twins_adds", boss: "twins", enemies: 60, coins: 0}, {name: "dragon_adds", boss: "storm_warden", enemies: 60, coins: 0},
        {name: "horde_coins", boss: "", enemies: 150, coins: 2500}];
    global.pf_dt = []; global.pf_fps = []; global.pf_acc = {};
}
function pf_menu_tick() {
    pf_init();
    if (global.pf_done) {
        show_debug_message("PERF_RESULT " + json_stringify({passed: true, checks: array_length(global.pf_scn), failures: [], metrics: global.pf_metrics}));
        game_end(); return;
    }
    if (global.pf_started) return;
    global.pf_frame++;
    // First scenario: stay in the menu until the texture warm-up is done (render_pipeline), measuring its cost there.
    if (global.pf_i == 0 && !variable_global_exists("pf_menu")) global.pf_menu = {frames: 0, max_ms: 0, done: false};
    if (global.pf_i == 0 && !global.pf_menu.done) {
        global.pf_menu.frames++; global.pf_menu.max_ms = max(global.pf_menu.max_ms, delta_time / 1000);
        if (!texture_warmup_done() && global.pf_menu.frames < 900) return;
        global.pf_menu.done = true; global.pf_menu.pages = array_length(texture_warmup_pages()); global.pf_metrics[$ "menu_warmup"] = global.pf_menu;
        show_debug_message("PERF menu_warmup " + json_stringify(global.pf_menu));
    }
    if (global.pf_frame < 10) return;
    var s = global.pf_scn[global.pf_i]; global.pf_started = true; global.pf_frame = 0; global.pf_dt = []; global.pf_fps = [];
    global.pf_acc = {enemies: 0, bullets: 0, hazards: 0, particles: 0, hz: 0, lights: 0, light_ms: 0, instances: 0, n: 0, spikes: 0, coins: 0};
    texture_debug_messages(true);
    if (s.boss == "") scene_test_start({level: 0, scene_minute: 15, class_name: "Mage", seed: 1337, build: 1, spell: 0, spell_level: 9, gear: 2, enemies: 0});
    else boss_test_start(s.boss, 20, "Mage", 1337, -1, false, 1);
}
function pf_controller_tick() {
    pf_init();
    if (!instance_exists(ObjectPlayer) || !variable_global_exists("boss_test") || !is_struct(global.boss_test) || !global.boss_test.active) return;
    var s = global.pf_scn[global.pf_i], pl = ObjectPlayer; global.pf_frame++;
    global.boss_test.invulnerable = true; pl.hp = pl.max_hp; global.next_levelup_time = 1000000000;
    if (global.pf_frame == 30) {
        if (instance_exists(global.active_boss)) global.active_boss.hp = global.active_boss.max_hp * .45; // phase 3: complex, overlapping patterns
        for (var k = 0; k < s.coins; k++) {var ca = k * 137.5, cd = 420 + (k mod 40) * 45; instance_create_layer(clamp(pl.x + lengthdir_x(cd, ca), 40, room_width - 40), clamp(pl.y + lengthdir_y(cd, ca), 40, room_height - 40), "Instances", ObjectCoin);}
    }
    // keep the enemy count at the target (kills are replaced), spawned on a ring around the player
    if (global.pf_frame >= 30 && global.pf_frame mod 4 == 0) {
        var have = instance_number(ObjectMonster);
        for (var k = have; k < min(s.enemies, have + 12); k++) {var a = k * 37 + global.pf_frame, d = 260 + (k mod 5) * 60; population_spawn_enemy(clamp(pl.x + lengthdir_x(d, a), 80, room_width - 80), clamp(pl.y + lengthdir_y(d, a), 80, room_height - 80));}
    }
    if (global.pf_frame == 121) show_debug_message("PERF WINDOW " + s.name); // texture loads logged after this line fall inside the window
    if (global.pf_frame > 120 && global.pf_frame <= 720) {
        var acc = global.pf_acc; acc.n++;
        array_push(global.pf_dt, delta_time / 1000); array_push(global.pf_fps, fps_real);
        // spikes: logged with frame and counts; texture page loads (texture_debug_messages) appear just before them in the log
        if (delta_time > 50000) {acc.spikes++; show_debug_message("PERF SPIKE " + s.name + " frame " + string(global.pf_frame) + " ms " + string(delta_time / 1000) + " enemies " + string(instance_number(ObjectMonster)) + " instances " + string(instance_count));}
        acc.enemies += instance_number(ObjectMonster); acc.bullets += array_length(global.hostile_bullets);
        acc.hazards += variable_global_exists("bv2_hazards") ? array_length(global.bv2_hazards) : 0;
        acc.particles += variable_global_exists("spell_particles") ? array_length(global.spell_particles) : 0;
        acc.hz += variable_global_exists("hz_last") ? global.hz_last : 0;
        acc.lights += variable_global_exists("light_metrics") ? global.light_metrics.sources : 0;
        acc.light_ms += (variable_global_exists("light_metrics") && variable_struct_exists(global.light_metrics, "draw_ms")) ? global.light_metrics.draw_ms : 0;
        acc.instances += instance_count; acc.coins += instance_number(ObjectCoin); // active coins only
    }
    if (global.pf_frame == 721) {
        var acc = global.pf_acc, n = max(1, acc.n), dt = global.pf_dt, fp = global.pf_fps, sum = 0, fsum = 0, fmin = 99999;
        array_sort(dt, true);
        for (var i = 0; i < array_length(dt); i++) sum += dt[i];
        for (var i = 0; i < array_length(fp); i++) {fsum += fp[i]; fmin = min(fmin, fp[i]);}
        global.pf_metrics[$ s.name] = {frames: n, frame_ms_mean: sum / n, frame_ms_p95: dt[floor(.95 * (array_length(dt) - 1))], frame_ms_max: dt[array_length(dt) - 1],
            fps_real_mean: fsum / n, fps_real_min: fmin, enemies: acc.enemies / n, hostile_bullets: acc.bullets / n, hazards: acc.hazards / n,
            spell_particles: acc.particles / n, hazard_particles: acc.hz / n, lights: acc.lights / n, light_pass_ms: acc.light_ms / n, instances: acc.instances / n, spikes_over_50ms: acc.spikes, active_coins: acc.coins / n};
        show_debug_message("PERF " + s.name + " " + json_stringify(global.pf_metrics[$ s.name]));
        global.pf_i++; global.pf_started = false; global.pf_frame = 0;
        if (global.pf_i >= array_length(global.pf_scn)) global.pf_done = true;
        round_end_to_title();
    }
}
function pf_world_capture() {}
function pf_gui_capture_begin() {}
function pf_gui_capture_end() {}
