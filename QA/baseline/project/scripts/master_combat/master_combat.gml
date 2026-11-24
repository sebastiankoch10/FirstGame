/// One automatic attack is a complete three-hit chain, with separate windups/active contacts.
function master_sword_start(_target) {
    sword_combo_active=true;sword_combo_clock=0;sword_combo_event=0;
    sword_combo_direction=point_direction(x,y,_target.x,_target.y);
    weapon_cooldown=max(24,ceil(68/(1+weapon_haste)));
    global.sword_combo_metrics.chains++;master_sword_step();
}
function master_sword_step() {
    var timings=[0,4,16,22,34,42,56];
    while(sword_combo_event<7 && sword_combo_clock>=timings[sword_combo_event]) {
        var event_index=sword_combo_event;sword_combo_event++;
        if(event_index==6) {sword_combo_active=false;attack_timer=0;return;}
        var stage=(event_index div 2)+1;
        if(event_index mod 2==0) {
            var target=combat_nearest(id,150);
            if(instance_exists(target))sword_combo_direction=point_direction(x,y,target.x,target.y);
            attack_stage=stage;attack_direction=sword_combo_direction;
            attack_duration=max(1,ceil((stage==1 ? 16 : (stage==2 ? 18 : 22))/(1+weapon_haste)));
            attack_timer=attack_duration;
        } else {
            var hit=instance_create_layer(x,y,"Instances",ObjectSwordHitbox);
            var multipliers=[0.5,0.6,0.9];
            hit.owner=id;hit.direction=sword_combo_direction;hit.combo_stage=stage;
            hit.damage=max(1,floor(round(weapon.damage+player_power*weapon.power_scale)*multipliers[stage-1]+.5));
            hit.hit_radius=(stage==3 ? 130 : 116)*spell_area;hit.hit_half_angle=stage==3 ? 70 : 58;
            hit.lifetime=10;hit.total_lifetime=10;
            global.sword_combo_metrics.swings++;if(stage==3)global.sword_combo_metrics.finishers++;
            fg_sfx("sword_swing");with(hit)event_perform(ev_step,0);
            light_pulse(x+lengthdir_x(70,attack_direction),y-12+lengthdir_y(70,attack_direction),stage==3 ? 160 : 105,make_color_rgb(255,190,83),stage==3 ? .55 : .25,.16);
        }
    }
    sword_combo_clock+=1+weapon_haste;
}
function master_slash_draw() {
    if(!instance_exists(owner))return;
    var progress=clamp(1-lifetime/max(1,total_lifetime),0,1);
    var spr=player_artpack_sprite("spr_master_slash_"+string(combo_stage));
    var frame=min(sprite_get_number(spr)-1,floor(progress*sprite_get_number(spr)));
    var alpha=clamp(lifetime/3,0,1),scale=hit_radius/112;
    var tier=sword_visual_tier(global.current_level);
    gpu_set_blendmode(bm_add);
    draw_sprite_ext(spr,frame,x,y,scale,scale,direction,c_white,alpha*(tier==1 ? .28 : (tier==2 ? .62 : .9)));
    if(tier==3)draw_sprite_ext(spr,frame,x,y,scale,scale,direction+4,make_color_rgb(255,212,116),alpha*.25);
    gpu_set_blendmode(bm_normal);
    draw_sprite_ext(spr,frame,x,y,scale,scale,direction,c_white,alpha*.72);
    draw_set_color(c_white);draw_set_alpha(1);
}
/// Body contact poses use the same clock as the actual damage events, not an unrelated loop.
function master_sword_frame(_stage,_clock) {
    if(_stage==1)return _clock<4 ? 0 : 1;
    if(_stage==2)return _clock<22 ? 0 : 1;
    return _clock<42 ? 0 : (_clock<50 ? 1 : 2);
}
