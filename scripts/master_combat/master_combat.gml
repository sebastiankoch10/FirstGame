/// One automatic attack is a complete three-hit chain, with separate windups/active contacts.
function master_sword_start(_target) {
    sword_combo_active=true;sword_combo_clock=0;sword_combo_event=0;
    sword_combo_direction=point_direction(x,y,_target.x,_target.y);
    weapon_cooldown=max(24,ceil(68/(1+weapon_haste)));
    global.sword_combo_metrics.chains++;
    // Talent "Sturmangriff": a chain started shortly after a dodge roll is empowered once.
    sword_charge_mult=1;
    if(variable_instance_exists(id,"sword_charge_until") && global.round_seconds<=sword_charge_until && talent_stat("sword_charge")>0){sword_charge_mult=1+talent_stat("sword_charge");sword_charge_until=-1;}
    sword_whirl_chain=talent_stat("sword_whirl")>0 && global.sword_combo_metrics.chains mod 4==0;
    master_sword_step();
}
/// The chain is the attack timeline "sword_chain" on the owner's clock sword_combo_clock (cursor sword_combo_event).
function master_sword_step() {
    var tl=atl_get("sword_chain");
    while(atl_due(tl,sword_combo_event,sword_combo_clock)) {
        var ev=tl.events[sword_combo_event];sword_combo_event++;
        if(ev.ev=="end") {sword_combo_active=false;attack_timer=0;return;}
        if(ev.ev=="pose")continue;
        var stage=ev.stage;
        if(ev.ev=="windup") {
            var target=combat_nearest(id,150);
            if(instance_exists(target))sword_combo_direction=point_direction(x,y,target.x,target.y);
            attack_stage=stage;attack_direction=sword_combo_direction;
            attack_duration=max(1,ceil(ev.dur/(1+weapon_haste)));
            attack_timer=attack_duration;
        } else {
            var hit=instance_create_layer(x,y,"Instances",ObjectSwordHitbox);
            hit.owner=id;hit.direction=sword_combo_direction;hit.combo_stage=stage;
            hit.damage=max(1,floor(round(weapon.damage+player_power*weapon.power_scale)*ev.mult+.5));
            hit.hit_radius=ev.radius*spell_area;hit.hit_half_angle=ev.span;
            // Talents and equipment (all neutral at rank 0 / without gear).
            var gear=variable_instance_exists(id,"weapon_damage_mult") ? weapon_damage_mult : 1,charge=variable_instance_exists(id,"sword_charge_mult") ? sword_charge_mult : 1;
            hit.damage=max(1,round(hit.damage*gear*(1+talent_stat("sword_dmg_pct"))*charge));
            hit.hit_radius*=1+talent_stat("sword_reach_pct");
            if(ev.finisher) {
                if(variable_instance_exists(id,"sword_whirl_chain") && sword_whirl_chain){hit.hit_half_angle=180;hit.hit_radius*=1.08;light_pulse(x,y-12,220,make_color_rgb(255,214,140),.8,.25);}
                if(talent_stat("sword_wave")>0)class_fx_add("sword_wave",x,y-10,hit.damage*talent_stat("sword_wave"),95*spell_area,.42);
                if(talent_stat("sword_leech")>0 && array_length(spell_targets(x,y-10,hit.hit_radius))>0 && hp>0){var before=hp;hp=min(max_hp,hp+talent_stat("sword_leech"));if(hp>before)light_pulse(x,y-20,90,make_color_rgb(120,255,150),.5,.2);}
            }
            hit.lifetime=ev.life;hit.total_lifetime=ev.life;
            global.sword_combo_metrics.swings++;if(ev.finisher)global.sword_combo_metrics.finishers++;
            fg_sfx("sword_swing");with(hit)event_perform(ev_step,0);
            // Visual only: sparks along the swing arc (bounded spell particle pool).
            for(var sp=0;sp<ev.sparks;sp++){var sa=hit.direction-hit.hit_half_angle+2*hit.hit_half_angle*(sp+.5)/ev.sparks,sr=hit.hit_radius*random_range(.55,.9);spell_particle(x+lengthdir_x(sr,sa),y-12+lengthdir_y(sr,sa),lengthdir_x(90,sa+90*ev.sweep),lengthdir_y(90,sa+90*ev.sweep),random_range(.12,.22),2,choose(make_color_rgb(255,214,140),c_white,make_color_rgb(255,170,90)),1,0);}
            light_pulse(x+lengthdir_x(70,attack_direction),y-12+lengthdir_y(70,attack_direction),ev.light_r,make_color_rgb(255,190,83),ev.light_a,.16);
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
    var tier=weapon_visual_tier();
    gpu_set_blendmode(bm_add);
    draw_sprite_ext(spr,frame,x,y,scale,scale,direction,c_white,alpha*(tier==1 ? .28 : (tier==2 ? .62 : .9)));
    if(tier==3)draw_sprite_ext(spr,frame,x,y,scale,scale,direction+4,make_color_rgb(255,212,116),alpha*.25);
    // An equipped weapon item adds a sheen in its rarity colour (visual only).
    if(variable_global_exists("equipment") && is_struct(global.equipment[$ "weapon"]))draw_sprite_ext(spr,frame,x,y,scale*1.04,scale*1.04,direction-3,equipment_rarity_color(global.equipment[$ "weapon"].rarity),alpha*.35);
    gpu_set_blendmode(bm_normal);
    draw_sprite_ext(spr,frame,x,y,scale,scale,direction,c_white,alpha*.72);
    draw_set_color(c_white);draw_set_alpha(1);
}
/// Body contact poses come from the same timeline as the damage events (frame keys of "sword_chain").
function master_sword_frame(_stage,_clock) {return atl_frame(atl_get("sword_chain"),_stage,_clock);}
