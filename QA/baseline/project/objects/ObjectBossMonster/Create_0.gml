/// Create Event von ObjectMonster
max_hp = 500 * global.monster_hp_multiplier;
hp = max_hp;
damage = 14 * global.monster_damage_multiplier;
speed = 1; // Geschwindigkeit bleibt konstant
slow_time = 0;
slow_factor = 1;
burn_time = 0;
burn_dps = 0;
monster_hurt_timer = 0;
monster_visual_key = "";
monster_visual_sprite = player_artpack_sprite("spr_fg_dragon_idle");
sprite_index = monster_visual_sprite;
hurt_flash_timer = 0;
damage_number = 0;
damage_number_timer = 0;
damage_number_y = -20;
boss_scale = 1.3;



base_move_speed = 1.1;

mask_index=combat_mask();
contact_radius=24;
shock_time=0; chase_vx=0; chase_vy=0;
speed=0;

particle_phase=irandom(7); separation_angle=irandom(359);

boss_configure(id,boss_definition("storm_warden"));
global.active_boss=id; global.boss_exists=true;
