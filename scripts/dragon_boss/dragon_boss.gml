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
    if(variable_instance_exists(_b,"bc_catch") && is_struct(_b.bc_catch) && !_b.dragon_dying)return {action:"leap",frame:clamp(floor(_b.bc_catch.age/max(.01,_b.bc_catch.warning)*4),0,3),sprite:asset_get_index("spr_fg_dragonextra_leap")};
    // Close-range attacks use the idle frame family: there the rig has tail, neck and head bones.
    if(!_b.dragon_dying && (_b.boss_cast=="tail" || _b.boss_cast=="bite") && (_b.boss_state=="windup" || _b.boss_state=="active"))return {action:"idle",frame:floor(_b.dragon_clock*4) mod 4,sprite:spr_fg_dragonboss_idle};
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
    if(variable_instance_exists(_b,"bc_lift"))lift=max(lift,_b.bc_lift);
    if(level_world_room())master_shadow_draw(_b.x,_b.y,100-lift*.25,25-lift*.08,.3);
    var col=_b.hurt_flash_timer>0 ? make_color_rgb(255,208,180) : element_tint(_b);
    // Body rig on the original dragonboss frames (wings, tail, neck/head); extra poses keep the plain sprite.
    if(DRAGON_RIG_ENABLED && vfx_secondary_motion() && sprite_exists(a.sprite) && string_pos("spr_fg_dragonboss_",sprite_get_name(a.sprite))==1)dragon_rig_draw(_b,a.sprite,a.frame,a.action,_b.x,_b.y-lift,sx*_b.dragon_facing,sy,col,alpha);
    else draw_sprite_ext(a.sprite,a.frame,_b.x,_b.y-lift,sx*_b.dragon_facing,sy,0,col,alpha);
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

