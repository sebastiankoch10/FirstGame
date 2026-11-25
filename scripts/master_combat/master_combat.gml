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
    var progress=clamp(1-lifetime/max(1,total_lifetime),0,1),rim=undefined;
    // An equipped weapon item tints the blade rim in its rarity colour (visual only).
    if(variable_global_exists("equipment") && is_struct(global.equipment[$ "weapon"]))rim=equipment_rarity_color(global.equipment[$ "weapon"].rarity);
    vfx_slash_draw(x,y,direction,hit_half_angle,hit_radius,progress,combo_stage,weapon_visual_tier(),rim);
}
/// Sword swing as a pixel crescent (render_pipeline: primitives land on the world grid, no stretched sprite): centred
/// on the chest, radius about the blade length, thickest in the middle and pointed at both ends: a light rim on the
/// blade-tip path, a pale-gold body and a thin dark inner edge. The visible part runs along the swing and fades in
/// steps. The finisher is wider and warmer with after-image rims. The hitbox is unchanged (reach = _radius).
function vfx_slash_draw(_x,_y,_dir,_span,_radius,_progress,_stage,_tier,_rim=undefined) {
    var fin=_stage>=3,sweep=(_stage mod 2==1) ? 1 : -1,a0=_dir-_span*sweep,a1=_dir+_span*sweep;
    var head=clamp(_progress*1.6,0,1),tail=clamp(_progress*1.6-.9,0,1),fade=_progress<.6 ? 1 : (_progress<.8 ? .7 : .4);
    if(head-tail<.02)return;
    var cy=_y-16,ro=_radius*(fin ? .56 : .5),band=ro*(fin ? .36 : .28),n=max(10,ceil(abs(a1-a0)*(head-tail)*ro/120)),pal=vfx_palette(0);
    var body=fin ? make_color_rgb(255,206,118) : pal[1],dark=fin ? make_color_rgb(150,84,38) : pal[0],light=pal[2];
    if(!is_undefined(_rim))light=merge_color(light,_rim,.45);
    var k=_tier<=1 ? .6 : (_tier==2 ? .82 : 1); // tier scales glow and after-images; the blade itself is always solid
    if(vfx_quality()>0){gpu_set_blendmode(bm_add);vfx_crescent(_x,cy,a0,a1,tail,head,ro,band,n,3,body,.25*k*fade);gpu_set_blendmode(bm_normal);}
    vfx_crescent(_x,cy,a0,a1,tail,head,ro,band,n,0,dark,.9*fade);
    vfx_crescent(_x,cy,a0,a1,tail,head,ro,band,n,1,body,fade);
    vfx_crescent(_x,cy,a0,a1,tail,head,ro,band,n,2,light,fade);
    if(fin && _tier>=2)for(var g=1;g<=2;g++)vfx_crescent(_x,cy,a0,a1,max(0,tail-.15*g),max(0,head-.15*g),ro+3*g,2,n,2,light,.45*k*fade/g);
    draw_set_alpha(1);draw_set_color(c_white);
}
/// One layer of a crescent over the arc part [_t0,_t1]: thickness _band*sin(pi*u)^.7 (pointed ends).
/// _layer 0 = dark inner edge, 1 = body, 2 = light rim on the outer radius, 3 = glow around everything.
function vfx_crescent(_x,_y,_a0,_a1,_t0,_t1,_ro,_band,_n,_layer,_col,_alpha) {
    if(_alpha<=0 || _t1<=_t0)return;
    draw_set_color(_col);draw_set_alpha(min(1,_alpha));draw_primitive_begin(pr_trianglestrip);
    for(var i=0;i<=_n;i++) {
        var u=i/_n,a=lerp(_a0,_a1,lerp(_t0,_t1,u)),inner=_ro-_band*power(max(0,sin(pi*u)),.7),r0,r1;
        switch(_layer){case 0:r0=inner;r1=min(_ro,inner+1.6);break;case 1:r0=min(_ro,inner+1);r1=_ro-2.5;break;case 2:r0=_ro-2.5;r1=_ro+.8;break;default:r0=inner-2;r1=_ro+3;}
        if(r1<r0)r1=r0;
        draw_vertex(round(_x+lengthdir_x(r0,a)),round(_y+lengthdir_y(r0,a)));
        draw_vertex(round(_x+lengthdir_x(r1,a)),round(_y+lengthdir_y(r1,a)));
    }
    draw_primitive_end();
}
/// One flat-coloured crescent strip over the arc part [_t0,_t1]; radii go from (_ri0,_ro0) at the tail to (_ri1,_ro1)
/// at the leading edge.
function vfx_slash_strip(_x,_y,_a0,_a1,_t0,_t1,_ri0,_ro0,_ri1,_ro1,_n,_col,_alpha) {
    if(_alpha<=0 || _t1<=_t0)return;
    draw_set_color(_col);draw_set_alpha(min(1,_alpha));
    draw_primitive_begin(pr_trianglestrip);
    for(var i=0;i<=_n;i++) {
        var u=i/_n,e=power(u,.6),a=lerp(_a0,_a1,lerp(_t0,_t1,u)),ri=lerp(_ri0,_ri1,e),ro=lerp(_ro0,_ro1,e);
        draw_vertex(round(_x+lengthdir_x(ri,a)),round(_y+lengthdir_y(ri,a)));
        draw_vertex(round(_x+lengthdir_x(ro,a)),round(_y+lengthdir_y(ro,a)));
    }
    draw_primitive_end();
}
/// Body contact poses come from the same timeline as the damage events (frame keys of "sword_chain").
function master_sword_frame(_stage,_clock) {return atl_frame(atl_get("sword_chain"),_stage,_clock);}
