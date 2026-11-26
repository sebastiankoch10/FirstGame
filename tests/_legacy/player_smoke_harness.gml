// Injected ONLY into an isolated smoke-test copy by run_player_smoke.py.
function smoke_assert(_condition, _message) {
    if (!_condition) {
        global.smoke_failure = _message;
        smoke_finish(false);
    }
}

function smoke_finish(_passed) {
    var _result = {
        passed: _passed,
        failure: global.smoke_failure,
        classes: global.smoke_results,
        elapsed_ms: current_time - global.smoke_started
    };
    var _json = json_stringify(_result);
    var _file = file_text_open_write("player-smoke-result.json");
    if (_file >= 0) {
        file_text_write_string(_file, _json);
        file_text_close(_file);
    }
    show_debug_message("PLAYER_SMOKE_RESULT " + _json);
    game_end();
}

function smoke_begin_step() {
    global.smoke_frame += 1;
    if (global.smoke_frame mod 120 == 1) {
        show_debug_message("PLAYER_SMOKE_STEP " + global.selected_character + " " + string(global.smoke_frame));
    }
    if (global.smoke_frame == 1) {
        global.smoke_start_x = x;
        global.smoke_start_y = y;
        global.smoke_distance = 0;
        global.smoke_attacks = 0;
        global.smoke_attack_effect = false;
        global.smoke_directions = array_create(4, false);
        global.smoke_class_started = current_time;
        global.smoke_last_x = x;
        global.smoke_last_y = y;
        global.smoke_actions = {};
        smoke_assert(sprite_exists(sprite_index), "Create sprite invalid");
        smoke_assert(sprite_exists(visual_sprite_index), "Create draw sprite invalid");
        smoke_assert(sprite_exists(mask_index), "Create collision mask invalid");
        smoke_assert(visual_actor == global.smoke_actors[global.smoke_class_index], "Wrong class initialized");
        // Reproduce the reported condition: even a missing engine draw sprite
        // must not reach a sprite-size/frame call in movement or attacks.
        sprite_index = -1;
        // Exercise the other first-draw-before-Step regression immediately.
        var _monster = instance_create_layer(x+200, y+200, "Instances", ObjectMonster);
        var _boss = instance_create_layer(x-250, y-200, "Instances", ObjectBossMonster);
        smoke_assert(sprite_exists(_monster.sprite_index), "Monster Create sprite invalid");
        smoke_assert(sprite_exists(_boss.sprite_index), "Boss Create sprite invalid");
        // Draw handlers must also be safe before their first normal Step.
        with (_monster) event_perform(ev_draw, 0);
        with (_boss) event_perform(ev_draw, 0);
        with (_boss) instance_destroy();
    }
}

function smoke_key_down(_key) {
    var _segment = (global.smoke_frame div 120) mod 4;
    if ((_key == ord("D") || _key == vk_right) && _segment == 0) return true;
    if ((_key == ord("S") || _key == vk_down) && _segment == 1) return true;
    if ((_key == ord("A") || _key == vk_left) && _segment == 2) return true;
    if ((_key == ord("W") || _key == vk_up) && _segment == 3) return true;
    return false;
}

function smoke_key_pressed(_key) {
    return _key == vk_space && (global.smoke_frame == 180 || global.smoke_frame == 190 || global.smoke_frame == 420);
}

function smoke_mouse_pressed(_button) {
    return _button == mb_left && global.smoke_frame mod 60 == 10;
}

function smoke_end_step(_action) {
    smoke_assert(!global.game_paused, "Unexpected pause prevented gameplay");
    smoke_assert(sprite_exists(sprite_index), "Step sprite invalid");
    smoke_assert(sprite_exists(visual_sprite_index), "Step draw sprite invalid");
    smoke_assert(sprite_exists(mask_index), "Step collision mask invalid");
    smoke_assert(mask_index == spr_fg_warrior_idle_right, "Animation changed collision mask");
    smoke_assert(collision_half_width == 32 && collision_half_height == 32, "Animation resized movement bounds");
    smoke_assert(x >= 32 && x <= room_width-32 && y >= 32 && y <= room_height-32, "Player left room bounds");
    global.smoke_distance += point_distance(x,y,global.smoke_last_x,global.smoke_last_y);
    global.smoke_last_x = x;
    global.smoke_last_y = y;
    global.smoke_directions[(global.smoke_frame div 120) mod 4] = true;
    variable_struct_set(global.smoke_actions, _action, true);
    if (state == player_state.attacking) global.smoke_attacks += 1;
    if (global.selected_character == "Sword" && instance_exists(ObjectSwordHitbox)) global.smoke_attack_effect = true;
    if (global.selected_character == "Mage" && instance_exists(ObjectFireball)) global.smoke_attack_effect = true;
    if (global.selected_character == "Ranger" && instance_exists(ObjectLightningball)) global.smoke_attack_effect = true;
    if (global.smoke_frame >= 720 && current_time-global.smoke_class_started >= 10000) {
        smoke_assert(global.smoke_distance > 300, "No sustained movement");
        smoke_assert(global.smoke_attacks > 0, "No attack state");
        smoke_assert(global.smoke_attack_effect, "No attack hitbox/projectile");
        smoke_assert(variable_struct_exists(global.smoke_actions,"jump"), "Jump not exercised");
        smoke_assert(variable_struct_exists(global.smoke_actions,"fall"), "Fall not exercised");
        smoke_assert(variable_struct_exists(global.smoke_actions,"dive"), "Dive not exercised");
        smoke_assert(variable_struct_exists(global.smoke_actions,"slide"), "Slide not exercised");
        array_push(global.smoke_results, {
            character: global.selected_character,
            room: room_get_name(room),
            frames: global.smoke_frame,
            elapsed_ms: current_time-global.smoke_class_started,
            movement_distance: global.smoke_distance,
            attack_frames: global.smoke_attacks,
            attack_effect: global.smoke_attack_effect,
            actions: global.smoke_actions
        });
        global.smoke_class_index += 1;
        if (global.smoke_class_index >= 3) {
            smoke_finish(true);
        } else {
            global.selected_character = global.smoke_classes[global.smoke_class_index];
            global.smoke_frame = 0;
            room_restart();
        }
    }
}