#macro DRAGON_RIG_ENABLED true
/// Dragon body rig: 2D skinning of the existing sprite frames (docs/Design/Technische Architektur.md 4.3, Boss-Design G2).
/// A coarse grid over the frame is bent by a few bones (wings, tail, neck, head) with smooth distance weights,
/// so the body stays one connected image: no cut parts, no seams, the original PNGs are untouched.
/// Purely visual: hitboxes, mouth anchors used by attacks and all timings are unchanged. During fire poses the
/// head/neck bones are not used, so the drawn mouth stays exactly on the annotated anchor (G1).
/// Bone coordinates are sprite pixels of the 512x512 dragonboss frames (origin 256,480), measured on the frames.
function dragon_rig_bones(_action) {
    // Left wing and tail sit at the same place in every dragonboss pose; head, neck and right wing only in "idle".
    static common=[
        {id:"wingL",x:205,y:262,ex:60,ey:140,r:120,parent:-1},
        {id:"tail1",x:205,y:385,ex:135,ey:410,r:48,parent:-1},
        {id:"tail2",x:135,y:410,ex:55,ey:420,r:62,parent:1}
    ];
    static idle=[
        {id:"wingL",x:205,y:262,ex:60,ey:140,r:120,parent:-1},
        {id:"tail1",x:205,y:385,ex:135,ey:410,r:48,parent:-1},
        {id:"tail2",x:135,y:410,ex:55,ey:420,r:62,parent:1},
        {id:"neck",x:292,y:300,ex:312,ey:222,r:52,parent:-1},
        {id:"head",x:312,y:222,ex:372,ey:178,r:78,parent:3},
        {id:"wingR",x:362,y:250,ex:440,ey:135,r:96,parent:-1}
    ];
    return _action=="idle" ? idle : common;
}
/// Bone angles in degrees (positive = clockwise on screen with y down) from the boss state. Secondary motion:
/// tail2 and head lag behind tail1 and neck, wings counter-swing.
function dragon_rig_pose(_b,_action) {
    var t=_b.dragon_clock,age=_b.dragon_state_age,p={wingL:-3*sin(t*1.25),wingR:3*sin(t*1.25),tail1:2.5*sin(t*1.4),neck:2*sin(t*1.1)};
    p.tail2=p.tail1+6*sin(t*1.4-.9);
    var look=0;
    if(instance_exists(ObjectPlayer)) {
        var size=_b.visual_height/430;
        look=clamp((ObjectPlayer.y-(_b.y-300*size))/320,-1,1)*7;      // head tilts toward the player's height
    }
    p.head=2.5*sin(t*1.1-.5)+look;
    if(!_b.dragon_dying) {
        if(_b.boss_state=="windup") {
            var k=sin(pi*clamp(age/max(.001,_b.enc_cfg.warning),0,1));  // rises and returns before the attack starts
            p.wingL-=7*k;p.wingR+=7*k;p.tail1+=3*k;
        }
        if(_b.boss_cast=="wind" && _b.boss_state=="active"){var f=sin(age*2*pi*3.5);p.wingL+=-14*f;p.wingR+=14*f;}
        if(_b.dragon_hit_age<0.18){var j=(1-_b.dragon_hit_age/.18);p.neck-=5*j;p.head-=6*j;p.tail2+=6*j;}
        // Tail sweep: the tail lifts and coils (windup), then whips through (active). Bite: neck pulls back, then lunges.
        if(_b.boss_cast=="tail" || _b.boss_cast=="bite") {
            var w=_b.boss_state=="windup" ? clamp(age/max(.001,_b.enc_cfg.warning),0,1) : 1,s=_b.boss_state=="active" ? sin(pi*clamp(age/max(.001,_b.enc_cfg.active),0,1)) : 0;
            if(_b.boss_cast=="tail"){p.tail1+=10*w-24*s;p.tail2+=20*w-38*s;p.wingL-=4*w;}
            else {p.neck+=-9*w+16*s;p.head+=-11*w+18*s;p.wingL-=5*w;p.wingR+=5*w;}
        }
    }
    return p;
}
/// Weighted grid for one frame (cached per _key): sprite-space vertices with bone weights.
/// _feet_y >= 0 keeps everything below that line planted (weights fade out over 26 px above it).
function rig_mesh(_spr,_frame,_bones,_key,_feet_y=-1,_step=24) {
    if(!variable_global_exists("rig_cache"))global.rig_cache={};
    var key=_key+":"+string(_spr)+":"+string(_frame);
    if(variable_struct_exists(global.rig_cache,key))return global.rig_cache[$ key];
    var uv=sprite_get_uvs(_spr,_frame),w=sprite_get_width(_spr),h=sprite_get_height(_spr);
    // The grid covers the opaque part of the frame (crop rectangle reported by sprite_get_uvs, in pixels).
    var x0=uv[4],y0=uv[5],x1=x0+w*uv[6],y1=y0+h*uv[7];
    var cols=max(2,ceil((x1-x0)/_step)+1),rows=max(2,ceil((y1-y0)/_step)+1),nb=array_length(_bones);
    var m={cols:cols,rows:rows,px:[],py:[],w:[]};
    for(var r=0;r<rows;r++)for(var c=0;c<cols;c++) {
        var px=lerp(x0,x1,c/(cols-1)),py=lerp(y0,y1,r/(rows-1));
        array_push(m.px,px);array_push(m.py,py);
        var ws=array_create(nb,0),feet=_feet_y>=0 ? clamp((_feet_y-py)/26,0,1) : 1;
        for(var i=0;i<nb;i++) {
            var bn=_bones[i],d=dragon_rig_seg_dist(px,py,bn.x,bn.y,bn.ex,bn.ey);
            ws[i]=sqr(1-clamp(d/bn.r,0,1))*feet;
        }
        array_push(m.w,ws);
    }
    global.rig_cache[$ key]=m;
    return m;
}
function dragon_rig_seg_dist(_x,_y,_ax,_ay,_bx,_by) {
    var dx=_bx-_ax,dy=_by-_ay,l=dx*dx+dy*dy,t=l>0 ? clamp(((_x-_ax)*dx+(_y-_ay)*dy)/l,0,1) : 0;
    return point_distance(_x,_y,_ax+dx*t,_ay+dy*t);
}
/// Forward kinematics: every bone is a rotation about its pivot, applied after its parent's transform.
function dragon_rig_matrices(_bones,_pose) {
    var mats=[];
    for(var i=0;i<array_length(_bones);i++) {
        var bn=_bones[i],a=degtorad(variable_struct_exists(_pose,bn.id) ? _pose[$ bn.id] : 0),cs=cos(a),sn=sin(a);
        // local: p' = R(p - pivot) + pivot  ->  [a b c; d e f]
        var M=[cs,-sn,bn.x-cs*bn.x+sn*bn.y, sn,cs,bn.y-sn*bn.x-cs*bn.y];
        if(bn.parent>=0) {
            var P=mats[bn.parent];
            M=[P[0]*M[0]+P[1]*M[3],P[0]*M[1]+P[1]*M[4],P[0]*M[2]+P[1]*M[5]+P[2],
               P[3]*M[0]+P[4]*M[3],P[3]*M[1]+P[4]*M[4],P[3]*M[2]+P[4]*M[5]+P[5]];
        }
        array_push(mats,M);
    }
    return mats;
}
/// Draws the deformed dragon frame. _ox/_oy: world position of the sprite origin; _sx/_sy: scale (facing in _sx).
function dragon_rig_draw(_b,_spr,_frame,_action,_ox,_oy,_sx,_sy,_col,_alpha) {
    rig_draw_frame(_spr,_frame,dragon_rig_bones(_action),dragon_rig_pose(_b,_action),"dragon_"+_action,458,_ox,_oy,_sx,_sy,_col,_alpha,24);
}
/// Generic skinned draw: the frame is first drawn normally into a surface of its size (page uvs from sprite_get_uvs
/// did not match the primitive texture for large frames, tested 25.11.), then the bent grid is drawn as strips.
function rig_draw_frame(_spr,_frame,_bones,_pose,_key,_feet_y,_ox,_oy,_sx,_sy,_col,_alpha,_step=24,_rot=0,_cut=0) {
    var m=rig_mesh(_spr,_frame,_bones,_key,_feet_y,_step),mats=dragon_rig_matrices(_bones,_pose);
    var nb=array_length(_bones),n=m.cols*m.rows,wx=array_create(n),wy=array_create(n);
    var xo=sprite_get_xoffset(_spr),yo=sprite_get_yoffset(_spr),sw=sprite_get_width(_spr),sh=sprite_get_height(_spr);
    for(var k=0;k<n;k++) {
        var px=m.px[k],py=m.py[k],ws=m.w[k],sum=0,qx=0,qy=0;
        for(var i=0;i<nb;i++)if(ws[i]>0){var M=mats[i];sum+=ws[i];qx+=ws[i]*(M[0]*px+M[1]*py+M[2]);qy+=ws[i]*(M[3]*px+M[4]*py+M[5]);}
        if(sum>1){qx/=sum;qy/=sum;} else {qx+=(1-sum)*px;qy+=(1-sum)*py;}
        var dx=(qx-xo)*_sx,dy=(qy-yo)*_sy;
        if(_rot!=0){var cs=dcos(_rot),sn=dsin(_rot),rx=dx*cs+dy*sn;dy=-dx*sn+dy*cs;dx=rx;}
        wx[k]=_ox+dx;wy[k]=_oy+dy;
    }
    if(!variable_global_exists("rig_surfs"))global.rig_surfs={};
    var sk=string(sw)+"x"+string(sh),s=variable_struct_exists(global.rig_surfs,sk) ? global.rig_surfs[$ sk] : -1;
    if(!surface_exists(s)){s=surface_create(sw,sh);global.rig_surfs[$ sk]=s;}
    surface_set_target(s);draw_clear_alpha(c_black,0);if(_cut>0)draw_sprite_part(_spr,_frame,0,_cut,sw,sh-_cut,0,_cut);else draw_sprite(_spr,_frame,xo,yo);surface_reset_target();
    var tex=surface_get_texture(s),tu=texture_get_texel_width(tex),tv=texture_get_texel_height(tex);
    for(var r=0;r<m.rows-1;r++) {
        draw_primitive_begin_texture(pr_trianglestrip,tex);
        for(var c=0;c<m.cols;c++) {
            var a=r*m.cols+c,b=a+m.cols;
            draw_vertex_texture_colour(wx[a],wy[a],m.px[a]*tu,m.py[a]*tv,_col,_alpha);
            draw_vertex_texture_colour(wx[b],wy[b],m.px[b]*tu,m.py[b]*tv,_col,_alpha);
        }
        draw_primitive_end();
    }
}
