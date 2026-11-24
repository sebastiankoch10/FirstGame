depth=-y;
if(global.game_paused) exit;
pickup_prev_x=x;pickup_prev_y=y;
if(menu_input_guard>0) {menu_input_guard--; exit;}
var input_x=(keyboard_check(vk_right)||keyboard_check(ord("D")) ? 1 : 0)-(keyboard_check(vk_left)||keyboard_check(ord("A")) ? 1 : 0);
var input_y=(keyboard_check(vk_down)||keyboard_check(ord("S")) ? 1 : 0)-(keyboard_check(vk_up)||keyboard_check(ord("W")) ? 1 : 0);
var mouse_distance=point_distance(x,y,mouse_x,mouse_y);
if(!mouse_check_button(mb_left)) mouse_move_armed=true;
var keyboard_input=input_x!=0 || input_y!=0;
var mouse_input=!keyboard_input && mouse_move_armed && mouse_check_button(mb_left) && mouse_distance>12;
var has_input=keyboard_input || mouse_input;
var input_direction=keyboard_input ? point_direction(0,0,input_x,input_y) : point_direction(x,y,mouse_x,mouse_y);
var move_amount=mouse_input ? min(moveSpeed,max(0,mouse_distance-12)) : moveSpeed;
aim_angle=point_direction(x,y,mouse_x,mouse_y);
if(has_input) facing_direction=input_direction;
image_angle=0; image_xscale=1;
var previous_motion=motion_state;
visual_land_timer=max(0,visual_land_timer-1);
movement_step(id,max(0,delta_time/1000000),has_input,input_direction,move_amount,keyboard_check_pressed(vk_space),keyboard_check_pressed(vk_control));
if(previous_motion!=player_motion_state.grounded && previous_motion!=player_motion_state.sliding && motion_state==player_motion_state.grounded)visual_land_timer=6;
state=has_input ? player_state.running : player_state.idle;
weapon_auto_step();
if(attack_timer>0) facing_direction=attack_direction;
motion_protected=player_is_protected(id);
var visual_actor = "swordsmanv3";
if (global.selected_character == "Mage") visual_actor = "magev3";
else if (global.selected_character == "Ranger") visual_actor = "rangerv3";

var visual_action = "idle";
var visual_direction_angle = facing_direction;
if (motion_state == player_motion_state.rising) {
    visual_action = "jump";
    visual_direction_angle = jump_direction;
} else if (motion_state == player_motion_state.falling) {
    visual_action = "fall";
    visual_direction_angle = jump_direction;
} else if (motion_state == player_motion_state.diving) {
    visual_action = "dive";
    visual_direction_angle = dive_direction;
} else if (motion_state == player_motion_state.sliding || dodge_timer>0) {
    visual_action = dodge_timer>0 && player_authored_actor(visual_actor) ? "dodge" : "slide";
    visual_direction_angle = dodge_timer>0 ? dodge_direction : slide_direction;
} else if (hud_hit_flash>0) {
    visual_action="hurt";
} else if (player_authored_actor(visual_actor) && visual_land_timer>0) {
    visual_action="landing";
} else if (attack_timer > 0) {
    visual_action = "attack";
    visual_direction_angle = attack_direction;

} else if (state == player_state.running) {
    visual_action = "walk";
}

if(visual_actor!="swordsmanv3") {
    visual_move_time=has_input ? visual_move_time+max(0,delta_time/1000000) : 0;
    if(visual_action=="walk" && visual_move_time>.45)visual_action="run";
    // Follow the shortest turn through authored octants; hair and cloth retain their preceding pose briefly.
    if(visual_action=="idle" || visual_action=="walk" || visual_action=="run") {
        var turn_blend=1-exp(-18*max(0,delta_time/1000000));
        visual_facing_angle-=angle_difference(visual_facing_angle,visual_direction_angle)*turn_blend;
        visual_direction_angle=visual_facing_angle;
    } else visual_facing_angle=visual_direction_angle;
}

var visual_direction = player_visual_direction(visual_actor,visual_direction_angle);

var visual_name = "spr_fg_" + visual_actor + "_" + visual_action + "_" + visual_direction;
var visual_key = visual_name;
if (visual_action == "attack") visual_key += "_" + string(attack_stage);

if (visual_animation_key != visual_key) {
    var visual_asset=player_visual_asset(visual_actor,visual_action,visual_direction,attack_stage);
    visual_sprite_index=visual_asset.sprite; visual_mirror=visual_asset.mirror; visual_size=visual_asset.size;
    visual_animation_key = visual_key;
    visual_frame_index = 0;
}

if (sprite_exists(visual_sprite_index)) {
    sprite_index = visual_sprite_index;
    image_speed = 0;
    var visual_frame_count = sprite_get_number(visual_sprite_index);
    var visual_fps = 8;
    if (visual_action == "idle") visual_fps = 4;
    else if(visual_action=="run")visual_fps=11;
    else if (visual_action == "attack" || visual_action == "jump" || visual_action == "fall" || visual_action == "hurt") visual_fps = 10;
    else if (visual_action == "dive" || visual_action == "slide") visual_fps = 12;
    if(visual_actor=="swordsmanv3" && visual_action=="hurt")visual_fps=18;

    if (visual_action == "attack") {
        var attack_progress = 1 - clamp(attack_timer / max(1,attack_duration), 0, 1);
        visual_frame_index = visual_actor=="swordsmanv3" && sword_combo_active ? master_sword_frame(attack_stage,sword_combo_clock-1) : clamp(floor(attack_progress * visual_frame_count), 0, visual_frame_count - 1);
        if(visual_actor=="magev3" || visual_actor=="rangerv3")visual_frame_index=clamp(floor(attack_progress*visual_frame_count*(visual_actor=="magev3" ? 1.7 : 2)),0,visual_frame_count-1);
    } else if (player_authored_actor(visual_actor) && visual_action=="dodge") {
        visual_frame_index=min(visual_frame_count-1,floor(dodge_elapsed/movement_config().dodge_duration*visual_frame_count));
    } else if (player_authored_actor(visual_actor) && visual_action=="slide") {
        visual_frame_index=min(visual_frame_count-1,floor(slide_timer/movement_config().slide_duration*visual_frame_count));
    } else if (player_authored_actor(visual_actor) && (visual_action=="jump" || visual_action=="fall")) {
        var jump_progress=jump_time/movement_config().jump_duration;
        var phase_progress=visual_action=="jump" ? jump_progress*2 : (jump_progress-0.5)*2;
        visual_frame_index=clamp(floor(phase_progress*visual_frame_count),0,visual_frame_count-1);
    } else if (visual_action == "idle" || visual_action == "walk" || visual_action=="run") {
        visual_frame_index = (visual_frame_index + visual_fps / max(1, room_speed)) mod visual_frame_count;
    } else {
        visual_frame_index = min(visual_frame_count - 1, visual_frame_index + visual_fps / max(1, room_speed));
    }
} else {
    visual_animation_key = visual_key;
}

var camera_x = clamp(x - 400, 0, max(0, room_width - 800));
var camera_y = clamp(y - 300, 0, max(0, room_height - 600));
camera_set_view_pos(camera, camera_x, camera_y);
