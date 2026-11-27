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
    _move_amount*=level_speed_factor_for(_pl); // Mud / magical ice: ground movement only, jumps and dodges unchanged.
    _pl.invulnerable_timer=max(0,_pl.invulnerable_timer-dt*60);
    _pl.mobility_cooldown=max(0,_pl.mobility_cooldown-dt);
    _pl.dodge_cooldown=max(0,_pl.dodge_cooldown-dt);
    if(_pl.motion_state==player_motion_state.grounded && _pl.dodge_timer<=0 && _pl.mobility_cooldown<=0) {
        if(_dodge_press && _pl.dodge_cooldown<=0) {
            _pl.dodge_direction=_moving ? _direction : _pl.facing_direction;
            _pl.dodge_timer=cfg.dodge_duration;_pl.dodge_elapsed=0;_pl.dodge_cooldown=max(.6,cfg.dodge_cooldown-talent_stat("dodge_cd")-equipment_stat("dodge_cd"));fg_sfx("dodge");
            _pl.sword_charge_until=global.round_seconds+1.5+cfg.dodge_duration;
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
 if(!global.game_paused){feedback_toast_draw();return;}
 if(variable_global_exists("talent_menu_active") && global.talent_menu_active){talent_menu_draw();return;}
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
        // Visual band from the spell level (docs/Design/Fähigkeiten, VFX & Audio.md 4): compact at 1-3, full at 7-9.
        var band=vfx_spell_band(SPELL.LIGHTNING);
        if(band==2)spell_fx_burst(bx,by,56,3,.3,2); else if(band==1)spell_fx_burst(bx,by,34,3,.24,1);
        light_pulse(bx,by,band==2 ? 150 : (band==1 ? 130 : 110),make_color_rgb(115,193,255),band==0 ? .5 : .55,.22);
        if(array_length(visited)==1)chain_segment_add(bx-26,by-(band==0 ? 160 : 220),bx,by,band,true);
        chain_segment_add(ax,ay,bx,by,band);
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
/// Lightning (spell 103) as a composite pixel effect in three visual bands (docs/Design/Fähigkeiten, VFX & Audio.md 2/4).
/// Purely visual: damage, targets, hop range and timing are unchanged.
/// Band from the spell level: 1-3 basis, 4-6 middle, 7-9 endgame.
function vfx_band(_level) {return _level>=7 ? 2 : (_level>=4 ? 1 : 0);}
/// Intensity of a band: basis .55, middle .8, endgame 1 (alpha/glow multiplier, never the hit radius).
function vfx_band_alpha(_band) {return _band<=0 ? .55 : (_band==1 ? .8 : 1);}
/// Band of a learned spell; global.vfx_band_override (0-2) forces a band for previews and capture tests.
function vfx_spell_band(_sid) {return variable_global_exists("vfx_band_override") ? global.vfx_band_override : vfx_band(spell_level(_sid));}
/// Deterministic hash in [-1,1] (no global RNG: seeded runs stay comparable).
function vfx_hash(_a,_b) {var v=sin(_a*12.9898+_b*78.233)*43758.5453;return (v-floor(v))*2-1;}
/// One chain segment: a jagged core regenerated every 45 ms, short branches, impact cross, sparks.
function chain_segment_add(_ax,_ay,_bx,_by,_band,_strike=false) {
    if(array_length(global.chain_segments)>=96)array_delete(global.chain_segments,0,1);
    var life=_band==2 ? .3 : (_band==1 ? .26 : .22);
    array_push(global.chain_segments,{ax:_ax,ay:_ay,bx:_bx,by:_by,life:life,total:life,band:_band,seed:random_seed_free(),strike:_strike});
    // Player lightning: a strike flashes with the band (basis small, endgame lifts the scene a little); never every hop.
    // softened 27.11.: the endgame strike washed the boss out white (own effects stay below boss dangers, Kampf 8)
    if(_strike && _band>=1)light_flash(_bx,_by,_band==2 ? 210 : 150,make_color_rgb(190,215,255),_band==2 ? 1.1 : .9,.22,_band==2 ? .08 : 0,.25);
    // graphics overhaul: a strike lands with a white core, crackling spark lines and a shock ring; every hop sparks
    if(_strike){fxp_impact(_bx,_by,3,.35+.25*_band);if(_band>=2)fx_aberration(1.5,.12);}
    else repeat(fxp_n(2+_band)){var a2=vfx_random(360);fxp_add(_bx,_by,lengthdir_x(180,a2),lengthdir_y(180,a2),vfx_random_range(.06,.14),3,1,FXP_STREAK,FXP_EMIT,0,4,0);}
    // Sparks at the struck point (pixel particles, count by band).
    var n=_band==2 ? 10 : (_band==1 ? 6 : 3);
    for(var i=0;i<n;i++) {
        var a=point_direction(_ax,_ay,_bx,_by)+180+vfx_hash(i,_bx)*80,sp=70+abs(vfx_hash(_by,i))*110;
        spell_particle(_bx,_by,lengthdir_x(sp,a),lengthdir_y(sp,a)-20,.14+abs(vfx_hash(i,_by))*.16,1+(_band>=1 && i mod 3==0),i mod 2==0 ? c_white : make_color_rgb(140,214,255),4,160);
    }
}
/// Seed without touching the global random state.
function random_seed_free() {if(!variable_global_exists("vfx_seed_counter"))global.vfx_seed_counter=0;global.vfx_seed_counter=(global.vfx_seed_counter+1) mod 100000;return global.vfx_seed_counter*7.31;}
function chain_bolt_points(_e,_tick,_amp) {
    var len=point_distance(_e.ax,_e.ay,_e.bx,_e.by),n=clamp(round(len/20),4,14),dir=point_direction(_e.ax,_e.ay,_e.bx,_e.by);
    var nx=lengthdir_x(1,dir+90),ny=lengthdir_y(1,dir+90),pts=[];
    for(var p=0;p<=n;p++) {
        var t=p/n,off=(p==0 || p==n) ? 0 : vfx_hash(_e.seed+p,_tick)*_amp*(1-abs(t-.5)*1.2);
        array_push(pts,[round(lerp(_e.ax,_e.bx,t)+nx*off),round(lerp(_e.ay,_e.by,t)+ny*off)]);
    }
    return pts;
}
function chain_polyline(_pts,_w) {for(var p=1;p<array_length(_pts);p++)draw_line_width(_pts[p-1][0],_pts[p-1][1],_pts[p][0],_pts[p][1],_w);}
function chain_visual_draw() {
    if(!variable_global_exists("chain_segments"))return;
    var tick=floor(current_time/45);gpu_set_blendmode(bm_add);
    for(var i=0;i<array_length(global.chain_segments);i++) {
        var e=global.chain_segments[i],b=variable_struct_exists(e,"band") ? e.band : 1,tot=variable_struct_exists(e,"total") ? e.total : .28;
        if(!variable_struct_exists(e,"seed"))e.seed=i*3.7;
        var k=clamp(e.life/tot,0,1),age=tot-e.life,amp=b==2 ? 9 : (b==1 ? 7 : 5);
        var pts=chain_bolt_points(e,tick,amp);
        // Glow: none at basis, soft at middle, wide double glow at endgame.
        if(b>=1){draw_set_color(make_color_rgb(40,86,200));draw_set_alpha(.30*k);chain_polyline(pts,b==2 ? 9 : 6);}
        if(b==2){draw_set_color(make_color_rgb(70,140,255));draw_set_alpha(.18*k);chain_polyline(pts,15);}
        draw_set_color(make_color_rgb(120,206,255));draw_set_alpha(.95*k);chain_polyline(pts,b==2 ? 3 : 2);
        if(b>=1){draw_set_color(c_white);draw_set_alpha(k);chain_polyline(pts,1);}
        // Branches: short forks, only in the first 60 % of the life.
        if(age<tot*.6) {
            var forks=b==2 ? 4 : (b==1 ? 2 : 1);
            for(var f=0;f<forks;f++) {
                var at=1+floor(abs(vfx_hash(e.seed,f+tick))*(array_length(pts)-2)),p0=pts[at];
                var dir=point_direction(e.ax,e.ay,e.bx,e.by)+(f mod 2==0 ? 1 : -1)*(40+abs(vfx_hash(f,e.seed))*35);
                var l1=10+abs(vfx_hash(tick,f))*(8+b*6),q1=[round(p0[0]+lengthdir_x(l1,dir)),round(p0[1]+lengthdir_y(l1,dir))];
                var q2=[round(q1[0]+lengthdir_x(l1*.6,dir+vfx_hash(f,tick)*40)),round(q1[1]+lengthdir_y(l1*.6,dir+vfx_hash(f,tick)*40))];
                draw_set_color(make_color_rgb(150,220,255));draw_set_alpha(.8*k);chain_polyline([p0,q1,q2],1);
            }
        }
        // Impact cross on the struck point for the first 80 ms.
        if(age<.08){var s=b==2 ? 7 : (b==1 ? 5 : 3),cx=round(e.bx),cy=round(e.by);draw_set_color(c_white);draw_set_alpha(1);draw_rectangle(cx-s,cy,cx+s,cy,false);draw_rectangle(cx,cy-s,cx,cy+s,false);}
    }
    gpu_set_blendmode(bm_normal);draw_set_alpha(1);draw_set_color(c_white);
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
/// Row pitch of the pause list: 62 px, compressed only when _count rows would reach the help lines at the bottom
/// (review scenarios with both verdict rows). The normal pause menu keeps 62.
function pause_row_pitch(_count) {var ui=pause_geometry(),bottom=display_get_gui_height()-80;return (_count<2 || ui.y+(_count-1)*62+ui.h<=bottom) ? 62 : max(ui.h+4,floor((bottom-ui.h-ui.y)/(_count-1)));}
function pause_inventory_draw(){spell_pause_draw();}

function hud_minimap() {
    if(!global.minimap_visible || !instance_exists(ObjectPlayer)) return;
    var size=100,xx=display_get_gui_width()-size-14,yy=display_get_gui_height()-size-36;
    draw_set_alpha(0.26);draw_set_color(make_color_rgb(18,30,33));draw_rectangle(xx,yy,xx+size,yy+size,false);
    if(level_generated())level_minimap_draw(xx,yy,size);
    equipment_minimap_draw(xx,yy,size);
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
