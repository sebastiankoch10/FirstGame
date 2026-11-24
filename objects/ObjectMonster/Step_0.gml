depth = -y;
if (global.game_paused) exit;
if(variable_instance_exists(id,"boss_twin") && boss_twin){if(!instance_exists(boss_owner)){instance_destroy();exit;}hp=boss_owner.hp;max_hp=boss_owner.max_hp;exit;}
if(variable_instance_exists(id,"boss_minion") && boss_minion){bv2_minion_step(id,min(.05,max(0,delta_time/1000000)));exit;}

var player_distance = 1000000000;
var moving_to_player = false;
if(instance_exists(ObjectPlayer)) {
    player_distance=point_distance(x,y,ObjectPlayer.x,ObjectPlayer.y);
    moving_to_player=true;
}
enemy_pursue();

if (burn_time > 0) {
    var burn_actual=min(max(0,hp),burn_dps / room_speed);hp-=burn_actual;
    if(variable_instance_exists(id,"burn_spell_id")) {run_stats_damage(burn_spell_id,burn_actual,false);damage_number_add(id,burn_actual,burn_spell_id,true);run_stats_get(burn_spell_id).dot_damage+=burn_actual;}
    burn_time -= 1;
}
if (hurt_flash_timer > 0) hurt_flash_timer -= 1;
if (damage_number_timer > 0) {
    damage_number_timer -= 1;
    damage_number_y -= 0.5;
}

// Monster stirbt, wenn HP <= 0
if (hp <= 0) {
    // Explicit self: the bare name resolves to the master_skeleton script asset (always truthy).
    if(variable_instance_exists(id,"lvl_kind"))level_enemy_death(id);
    else if(self.master_skeleton)master_skeleton_remains(id);
    global.run_kills++;
    fg_sfx("enemy_death");
    instance_create_layer(x, y, "Instances", ObjectCoin);
    // Magnet orbs are exclusively boss rewards.
    instance_destroy();
    exit;
}

if(variable_instance_exists(id,"lvl_kind")){level_enemy_step(min(.05,max(0,delta_time/1000000)));exit;}
if(self.master_skeleton){master_skeleton_step(min(.05,max(0,delta_time/1000000)));exit;}

var monster_action = "idle";
if (moving_to_player) monster_action = (player_distance <= 40) ? "attack" : "walk";
if (monster_hurt_timer > 0) {
    monster_hurt_timer -= 1;
    monster_action = "hurt";
}

if (instance_exists(ObjectPlayer)) image_xscale = (ObjectPlayer.x < x) ? -abs(image_xscale) : abs(image_xscale);

var monster_key = "spr_fg_" + monster_species + "_" + monster_action;
if (monster_visual_key != monster_key) {
    monster_visual_key = monster_key;
    monster_visual_sprite = player_artpack_sprite(monster_key);
    if (sprite_exists(monster_visual_sprite)) {
        sprite_index = monster_visual_sprite;
        image_index = 0;
        var monster_fps = monster_action == "idle" ? 4 : (monster_action == "walk" ? 8 : (monster_action == "attack" ? 9 : 8));
        image_speed = monster_fps / max(1, room_speed);
    }
}
if (sprite_exists(sprite_index) && (monster_action == "attack" || monster_action == "hurt")) {
    var monster_last_frame = sprite_get_number(sprite_index) - 1;
    if (image_index >= monster_last_frame) {
        image_index = monster_last_frame;
        image_speed = 0;
    }
}
