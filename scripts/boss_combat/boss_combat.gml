/// Central encounter schedule and reusable, bounded boss attack components.
function boss_definitions() {
    static defs=[
        {id:"mini_sentinel",name:"Waldwaechter",at:60,main:false,tier:0,hp:650,contact:12,bullet:8,strike:42,lob:26,species:"golem",reward:8,individual:true},
        {id:"mini_warden",name:"Runenwaechter",at:180,main:false,tier:1,hp:1100,contact:14,bullet:10,strike:58,lob:30,species:"boar",reward:12,individual:true},
        {id:"storm_warden",name:"ASCHENFLUEGEL",at:300,main:true,tier:2,hp:9200,contact:16,bullet:12,strike:86,lob:44,species:"dragon",reward:30,individual:true},
        {id:"twins",name:"DIE ZWILLINGSHEXEN",at:300,main:true,tier:2,hp:13000,contact:0,bullet:12,strike:50,lob:35,species:"witches",reward:30,individual:true},
        {id:"behemoth",name:"SUMPFBEHEMOTH",at:300,main:true,tier:2,hp:9200,contact:14,bullet:12,strike:55,lob:32,species:"behemoth",reward:30,individual:true}
    ];
    return defs;
}
function boss_definition(_id) {
    var defs=boss_definitions();
    for(var i=0;i<array_length(defs);i++) if(defs[i].id==_id) return defs[i];
    return undefined;
}
function boss_dev_allowed() {
    if(debug_mode) return true;
    for(var i=1;i<=parameter_count();i++) if(parameter_string(i)=="--boss-dev") return true;
    return false;
}
function boss_system_reset() {
    global.boss_spawn_times=[60,180,300,600,900,1200,1500,1800];
    global.boss_spawned=array_create(8,false);global.bv2_hazards=[];
    global.boss_rng=irandom(2147483645)+1;
    global.hostile_bullets=[]; global.active_boss=noone;
    global.boss_index=0; global.boss_exists=false;
    global.boss_victory_name=""; global.boss_victory_time=0;
    global.boss_dev_enabled=boss_dev_allowed();
    if(global.boss_dev_enabled) exception_unhandled_handler(function(ex) {
        var message="BOSS_DEV_EXCEPTION "+json_stringify(ex);
        show_debug_message(message);
        var log=file_text_open_append("boss-dev-errors.log");
        file_text_write_string(log,message); file_text_writeln(log); file_text_close(log);
        game_end(); return true;
    });
    global.boss_dev_speed=1; global.boss_dev_index=2; global.boss_dev_pattern=0;
}
function boss_schedule_step() {
    if(global.game_paused || global.game_over || !global.round_active || !instance_exists(ObjectPlayer)) return;
    if(instance_exists(global.active_boss) || instance_exists(ObjectBossMonster)) return;
    if(variable_global_exists("boss_test") && global.boss_test.active)return;
    for(var i=0;i<8;i++) {
        if(global.boss_spawned[i] || global.round_seconds<global.boss_spawn_times[i]) continue;
        var selected=i==0 ? "mini_sentinel" : (i==1 ? "mini_warden" : boss_v2_pick());
        if(selected=="")return;
        var spawned=boss_spawn(selected);
        if(instance_exists(spawned)) {global.boss_spawned[i]=true; global.boss_index=i+1;}
        return; // At most one boss; overdue encounters queue in deterministic order.
    }
}
function boss_spawn(_id) {
    var d=boss_definition(_id);
    if(!is_struct(d) || !instance_exists(ObjectPlayer) || instance_exists(ObjectBossMonster)) return noone;
    if(d.main && !boss_v2_available(boss_v2_definition(_id)))return noone;
    var pl=ObjectPlayer,px=pl.x,py=pl.y;
    var best_x=clamp(px+280,80,room_width-80),best_y=py,best_distance=0;
    for(var i=0;i<8;i++) {
        var xx=clamp(px+lengthdir_x(290,i*45),80,room_width-80);
        var yy=clamp(py+lengthdir_y(210,i*45),80,room_height-80);
        var dist=point_distance(px,py,xx,yy);
        if(dist>best_distance) {best_distance=dist; best_x=xx; best_y=yy;}
    }
    var b=instance_create_layer(best_x,best_y,"Instances",ObjectBossMonster);
    boss_configure(b,d);
    if(b.dragon_enabled) {b.x=clamp(px+245,140,room_width-140);b.y=clamp(py+200,310,room_height-24);}
    global.active_boss=b; global.boss_exists=true;
    fg_sfx("boss_spawn"); fg_music_set("boss");
    return b;
}
function boss_configure(_b,_d) {
    _b.boss_data=_d; _b.boss_id=_d.id;
    _b.max_hp=_d.hp*global.monster_hp_multiplier; _b.hp=_b.max_hp;
    _b.damage=_d.contact*global.monster_damage_multiplier;
    _b.boss_phase=1; _b.boss_state="intro"; _b.boss_timer=1.5;
    _b.boss_rotation=0; _b.boss_fan_uses=0; _b.boss_cast="";
    _b.boss_cast_angle=0; _b.boss_fan_count=1;
    _b.boss_wave_left=0; _b.boss_wave_timer=0;
    _b.boss_completed=false;_b.v2_clock=0; // one hazard clock per boss (boss_v2_init resets it for main bosses)
    _b.body_radius=_d.main ? (_d.tier>=5 ? 132 : 88) : 44;
    _b.visual_height=_d.main ? (_d.tier>=5 ? 310 : 220) : 108;
    if(_d.id=="storm_warden") {_b.body_radius=108;_b.visual_height=300;}
    _b.contact_radius=_b.body_radius;
    _b.offscreen_time=0;_b.teleport_cooldown=0;_b.teleport_warning=0;
    _b.teleport_x=_b.x;_b.teleport_y=_b.y;_b.contact_next=0;
    _b.boss_scale=1;
    // Shared body mask scaled explicitly for a larger boss body, not by attack-frame dimensions.
    _b.mask_index=boss_body_mask(_b.body_radius,_b.visual_height);
    _b.speed=0; _b.base_move_speed=0.65;
    _b.monster_visual_key="";
    dragon_init(_b);
    boss_v2_init(_b);
    _b.mini_auto_timer=1;
}
function boss_cleanup(_owner,_keep_actors=false) {
    if(_keep_actors)bv2_clear_owner(_owner);else boss_v2_cleanup(_owner);
    if(variable_global_exists("hostile_bullets")) {
        for(var i=array_length(global.hostile_bullets)-1;i>=0;i--) if(global.hostile_bullets[i].owner==_owner) array_delete(global.hostile_bullets,i,1);
    }
    if(variable_global_exists("active_boss") && global.active_boss==_owner) {global.active_boss=noone; global.boss_exists=false;}
}
function boss_reward_once(_b) {
    if(!instance_exists(_b) || _b.boss_completed) return false;
    _b.boss_completed=true;global.run_boss_kills++;
    talent_on_boss_defeated(is_struct(_b.boss_data) && _b.boss_data.main);equipment_boss_drop(_b);
    fg_sfx("boss_defeated");
    if(global.round_active && !global.game_over) fg_music_set("level");
    boss_cleanup(_b.id);
    // Chest and magnet remain valuable; direct XP cannot cross several thresholds on its own.
    var reward_cap=max(0,floor(global.coins_needed*.12));
    global.coins+=min(reward_cap,_b.boss_data.main ? 5 : 2);
    _b.reward_chest=instance_create_layer(_b.x,_b.y,"Instances",ObjectChest);
    _b.reward_orb=magnet_drop(clamp(_b.x+42,24,room_width-24),clamp(_b.y,24,room_height-24),true);
    global.boss_victory_name=_b.boss_data.name;global.boss_victory_time=4;
    return true;
}
function boss_complete(_b) {
    if(!instance_exists(_b)) return;
    boss_reward_once(_b);with(_b) instance_destroy();
}
/// Miniboss zone (lightning, lob). Since 27.11. a shared bv2 hazard on the boss's own clock: the same circle, warning,
/// 0.12 s hit window, one hit, height (lightning all, lob ground); looks and ignition in scripts/hazard_looks.
function boss_zone_add(_boss,_kind,_x,_y,_radius,_warning,_damage) {
    var h=bv2_zone(_boss,"mini_"+_kind,clamp(_x,24,room_width-24),clamp(_y,24,room_height-24),_radius,_warning,.12,_damage,_kind=="lightning" ? "all" : "ground");
    if(!is_struct(h) || h.expired) return false;
    h.col=make_color_rgb(255,67,104);h.src_x=_boss.x;h.src_y=_boss.y-20;
    return true;
}
function boss_fan_pattern(_boss,_angle,_count,_spacing,_speed,_damage) {
    for(var i=0;i<_count;i++) {
        if(array_length(global.hostile_bullets)>=512) break;
        var dir=_angle+(i-(_count-1)*0.5)*_spacing;
        array_push(global.hostile_bullets,{owner:_boss,x:_boss.x,y:_boss.y-20,
            vx:lengthdir_x(_speed,dir),vy:lengthdir_y(_speed,dir),radius:5,age:0,life:6,damage:_damage});
    }
}
function boss_ring_pattern(_boss,_safe_angle) {
    // A deliberate +/-36 degree safe wedge remains open in every ring.
    var count=22;
    for(var i=0;i<count;i++) {
        var angle=i*360/count;
        if(abs(angle_difference(angle,_safe_angle))<36) continue;
        boss_fan_pattern(_boss,angle,1,0,145,_boss.boss_data.bullet);
    }
}
function boss_attack_begin(_b,_pattern) {
    if(!instance_exists(_b) || !instance_exists(ObjectPlayer)) return;
    if(_b.dragon_enabled) {dragon_attack_begin(_b,_pattern);return;}
    var d=_b.boss_data,pl=ObjectPlayer;
    _b.boss_cast=_pattern; _b.boss_state="windup";
    _b.boss_cast_angle=point_direction(_b.x,_b.y-20,pl.x,pl.y-10);
    _b.boss_wave_left=0;
    if(_pattern=="lightning") {
        var warning=_b.boss_phase==1 ? 1.15 : 1.0;
        _b.boss_timer=warning;
        var radius=d.main ? 52 : 40;
        boss_zone_add(_b,"lightning",pl.x,pl.y-10,radius,warning,d.strike*global.monster_damage_multiplier);
        if(_b.boss_phase==2 && d.main) {
            for(var side=-1;side<=1;side+=2) boss_zone_add(_b,"lightning",pl.x+lengthdir_x(145,_b.boss_cast_angle+90*side),pl.y-10+lengthdir_y(145,_b.boss_cast_angle+90*side),radius,warning,d.strike*global.monster_damage_multiplier);
        }
    } else if(_pattern=="lob") {
        _b.boss_timer=1.4;
        boss_zone_add(_b,"lob",pl.x,pl.y-10,68,1.4,d.lob*global.monster_damage_multiplier);
        if(_b.boss_phase==2) boss_zone_add(_b,"lob",pl.x+lengthdir_x(165,_b.boss_cast_angle+90),pl.y-10+lengthdir_y(165,_b.boss_cast_angle+90),68,1.65,d.lob*global.monster_damage_multiplier);
    } else {
        _b.boss_timer=_pattern=="ring" ? 1.0 : 0.75;
        _b.boss_fan_uses++;
        _b.boss_fan_count=min(5,1+2*min(2,_b.boss_fan_uses-1));
        if(_b.boss_phase==2) _b.boss_fan_count=max(5,_b.boss_fan_count);
        // announcement of the fan / ring as a shared hazard without hit (marker), same sector as before
        var ring=_pattern=="ring",mk=bv2_hazard(_b,"mini_cast",telegraph_make("sector",_b.x,_b.y-20,500,_b.boss_timer,_b.boss_cast_angle+(ring ? 180 : 0),ring ? 288 : max(10,(_b.boss_fan_count-1)*14)),0,0,"all",false,undefined);
        if(is_struct(mk)){mk.marker=true;mk.col=make_color_rgb(255,93,135);}
    }
}
function boss_step(_b,_dt) {
    if(global.game_paused || global.game_over || !instance_exists(_b)) return;
    if(variable_instance_exists(_b,"v2_enabled") && _b.v2_enabled)boss_twin_status(_b);
    if(_b.burn_time>0) {var burn_actual=min(max(0,_b.hp),_b.burn_dps*_dt);_b.hp-=burn_actual;
        if(variable_instance_exists(_b,"burn_spell_id")) {run_stats_damage(_b.burn_spell_id,burn_actual,false);damage_number_add(_b,burn_actual,_b.burn_spell_id,true);run_stats_get(_b.burn_spell_id).dot_damage+=burn_actual;} _b.burn_time=max(0,_b.burn_time-_dt*room_speed);}
    _b.slow_time=max(0,_b.slow_time-_dt*room_speed); _b.shock_time=max(0,_b.shock_time-_dt*room_speed);
    _b.hurt_flash_timer=max(0,_b.hurt_flash_timer-1); _b.damage_number_timer=max(0,_b.damage_number_timer-1);
    if(_b.dragon_enabled) {dragon_step(_b,_dt);return;}
    if(_b.v2_enabled) {if(_b.hp<=0){if(!_b.v2_dying)boss_v2_die(_b);return;}bv2_encounter_step(_b,_dt);return;}
    if(_b.hp<=0) {boss_complete(_b); return;}
    _b.v2_clock+=_dt; // drives the miniboss's shared hazards (zones, announcements)
    if(_b.boss_data.main && _b.boss_phase==1 && _b.hp<_b.max_hp*0.5) {
        boss_cleanup(_b.id); global.active_boss=_b; global.boss_exists=true;
        fg_sfx("boss_phase");
        _b.boss_phase=2; _b.boss_state="transition"; _b.boss_timer=1.4; _b.boss_wave_left=0;
        effect_add(_b.x,_b.y-15,95,make_color_rgb(184,135,235),28);
    }
    if(boss_navigation_step(_b,_dt)) return;
    if(_b.boss_id=="mini_sentinel") {
        _b.mini_auto_timer-=_dt;
        if(_b.mini_auto_timer<=0 && instance_exists(ObjectPlayer)){boss_fan_pattern(_b,point_direction(_b.x,_b.y-20,ObjectPlayer.x,ObjectPlayer.y-10),1,0,175,_b.boss_data.bullet*global.monster_damage_multiplier);fg_sfx("magic_projectile");_b.mini_auto_timer=1.6;}
    }
    _b.boss_timer-=_dt;
    if(_b.boss_wave_left>0) {
        _b.boss_wave_timer-=_dt;
        if(_b.boss_wave_timer<=0) {
            boss_fan_pattern(_b,_b.boss_cast_angle+(_b.boss_wave_left mod 2==0 ? 4 : -4),_b.boss_fan_count,14,165,_b.boss_data.bullet*global.monster_damage_multiplier);
            _b.boss_wave_left--; _b.boss_wave_timer=0.28;
        }
    }
    if(_b.boss_timer<=0) {
        if(_b.boss_state=="windup") {
            if(_b.boss_cast=="fan") {
                boss_fan_pattern(_b,_b.boss_cast_angle,_b.boss_fan_count,14,_b.boss_phase==1 ? 130 : 165,_b.boss_data.bullet*global.monster_damage_multiplier);
                if(_b.boss_phase==2) {_b.boss_wave_left=1+min(1,max(0,_b.boss_data.tier-3)); _b.boss_wave_timer=0.28;}
            }
            if(_b.boss_cast=="ring") boss_ring_pattern(_b,_b.boss_cast_angle);
            _b.boss_state="recovery"; _b.boss_timer=_b.boss_phase==1 ? 1.0 : 0.8;
        } else {
            var rotation=_b.boss_id=="mini_sentinel" ? ["lightning","lob","lightning"] : (_b.boss_data.main ? (_b.boss_phase==1 ? ["lightning","fan","lob","fan"] : ["lightning","fan","lob","ring","fan"]) : ["fan","lightning","fan"]);
            var pattern=rotation[_b.boss_rotation mod array_length(rotation)];
            _b.boss_rotation++;
            boss_attack_begin(_b,pattern);
        }
    }
    // Bosses stop while telegraphing. Recovery offers a stable melee attack window.
    if(_b.boss_state=="recovery" && instance_exists(ObjectPlayer)) {
        var dist=point_distance(_b.x,_b.y,ObjectPlayer.x,ObjectPlayer.y);
        if(dist>_b.body_radius+45) {
            var dir=point_direction(_b.x,_b.y,ObjectPlayer.x,ObjectPlayer.y);
            var factor=(_b.slow_time>0 ? _b.slow_factor : 1)*(_b.shock_time>0 ? 0.8 : 1);
            var blend=1-exp(-4*_dt);
            _b.chase_vx=lerp(_b.chase_vx,lengthdir_x(65*factor,dir),blend);_b.chase_vy=lerp(_b.chase_vy,lengthdir_y(65*factor,dir),blend);
            _b.x+=_b.chase_vx*_dt; _b.y+=_b.chase_vy*_dt;
            _b.x=clamp(_b.x,_b.body_radius,room_width-_b.body_radius);_b.y=clamp(_b.y,_b.visual_height,room_height-24);
        }
    }
    var action=_b.boss_state=="windup" ? "attack" : (_b.boss_state=="recovery" ? "walk" : "idle");
    var key="spr_fg_"+_b.boss_data.species+"_"+action;
    if(_b.monster_visual_key!=key) {
        _b.monster_visual_key=key; _b.sprite_index=player_artpack_sprite(key); _b.image_index=0;
    }
    _b.image_speed=0;
    _b.image_index=(_b.image_index+_dt*6) mod sprite_get_number(_b.sprite_index);
    if(instance_exists(ObjectPlayer) && abs(ObjectPlayer.x-_b.x)>35) _b.image_xscale=ObjectPlayer.x<_b.x ? -1 : 1;
    _b.depth=-_b.y;
}
function boss_point_segment_distance(_px,_py,_ax,_ay,_bx,_by) {
    var dx=_bx-_ax,dy=_by-_ay,den=dx*dx+dy*dy;
    var t=den>0 ? clamp(((_px-_ax)*dx+(_py-_ay)*dy)/den,0,1) : 0;
    return point_distance(_px,_py,_ax+dx*t,_ay+dy*t);
}
function boss_hazards_step(_dt) {
    if(global.game_paused || global.game_over) return;
    var pl=instance_exists(ObjectPlayer) ? ObjectPlayer : noone;
    for(var i=array_length(global.hostile_bullets)-1;i>=0;i--) {
        var b=global.hostile_bullets[i];
        if(!instance_exists(b.owner)) {array_delete(global.hostile_bullets,i,1); continue;}
        var old_x=b.x,old_y=b.y;
        b.x+=b.vx*_dt; b.y+=b.vy*_dt; b.age+=_dt;
        var remove=b.age>=b.life || b.x<0 || b.y<0 || b.x>room_width || b.y>room_height;
        var spit=variable_struct_exists(b,"bv2_kind") && b.bv2_kind=="swamp_spit";
        if(spit){b.travelled+=point_distance(old_x,old_y,b.x,b.y);if(b.travelled>=b.range)remove=true;}
        if(!remove && instance_exists(pl) && boss_point_segment_distance(pl.x,pl.y-10,old_x,old_y,b.x,b.y)<=b.radius+pl.contact_radius) {
            var damaged=spit ? false : player_receive_damage(pl,b.damage,"high");
            if(variable_struct_exists(b,"wind") && b.wind && damaged){var px=pl.x,py=pl.y;pl.x=clamp(pl.x+b.vx*.35,16,room_width-16);pl.y=clamp(pl.y+b.vy*.35,16,room_height-16);scenery_resolve(pl,px,py);}
            if(variable_struct_exists(b,"dragon_void")){class_fx_burst(b.x,b.y,48,3);light_pulse(b.x,b.y,160,make_color_rgb(178,105,255),.8,.2);}
            remove=true;
        }
        if(remove){if(spit){var splash=bv2_zone(b.owner,"swamp_spit",b.x,b.y,max(35,b.splash_radius),0,.18,b.damage,"all");splash.poison=b.poison;}array_delete(global.hostile_bullets,i,1);}
    }
}
function boss_world_step(_dt) {
    if(global.game_paused || global.game_over || !global.round_active) return;
    global.round_seconds+=_dt;
    global.boss_victory_time=max(0,global.boss_victory_time-_dt);
    boss_schedule_step();
    var combat_time_scale=global.boss_dev_enabled ? global.boss_dev_speed : 1;
    var combat_dt=min(_dt,1/15)*combat_time_scale; // Hitches cannot consume a new telegraph in one frame.
    var b=instance_exists(global.active_boss) ? global.active_boss : noone;
    if(instance_exists(b)) boss_step(b,combat_dt);
    boss_hazards_step(combat_dt);
    bv2_hazards_step(combat_dt);
    if(instance_exists(ObjectPlayer))bv2_status_step(ObjectPlayer,combat_dt);
    if(global.boss_dev_enabled) boss_dev_controls();
}
/// Shared hostile projectiles of every boss (zones and announcements are bv2 hazards since 27.11.).
function boss_hazards_draw() {
    if(!variable_global_exists("hostile_bullets")) return;
    draw_set_alpha(1);
    for(var i=0;i<array_length(global.hostile_bullets);i++) {
        var b=global.hostile_bullets[i];
        if(variable_struct_exists(b,"bv2_kind")){
            var angle=point_direction(0,0,b.vx,b.vy);
            if(b.bv2_kind=="twins_fire" || b.bv2_kind=="twins_ice")vfx_element_orb(b.x,b.y,30,angle,b.bv2_kind=="twins_ice" ? 2 : 1); // pixel orb instead of the scaled painted sprite
            else bv2_fx(b.bv2_kind,.2+frac(b.age)*.25,b.x,b.y,30,angle);
            continue;
        }
        if(variable_struct_exists(b,"dragon_void")){dragon_fx_sprite(b.wind ? 3 : (b.volley ? 7 : 4),.125+frac(b.age)*.25,b.x,b.y,b.wind ? 42 : 24,point_direction(0,0,b.vx,b.vy));continue;}
        draw_set_color(make_color_rgb(255,81,136)); draw_circle(b.x,b.y,b.radius+2,false);
        draw_set_color(make_color_rgb(255,234,243)); draw_circle(b.x,b.y,b.radius-1,false);
    }
    draw_set_alpha(1); draw_set_color(c_white);
}
function boss_hud_draw(_x,_y,_width) {
    if(!instance_exists(global.active_boss)) {
        if(global.boss_victory_time>0) {
            draw_set_color(make_color_rgb(232,204,133)); draw_text_ext(_x,_y,"BESIEGT: "+global.boss_victory_name,18,_width);
        }
        return;
    }
    var b=global.active_boss;
    draw_set_color(make_color_rgb(235,210,165));
    draw_text(_x,_y,b.boss_data.name+"  / "+string(b.boss_phase));
    var ratio=clamp(b.hp/b.max_hp,0,1),by=_y+21;
    draw_set_color(make_color_rgb(92,61,76));draw_rectangle(_x,by,_x+_width,by+6,true);
    draw_set_alpha(0.4);draw_set_color(make_color_rgb(42,19,30));draw_rectangle(_x+1,by+1,_x+_width-1,by+5,false);draw_set_alpha(1);
    if(ratio>0) {draw_set_color(make_color_rgb(209,78,112));draw_rectangle(_x+1,by+1,_x+(_width-2)*ratio,by+5,false);}
    var label=b.boss_state=="transition" ? "PHASENWECHSEL" : (b.boss_state=="windup" ? b.boss_cast : "");
    if(b.dragon_enabled && b.boss_state=="windup")label=dragon_pattern_label(b.boss_cast);
    draw_set_halign(fa_right);draw_set_color(make_color_rgb(234,180,198));draw_text(_x+_width,_y,label);draw_set_halign(fa_left);draw_set_color(c_white);
}
/// Development APIs are inert in normal builds without --boss-dev or the debugger.
function boss_dev_start(_id="storm_warden",_phase=1,_hp_fraction=1,_speed=1) {
    if(!global.boss_dev_enabled) return noone;
    if(instance_exists(global.active_boss)) {var old=global.active_boss; boss_cleanup(old); with(old) instance_destroy();}
    var b=boss_spawn(_id);
    if(instance_exists(b)) {
        b.boss_phase=clamp(_phase,1,b.dragon_enabled ? 4 : 2); b.hp=max(1,b.max_hp*clamp(_hp_fraction,0.01,1));
        global.boss_dev_speed=clamp(_speed,0.1,1);
    }
    return b;
}
function boss_dev_controls() {
    if(!global.boss_dev_enabled) return;
    if(keyboard_check_pressed(vk_f6)) {
        var defs=boss_definitions(); boss_dev_start(defs[global.boss_dev_index].id);
        global.boss_dev_index=(global.boss_dev_index+1) mod array_length(defs);
    }
    if(keyboard_check_pressed(vk_f7) && instance_exists(global.active_boss)) global.active_boss.hp=global.active_boss.max_hp*0.49;
    if(keyboard_check_pressed(vk_f8) && instance_exists(global.active_boss)) {
        var patterns=global.active_boss.dragon_enabled ? ["beam","arc","meteor","slam","wind","void","stomp","vortex","volley"] : ["lightning","fan","lob","ring"];
        boss_attack_begin(global.active_boss,patterns[global.boss_dev_pattern]);
        global.boss_dev_pattern=(global.boss_dev_pattern+1) mod array_length(patterns);
    }
    if(keyboard_check_pressed(vk_f9)) global.boss_dev_speed=global.boss_dev_speed==1 ? 0.35 : 1;
}
