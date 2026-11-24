/// Timing and UI rules added without replacing the existing weapon/spell/audio systems.
function movement_config() {
    static cfg={jump_duration:0.66,jump_height:68,apex_window:0.080,dive_duration:0.10,
        slide_duration:0.30,slide_distance:135,slide_speed:9,dodge_duration:0.16,dodge_cooldown:1.5,
        dodge_iframes:0.10,landing_recovery:0.35,slide_recovery:0.65};
    return cfg;
}
function movement_step(_pl,_dt,_moving,_direction,_move_amount,_jump_press,_dodge_press) {
    var cfg=movement_config(),dt=min(max(0,_dt),0.05),started=false;
    var start_x=_pl.x,start_y=_pl.y;
    if(variable_instance_exists(_pl,"boss_root_time") && _pl.boss_root_time>0)_move_amount*=.25;
    _pl.invulnerable_timer=max(0,_pl.invulnerable_timer-dt*60);
    _pl.mobility_cooldown=max(0,_pl.mobility_cooldown-dt);
    _pl.dodge_cooldown=max(0,_pl.dodge_cooldown-dt);
    if(_pl.motion_state==player_motion_state.grounded && _pl.dodge_timer<=0 && _pl.mobility_cooldown<=0) {
        if(_dodge_press && _pl.dodge_cooldown<=0) {
            _pl.dodge_direction=_moving ? _direction : _pl.facing_direction;
            _pl.dodge_timer=cfg.dodge_duration;_pl.dodge_elapsed=0;_pl.dodge_cooldown=cfg.dodge_cooldown;fg_sfx("dodge");
        } else if(_jump_press) {
            _pl.jump_direction=_moving ? _direction : _pl.facing_direction;
            _pl.motion_state=player_motion_state.rising;_pl.jump_time=0;_pl.jump_second_used=false;started=true;fg_sfx("jump");
        }
    }
    if(_pl.dodge_timer>0) {
        _pl.x+=lengthdir_x(510*dt,_pl.dodge_direction);_pl.y+=lengthdir_y(510*dt,_pl.dodge_direction);
        _pl.dodge_timer=max(0,_pl.dodge_timer-dt);_pl.dodge_elapsed+=dt;
        if(_pl.dodge_timer<=0) _pl.mobility_cooldown=max(_pl.mobility_cooldown,cfg.landing_recovery);
    } else if(_pl.motion_state==player_motion_state.grounded) {
        if(_moving) {_pl.x+=lengthdir_x(_move_amount*60*dt,_direction);_pl.y+=lengthdir_y(_move_amount*60*dt,_direction);}
    } else if(_pl.motion_state==player_motion_state.rising || _pl.motion_state==player_motion_state.falling) {
        var input_time=_pl.jump_time;
        _pl.jump_time+=dt;_pl.jump_elapsed=_pl.jump_time*60;
        if(_moving) _pl.jump_direction=_direction;
        _pl.x+=lengthdir_x(_pl.moveSpeed*1.25*60*dt,_pl.jump_direction);_pl.y+=lengthdir_y(_pl.moveSpeed*1.25*60*dt,_pl.jump_direction);
        var progress=clamp(_pl.jump_time/cfg.jump_duration,0,1);
        _pl.jump_height=4*cfg.jump_height*progress*(1-progress);
        _pl.motion_state=progress<0.5 ? player_motion_state.rising : player_motion_state.falling;
        if(!started && _jump_press && !_pl.jump_second_used) {
            _pl.jump_second_used=true;
            if(abs(input_time-cfg.jump_duration*0.5)<=cfg.apex_window*0.5+0.000001) {
                _pl.motion_state=player_motion_state.diving;_pl.dive_direction=_pl.jump_direction;
                _pl.dive_time=0;_pl.dive_start_height=_pl.jump_height;
            }
        }
        if(progress>=1) {
            _pl.jump_height=0;_pl.jump_time=0;_pl.motion_state=player_motion_state.grounded;
            _pl.mobility_cooldown=cfg.landing_recovery;
        }
    } else if(_pl.motion_state==player_motion_state.diving) {
        _pl.dive_time+=dt;
        _pl.x+=lengthdir_x(_pl.moveSpeed*1.5*60*dt,_pl.dive_direction);_pl.y+=lengthdir_y(_pl.moveSpeed*1.5*60*dt,_pl.dive_direction);
        _pl.jump_height=lerp(_pl.dive_start_height,0,clamp(_pl.dive_time/cfg.dive_duration,0,1));
        if(_pl.dive_time>=cfg.dive_duration) {
            _pl.jump_height=0;_pl.motion_state=player_motion_state.sliding;_pl.slide_timer=0;
            _pl.slide_remaining=cfg.slide_distance;_pl.slide_speed=cfg.slide_speed;_pl.slide_direction=_pl.dive_direction;fg_sfx("slide");
        }
    } else if(_pl.motion_state==player_motion_state.sliding) {
        var distance=min(_pl.slide_remaining,_pl.slide_speed*60*dt);
        _pl.x+=lengthdir_x(distance,_pl.slide_direction);_pl.y+=lengthdir_y(distance,_pl.slide_direction);
        _pl.slide_remaining-=distance;_pl.slide_speed=max(0,_pl.slide_speed-dt*12);_pl.slide_timer+=dt;
        if(_pl.slide_timer>=cfg.slide_duration || _pl.slide_remaining<=0 || _pl.slide_speed<=0) {
            _pl.motion_state=player_motion_state.grounded;_pl.slide_remaining=0;_pl.slide_speed=0;
            _pl.mobility_cooldown=cfg.slide_recovery;
        }
    }
    var old_x=_pl.x,old_y=_pl.y;
    _pl.x=clamp(_pl.x,_pl.collision_half_width,room_width-_pl.collision_half_width);
    _pl.y=clamp(_pl.y,_pl.collision_half_height,room_height-_pl.collision_half_height);
    scenery_resolve(_pl,start_x,start_y);
    if(_pl.motion_state==player_motion_state.sliding && (_pl.x!=old_x || _pl.y!=old_y)) {
        _pl.motion_state=player_motion_state.grounded;_pl.mobility_cooldown=cfg.slide_recovery;
    }
}
function player_health_draw() {
    if(health_visible_time<=0) return;
    var xx=x-31,yy=y-jump_height-68;
    draw_set_alpha(1);draw_set_color(make_color_rgb(12,17,24));draw_rectangle(xx-2,yy-2,xx+64,yy+7,false);
    draw_set_color(make_color_rgb(219,193,137));draw_rectangle(xx-2,yy-2,xx+64,yy+7,true);
    draw_set_color(make_color_rgb(224,173,73));draw_rectangle(xx,yy,xx+60*clamp(hud_hp_trail/max_hp,0,1),yy+5,false);
    draw_set_color(make_color_rgb(213,64,82));draw_rectangle(xx,yy,xx+60*clamp(hp/max_hp,0,1),yy+5,false);
    draw_set_halign(fa_center);draw_set_valign(fa_bottom);draw_set_color(c_white);
    draw_text(x,yy-4,string(ceil(hp))+" / "+string(max_hp));
    if(hud_hit_flash>0) {draw_set_color(make_color_rgb(255,130,112));draw_text(x+50,yy-4,"-"+string_format(last_damage_taken,0,0));}
    draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_color(c_white);
}
function format_round_time(_seconds) {
    var seconds=max(0,floor(_seconds)),minutes=seconds div 60;
    return (minutes<10 ? "0" : "")+string(minutes)+":"+(seconds mod 60<10 ? "0" : "")+string(seconds mod 60);
}

