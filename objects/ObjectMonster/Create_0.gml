/// Create Event von ObjectMonster
max_hp = 72 * global.monster_hp_multiplier;
hp = max_hp;
damage = 8 * global.monster_damage_multiplier;
speed = 0.2;
slow_time = 0;
slow_factor = 1;
burn_time = 0;
burn_dps = 0;
master_skeleton=room==Room1;
monster_species = self.master_skeleton ? "master_skeleton" : "slime";
monster_hurt_timer = 0;
monster_visual_key = "";
monster_visual_sprite = player_artpack_sprite(self.master_skeleton ? "spr_master_skeleton_idle_down" : "spr_fg_slime_idle");
sprite_index = monster_visual_sprite;
separation_phase = irandom(3);
hurt_flash_timer = 0;
damage_number = 0;
damage_number_timer = 0;
damage_number_y = -20;
monster_scale = 1.3;

base_move_speed = 1.05;

mask_index=combat_mask();
contact_radius=11;
shock_time=0; chase_vx=0; chase_vy=0;
speed=0;

particle_phase=irandom(7); separation_angle=irandom(359);
hit_stun=0;stun_lockout=0;knock_vx=0;knock_vy=0;
if(self.master_skeleton)master_skeleton_init();
