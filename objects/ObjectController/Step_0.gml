fg_audio_tick(max(0,delta_time/1000000));
boss_test_pending_start();
boss_test_tick(max(0,delta_time/1000000));review_tick(max(0,delta_time/1000000));
coin_cull_step(); // coins far outside the view sleep until the view comes near (combat_feedback)
if(talent_menu_step()) return; // character screen (talents + equipment) owns the frame while open
/// Step Event for ObjectController

// Escape oeffnet/verlaesst die normale Pause; Auswahl-Menues haben Vorrang.
if (!global.levelup_active && !global.chest_collected) {
    if (keyboard_check_pressed(vk_escape) && !global.game_over && !review_feedback_active()) { // Esc in the verdict dialog only closes the dialog
        if (global.settings_active) {global.settings_active=false; global._pause_index=0; return;}
        if (global.game_paused && global.normal_pause_active) {
            global.game_paused = false;
            global.normal_pause_active = false;
            instance_activate_all();
            global.pause_initialized = false;
            if(instance_exists(ObjectPlayer)) {ObjectPlayer.mouse_move_armed=false; ObjectPlayer.menu_input_guard=1;}
        } else if (!global.game_paused) {
            global.game_paused = true;
            global.normal_pause_active = true;
            global._pause_index=0;
            global.pause_initialized = false;
        }
    }
}

// Keep player/camera/GUI instances alive. Simulation is guarded, not deactivated.
if(global.game_paused && !global.game_over && !global.normal_pause_active && !global.levelup_active && !global.chest_collected) global.normal_pause_active=true;
// === PAUSE & ZAUBERAUSWAHL ===
if (global.game_paused) {
    if (variable_global_exists("game_over") && global.game_over) {
        if (!global.pause_initialized) {
            global.pause_initialized = true;

        }
        round_menu_step();
        return;
    }
    if (!global.pause_initialized) {
        global.pause_initialized = true;

    }

    if (global.chest_collected || global.levelup_active) {
        if(!global.choice_open) {global.choice_open=true;global.choice_mouse_armed=false;}
        if(!mouse_check_button(mb_left))global.choice_mouse_armed=true;
        var option_count = array_length(global.spell_options);
        if (option_count == 0) {
            show_debug_message("WARNUNG: Keine Spell-Optionen vorhanden!");
        }

        var previous_spell_index=global.selected_spell_index;
        // ---- Navigation per Pfeiltasten ----
        if (option_count > 0) {
            if (keyboard_check_pressed(vk_up)) {
                global.selected_spell_index =
                    (global.selected_spell_index - 1 + option_count) % option_count;
            }
            if (keyboard_check_pressed(vk_down)) {
                global.selected_spell_index =
                    (global.selected_spell_index + 1) % option_count;
            }
        }

        // ---- Maus-Hover passend zur Draw-UI ----
        var ui=spell_ui_layout();
        var ui_dx=ui.x, ui_dy=ui.y, card_w=ui.w, card_h=ui.row, card_gap=ui.gap;

        var mx = device_mouse_x_to_gui(0);
        var my = device_mouse_y_to_gui(0);

        var hover = -1;
        for (var i_h = 0; i_h < array_length(global.spell_options); i_h++) {
            var y0 = ui_dy + i_h * (card_h + card_gap);
            var x0 = ui_dx, y1 = y0 + card_h, x1 = ui_dx + card_w;
            if (mx >= x0 && mx <= x1 && my >= y0 && my <= y1) {
                hover = i_h;
                break;
            }
        }
        global._ui_hover_index = hover;
        if (hover >= 0) global.selected_spell_index = hover;
        fg_audio_hover(previous_spell_index,global.selected_spell_index);

        // ---- Auswahl bestätigen: Space ODER Linksklick auf Karte ----
        var confirm = false;
        // Gameplay keys never confirm a skill choice.
        if (global.choice_mouse_armed && mouse_check_button_pressed(mb_left) && hover >= 0) confirm = true;

        if (confirm) {
            if (array_length(global.spell_options) > 0) {
                var idx = clamp(global.selected_spell_index, 0, max(0, array_length(global.spell_options)-1));
                var selected = global.spell_options[idx];
                if (is_struct(selected)) {
                    if (variable_struct_exists(selected, "id")) learn_spell(selected.id);

                }

                // Zustand zurücksetzen
                global.choice_open=false;global.choice_mouse_armed=false;
                global.chest_collected = false;
                global.levelup_active  = false;
                global.game_paused     = false;
                instance_activate_all();
                global.pause_initialized = false;
                global._ui_hover_index = -1;
                global.start_choice_pending=false;
                global.next_levelup_time=global.round_seconds+progression_config().min_gap;
                if(instance_exists(ObjectPlayer)) {ObjectPlayer.mouse_move_armed=false; ObjectPlayer.menu_input_guard=1; apply_passives(ObjectPlayer);}
            }
        }

        return; // solange Auswahl ansteht, Rest skippen
    }

    if (global.normal_pause_active) {round_menu_step(); return;}
}

var simulation_dt=max(0,delta_time/1000000);
boss_world_step(simulation_dt);
if(global.game_paused || global.game_over) return;
hud_step(simulation_dt);
effects_step();
feedback_step(simulation_dt);weather_step(simulation_dt);
spell_v2_step(simulation_dt);equipment_step(simulation_dt);spell_vfx_step(simulation_dt);
fxp_step(simulation_dt);atmos_step(simulation_dt);fx_step(simulation_dt);fx_attacks_step(simulation_dt);fx_char_step(simulation_dt);fx_world_step(simulation_dt); // graphics overhaul: particles, atmosphere, post events (visual only)
class_effects_step(simulation_dt);
chain_visual_step(simulation_dt);


// === MAINTENANCE: COOLDOWNS & PASSIVES ===
var pl = (variable_global_exists("player")) ? global.player : noone;
if (instance_exists(pl)) {
    apply_passives(pl);
    spell_orbit_step(pl);
}

atmosphere_step(max(0,delta_time/1000000));
// Independent automatic spell cooldowns.
hotbar_tick_cooldowns();

// === LEVEL-UP CHECK ===
progression_try_level();

// === AUTOMATIC SPELLS ===
if (!global.game_paused) {
    auto_spells_step();
}

progression_audit_step();