function ui_modal_draw() {
 shader_reset();gpu_set_texfilter(false);gpu_set_blendmode(bm_normal);draw_set_alpha(1);draw_set_font(-1);draw_set_halign(fa_left);draw_set_valign(fa_top);
 if(!global.game_paused)return;
 if(global.game_over || global.normal_pause_active){round_menu_draw();return;}
 if(global.chest_collected || global.levelup_active)spell_choices_draw();
}

/// Explicit electrical chain: no projectile multiplier and no repeated target per cast.
function cast_chain_lightning(_first,_damage,_targets,_hop_range,_owner) {
    var visited=[],target=_first,ax=_owner.x,ay=_owner.y-12;
    repeat(_targets) {
        if(!instance_exists(target) || target.hp<=0 || !combat_target_visible(target)) break;
        var bx=target.x,by=target.y-12;
        array_push(visited,target.id);
        apply_attack_damage(target,_damage,_owner,SPELL.LIGHTNING);target.shock_time=max(target.shock_time,round(GetSpellData(SPELL.LIGHTNING).shock_time*_owner.status_factor));impact_add(target.x,target.y-12,"arcane");
        spell_fx_burst(bx,by,72,3,.3);light_pulse(bx,by,185,make_color_rgb(115,193,255),.8,.22);
        if(array_length(visited)==1)array_push(global.chain_segments,{ax:bx-26,ay:by-220,bx:bx,by:by,life:.28});
        if(array_length(global.chain_segments)>=96) array_delete(global.chain_segments,0,1);
        array_push(global.chain_segments,{ax:ax,ay:ay,bx:bx,by:by,life:0.28});
        ax=bx;ay=by;
        var next_target=noone,best=_hop_range+0.001,types=[ObjectMonster,ObjectBossMonster];
        for(var t=0;t<2;t++) for(var i=0;i<instance_number(types[t]);i++) {
            var e=instance_find(types[t],i);
            if(e.hp<=0 || array_contains(visited,e.id) || !combat_target_visible(e)) continue;
            var dist=point_distance(ax,ay,e.x,e.y-12);
            if(dist<best) {best=dist;next_target=e;}
        }
        target=next_target;
    }
    return array_length(visited);
}
function chain_visual_step(_dt) {
    for(var i=array_length(global.chain_segments)-1;i>=0;i--) {
        global.chain_segments[i].life-=_dt;
        if(global.chain_segments[i].life<=0) array_delete(global.chain_segments,i,1);
    }
}
function chain_visual_draw() {
    for(var i=0;i<array_length(global.chain_segments);i++) {
        var e=global.chain_segments[i],last_x=e.ax,last_y=e.ay;
        draw_set_alpha(clamp(e.life/0.28,0,1));
        for(var part=1;part<=7;part++) {
            var next_x=lerp(e.ax,e.bx,part/7),next_y=lerp(e.ay,e.by,part/7);
            if(part<7) {next_x+=((part+i) mod 2==0 ? 3 : -3);next_y+=((part*3+i) mod 2==0 ? 2 : -2);}
            draw_set_color(make_color_rgb(61,117,234));draw_line_width(last_x,last_y,next_x,next_y,10);
            draw_set_color(make_color_rgb(105,206,255));draw_line_width(last_x,last_y,next_x,next_y,5);
            draw_set_color(make_color_rgb(242,254,255));draw_line_width(last_x,last_y,next_x,next_y,2);
            last_x=next_x;last_y=next_y;
        }
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
function draw_upgrade_orbs(_x,_y,_level,_spacing=9,_color=12642292) {
    var level=clamp(floor(_level),0,9);
    for(var i=0;i<9;i++) {
        var xx=_x+i*_spacing;
        if(i<level) {
            draw_set_color(make_color_rgb(47,82,106));draw_circle(xx,_y,4,false);
            draw_set_color(_color);draw_circle(xx,_y,2.5,false);
            draw_set_color(make_color_rgb(239,252,255));draw_point(xx-1,_y-1);
        } else {draw_set_color(make_color_rgb(41,48,62));draw_circle(xx,_y,2.5,false);}
    }
    draw_set_color(c_white);
}
function pause_geometry() {
    var w=display_get_gui_width(),h=display_get_gui_height();
    return {x:18,y:84,w:w*0.22,h:48,gap:14,character_x:w*0.36,ability_x:w*0.55,
        ability_w:w*0.45-18,ability_y:76,row:min(35,(h-140)/12)};
}
function pause_inventory_draw(){spell_pause_draw();}

function hud_minimap() {
    if(!global.minimap_visible || !instance_exists(ObjectPlayer)) return;
    var size=100,xx=display_get_gui_width()-size-14,yy=display_get_gui_height()-size-36;
    draw_set_alpha(0.26);draw_set_color(make_color_rgb(18,30,33));draw_rectangle(xx,yy,xx+size,yy+size,false);
    draw_set_alpha(0.65);draw_set_color(make_color_rgb(164,183,171));draw_rectangle(xx,yy,xx+size,yy+size,true);
    var r=combat_view_rect();
    draw_set_alpha(0.45);draw_set_color(make_color_rgb(179,200,194));
    draw_rectangle(xx+r.left/room_width*size,yy+r.top/room_height*size,xx+r.right/room_width*size,yy+r.bottom/room_height*size,true);
    draw_set_alpha(1);draw_set_color(make_color_rgb(128,240,243));
    draw_circle(xx+clamp(ObjectPlayer.x/room_width,0,1)*size,yy+clamp(ObjectPlayer.y/room_height,0,1)*size,2.5,false);
    draw_set_color(c_white);
}
function spell_upgrade_summary(_sid,_level){return spell_upgrade_v2(_sid,_level);}

function element_tint(_e) {
    var color=c_white;
    if(_e.burn_time>0) color=merge_color(color,make_color_rgb(255,157,89),0.18);
    if(_e.slow_time>0) color=merge_color(color,make_color_rgb(140,215,255),0.20);
    if(_e.shock_time>0) color=merge_color(color,make_color_rgb(163,202,255),0.16+0.10*((current_time div 90) mod 2));
    return color;
}
function element_glow(_e) {
    if(_e.burn_time<=0 && _e.slow_time<=0 && _e.shock_time<=0) return;
    var color=_e.burn_time>0 ? make_color_rgb(255,128,44) : make_color_rgb(100,187,255);
    gpu_set_blendmode(bm_add);draw_set_color(color);
    for(var radius=24;radius>=12;radius-=6) {draw_set_alpha(0.035);draw_circle(_e.x,_e.y-10,radius,false);}
    gpu_set_blendmode(bm_normal);draw_set_alpha(1);draw_set_color(c_white);
}
