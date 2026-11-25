effects_draw();
if(level_world_room())master_shadow_draw(x-4,y+3,17-jump_height*.12,6-jump_height*.04,jump_height>0 ? .2 : .4);
equipment_player_aura_draw(id);
// Draw-Event von ObjectPlayer oder ObjectMonster

if (!variable_instance_exists(id, "jump_height")) jump_height = 0;
var use_artpack_sprite = sprite_exists(visual_sprite_index);
var draw_xscale = player_scale * visual_mirror * visual_size;
var draw_yscale = player_scale * visual_size;
// Idle breath is a small render transform, not additional authored sprite frames.
if((visual_actor=="magev3" || visual_actor=="rangerv3") && state==player_state.idle && attack_timer<=0 && motion_state==player_motion_state.grounded && hp>0)draw_yscale*=1+sin(current_time/420)*.008;
var motion_direction = 0;
var trail_length = 0;

if (motion_state == player_motion_state.rising) {
    if(!player_authored_actor(visual_actor)) draw_xscale *= 0.9;
    if(!player_authored_actor(visual_actor)) draw_yscale *= 1.15;
} else if (motion_state == player_motion_state.falling) {
    if(!player_authored_actor(visual_actor)) draw_xscale *= 1.05;
    if(!player_authored_actor(visual_actor)) draw_yscale *= 0.9;
} else if (motion_state == player_motion_state.diving) {
    if(!player_authored_actor(visual_actor)) draw_xscale *= 1.12;
    if(!player_authored_actor(visual_actor)) draw_yscale *= 0.72;
    motion_direction = dive_direction;
    trail_length = 18;
} else if (motion_state == player_motion_state.sliding || dodge_timer>0) {
    if(!player_authored_actor(visual_actor)) draw_xscale *= 1.18;
    if(!player_authored_actor(visual_actor)) draw_yscale *= 0.65;
    motion_direction = dodge_timer>0 ? dodge_direction : slide_direction;
    trail_length = 28;
}

if (trail_length > 0) {
    draw_set_alpha(0.45);
    draw_set_color(c_silver);
    draw_line(
        x - lengthdir_x(trail_length, motion_direction),
        y - lengthdir_y(trail_length, motion_direction),
        x,
        y
    );
    draw_set_alpha(1);
    draw_set_color(c_white);
}

if (jump_height > 0 && !level_world_room()) {
    draw_set_alpha(clamp(0.35 - jump_height / 700, 0.08, 0.35));
    draw_set_color(c_black);
    draw_ellipse(x - 18, y - 5, x + 18, y + 7, false);
    draw_set_alpha(1);
}
var player_draw_sprite = use_artpack_sprite ? visual_sprite_index : sprite_index;
var player_draw_frame = use_artpack_sprite ? visual_frame_index : image_index;
if(hp<=0 && player_authored_actor(visual_actor)) {
 var dir=player_visual_direction(visual_actor,facing_direction);
 player_draw_sprite=player_artpack_sprite("spr_fg_"+visual_actor+"_death_"+dir);
 player_draw_frame=min(sprite_get_number(player_draw_sprite)-1,floor((current_time-death_time)/120));
 draw_xscale=player_scale;draw_yscale=player_scale;
}
if (!sprite_exists(player_draw_sprite)) {
    show_error("ObjectPlayer has no valid ArtPack draw sprite", true);
    exit;
}
// Base model + visible equipment layers, all on the same frame (scripts/equipment_visual).
var life = player_motion_life();
player_layers_draw(visual_actor, player_draw_sprite, player_draw_frame, x, y - jump_height, draw_xscale * life.sx, draw_yscale * life.sy, hud_hit_flash>0 ? make_color_rgb(255,85,82) : c_white, 1, undefined, life.rot);

if (damage_reduction>0 && variable_instance_exists(id,"orbit_angle")) {
    var d=GetSpellData(SPELL.SHIELD);
    var ox=x+lengthdir_x(d.shield_radius,orbit_angle);
    var oy=y+lengthdir_y(d.shield_radius,orbit_angle);
    draw_set_color(make_color_rgb(117,210,255));
    draw_circle(ox,oy,10,true);
    spell_ui_icon(SPELL.SHIELD,ox-8,oy-8,16);
    draw_set_color(c_white);
}

player_health_draw();
