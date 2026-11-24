/// First main encounter only. Locked telegraphs, bounded boss-specific hazards and animation clock.
function dragon_config() {
    static cfg={beam_length:1200,sweep_length:650,arc_length:360,beam_width:48,
        beam_time:1.0,sweep_time:1.45,arc_time:0.7,warning:1.2,hit_interval:0.35,
        beam_damage:36,sweep_damage:30,arc_damage:36,magma_damage:64,
        magma_radius:125,magma_warning:1.05,magma_active:0.55,death_time:1.4};
    return cfg;
}
function dragon_init(_b) {
    _b.dragon_enabled=_b.boss_id=="storm_warden";
    if(!_b.dragon_enabled) return;
    _b.dragon_clock=0;_b.dragon_state_age=0;_b.dragon_cycle=0;
    _b.dragon_facing=-1;_b.dragon_angle=180;_b.dragon_base_angle=180;
    _b.dragon_next_hit=0;_b.dragon_magma=[];_b.dragon_dying=false;_b.dragon_hit_age=99;
    _b.dragon_last_hp=_b.hp;_b.dragon_anim="idle";_b.dragon_frame=0;
    _b.enc_zones=[];_b.enc_hits=0;_b.enc_waves=0;
    _b.boss_timer=2;_b.boss_state="intro";
}
function dragon_state(_b,_state,_duration) {_b.boss_state=_state;_b.boss_timer=_duration;_b.dragon_state_age=0;}
function dragon_fire_pose(_b) {
    if(variable_instance_exists(_b,"dragon_pose_locked") && _b.dragon_pose_locked && _b.boss_cast=="beam")return _b.dragon_locked_pose;
    var vertical=sin(degtorad(_b.dragon_angle));
    return {action:vertical>0.38 ? "breath_up" : (vertical< -0.38 ? "breath_down" : "breath"),frame:vertical< -0.15 && vertical>=-0.38 ? 1 : 0};
}
function dragon_mouth(_b,_fire_pose=false) {
    var a=_fire_pose ? dragon_fire_pose(_b) : dragon_animation(_b),anchor=dragon_art_anchor(a.action,a.frame);
    var size=_b.visual_height/430,breath=sin(_b.dragon_clock*3.4);
    return {x:_b.x+_b.dragon_facing*anchor[0]*size*(1+breath*0.008),y:_b.y+anchor[1]*size*(1+breath*0.012)};
}
function dragon_pattern_label(_pattern) {
    switch(_pattern) {case "beam":return "FEUERSTRAHL";case "sweep":return "FEUERSCHWENK";case "arc":return "FEUERBOGEN";case "stomp":return "MAGMAERUPTION";case "meteor":return "METEORITENREGEN";case "slam":return "BODENEINSCHLAG";case "wind":return "FLUEGELSTURM";case "void":return "VOID-ORBS";case "vortex":return "FEUERWIRBEL";case "volley":return "VOID-SALVEN";}
    return _pattern;
}
function dragon_attack_begin(_b,_pattern) {dragon_encounter_begin(_b,_pattern);}
function dragon_attack_duration(_b) {return dragon_encounter_config(_b.boss_cast,_b.boss_phase).active;}
function dragon_attack_geometry(_b) {
    var cfg=dragon_config(),mouth=dragon_mouth(_b,true);
    if(_b.boss_cast=="beam" && variable_instance_exists(_b,"dragon_origin_x"))mouth={x:_b.dragon_origin_x,y:_b.dragon_origin_y};
    var len=_b.boss_cast=="beam" ? (variable_instance_exists(_b,"dragon_beam_length") ? _b.dragon_beam_length : cfg.beam_length) : (_b.boss_cast=="sweep" ? cfg.sweep_length : cfg.arc_length);
    return {x:mouth.x,y:mouth.y,ex:mouth.x+lengthdir_x(len,_b.dragon_angle),ey:mouth.y+lengthdir_y(len,_b.dragon_angle),
        angle:_b.dragon_angle,length:len,width:cfg.beam_width};
}
function dragon_player_in_fire(_b,_pl) {
    var g=dragon_attack_geometry(_b);
    if(_b.boss_cast=="arc") {
        var distance=point_distance(g.x,g.y,_pl.x,_pl.y-10),heading=point_direction(g.x,g.y,_pl.x,_pl.y-10);
        return distance<=g.length+_pl.contact_radius && (distance<18 || abs(angle_difference(heading,g.angle))<=18);
    }
    return boss_point_segment_distance(_pl.x,_pl.y-10,g.x,g.y,g.ex,g.ey)<=g.width*0.5+_pl.contact_radius;
}
function dragon_step(_b,_dt) {dragon_encounter_step(_b,_dt);}
function dragon_die(_b) {
    if(_b.dragon_dying) return;
    _b.dragon_dying=true;_b.dragon_magma=[];_b.damage=0;
    dragon_state(_b,"dying",dragon_config().death_time);
    boss_reward_once(_b); // Chest and exactly one orb at actual HP death, not animation completion.
}
function dragon_death_step(_b,_dt) {
    if(global.game_paused) return;
    _b.dragon_state_age+=_dt;_b.dragon_clock+=_dt;
    if(_b.dragon_state_age>=dragon_config().death_time) with(_b) instance_destroy();
}
function dragon_animation(_b) {
    var action="idle",frame=0,age=_b.dragon_state_age;
    if(!_b.dragon_dying && (_b.boss_state=="windup" || _b.boss_state=="active")) {
        var extra="",progress=_b.boss_state=="windup" ? age/max(.001,_b.enc_cfg.warning) : age/max(.001,_b.enc_cfg.active);
        switch(_b.boss_cast) {
            case "wind":extra="wingbeat";break;
            case "slam":extra="leap";break;
            case "void":case "volley":case "vortex":extra="channel";break;
            case "meteor":extra="summon";break;
        }
        if(extra!="")return {action:extra,frame:extra=="wingbeat" && _b.boss_state=="active" ? floor(age*8) mod 4 : clamp(floor(progress*4),0,3),sprite:asset_get_index("spr_fg_dragonextra_"+extra)};
    }
    if(_b.dragon_dying) {action="death";frame=min(2,floor(age*3));}
    else if(_b.boss_state=="transition") {action="phase";frame=floor(age*5) mod 2;}
    else if(_b.boss_state=="stomp") {action="stomp";frame=1;}
    else if(_b.boss_state=="windup") {
        action=_b.boss_cast=="stomp" ? "stomp" : "charge";frame=_b.boss_cast=="stomp" ? 0 : min(1,floor(age*2));
    } else if(_b.boss_state=="active") {
        var fire_pose=dragon_fire_pose(_b);action=fire_pose.action;frame=fire_pose.frame;
    } else if(_b.dragon_hit_age<0.12) action="hurt";
    else if(_b.boss_state=="recovery" && point_distance(0,0,_b.chase_vx,_b.chase_vy)>8) {action="walk";frame=floor(_b.dragon_clock*6) mod 4;}
    else if(_b.boss_state=="recovery" && age<0.3) {action="turn";frame=floor(age*6) mod 2;}
    else frame=floor(_b.dragon_clock*4) mod 4;
    return {action:action,frame:frame,sprite:asset_get_index("spr_fg_dragonboss_"+action)};
}
function dragon_draw(_b) {
    var a=dragon_animation(_b),breath=sin(_b.dragon_clock*3.4),size=_b.visual_height/430;
    var sx=size*(1+breath*0.008),sy=size*(1+breath*0.012),alpha=_b.dragon_dying ? clamp((1.4-_b.dragon_state_age)*2,0,1) : 1;
    var lift=0;if(_b.boss_cast=="slam" && _b.boss_state=="windup")lift=sin(pi*clamp(_b.dragon_state_age/_b.enc_cfg.warning,0,1))*140;
    if(level_world_room())master_shadow_draw(_b.x,_b.y,100-lift*.25,25-lift*.08,.3);
    draw_sprite_ext(a.sprite,a.frame,_b.x,_b.y-lift,sx*_b.dragon_facing,sy,0,_b.hurt_flash_timer>0 ? make_color_rgb(255,208,180) : element_tint(_b),alpha);
    _b.dragon_anim=a.action;_b.dragon_frame=a.frame;draw_set_color(c_white);draw_set_alpha(1);
}
function dragon_sector_outline(_x,_y,_radius,_start,_span) {
    var px=_x+lengthdir_x(_radius,_start),py=_y+lengthdir_y(_radius,_start);
    draw_line_width(_x,_y,px,py,2);
    for(var i=1;i<=24;i++) {var a=_start+_span*i/24,xx=_x+lengthdir_x(_radius,a),yy=_y+lengthdir_y(_radius,a);draw_line_width(px,py,xx,yy,2);px=xx;py=yy;}
    draw_line_width(_x,_y,px,py,2);
}
function dragon_warning_edges(_g) {
    var nx=lengthdir_x(_g.width*0.5,_g.angle+90),ny=lengthdir_y(_g.width*0.5,_g.angle+90);
    return {ax:_g.x+nx,ay:_g.y+ny,bx:_g.ex+nx,by:_g.ey+ny,cx:_g.x-nx,cy:_g.y-ny,dx:_g.ex-nx,dy:_g.ey-ny};
}
function dragon_fire_sprite(_g,_angle,_length,_width,_frame,_alpha) {
    var cx=_g.x+lengthdir_x(_length*0.5,_angle),cy=_g.y+lengthdir_y(_length*0.5,_angle);
    draw_sprite_ext(spr_fg_dragonboss_flame,_frame,cx,cy,_length/128,_width/64,_angle,c_white,_alpha);
}
function dragon_vfx_draw(_b) {dragon_encounter_draw(_b);}
/// Editable mouth anchors from source pose annotations and import transform.
function dragon_art_anchor(_action,_frame) {
 static data={charge:[[160, -342.18], [170, -312.18]],breath_up:[[190, -362.18]],breath:[[200, -292.18], [225, -252.18]],breath_down:[[210, -230.8]]};
 if(!variable_struct_exists(data,_action))return [150,-300];
 var points=variable_struct_get(data,_action);return points[clamp(_frame,0,array_length(points)-1)];
}
