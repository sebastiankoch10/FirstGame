/// FFXIV-style choreography on top of the shared Boss System 2.0 hazards (DESIGN/BOSS_DESIGN.md).
/// Every pattern piece is an ordinary bv2 hazard: warning and activation run on the owner's single v2_clock,
/// so the countdown clock and the hitbox can never drift apart. Damage values are always the calling
/// ability's existing damage; this file adds geometry and timing, no new balancing numbers.
function bc_config() {
    static cfg={beam_length:2600,       // "unbounded" beams: longer than any camera diagonal in a 4096 world
        far_distance:520,               // catch-up moves only when the player keeps this distance ...
        far_time:3.5,                   // ... for this many seconds while the boss is between attacks
        catchup_cooldown:20,            // rare: at most every 20 s
        dive_warning:1.6,dive_radius:170,emerge_warning:1.7,emerge_radius:190,reform_warning:1.1,reform_radius:85,
        cell:118,grid:5};
    return cfg;
}
/// Complex variants of the early abilities (1-3, unlocked at minute 5) only appear in later encounters
/// ("Früh freigeschaltete Fähigkeiten dürfen später komplexere Varianten bekommen"): boss phase AND >= 6 unlocked abilities.
function bc_complex(_b,_phase_min) {return _b.boss_phase>=_phase_min && variable_instance_exists(_b,"v2_unlocked") && _b.v2_unlocked>=6;}
function bc_clamp_x(_x,_pad=60) {return clamp(_x,_pad,room_width-_pad);}
function bc_clamp_y(_y,_pad=60) {return clamp(_y,_pad,room_height-_pad);}
/// Axis-aligned or rotated rectangle starting at (_x,_y) and running _len pixels along _angle.
function bc_rect(_b,_kind,_x,_y,_len,_width,_angle,_warning,_active,_damage,_height="ground") {
    var h=bv2_hazard(_b,_kind,telegraph_make("rectangle",_x,_y,_len,_warning,_angle,0,_width),_active,_damage,_height,true,undefined);
    if(is_struct(h)){h.warning=max(0,_warning);h.cell=true;}
    return h;
}
/// Checkerboard of n x n cells centred on (_cx,_cy). _parity 0/1 selects the colour; run 0 then 1 for the inversion.
function bc_checker(_b,_kind,_cx,_cy,_cell,_n,_parity,_warning,_active,_damage,_height="ground") {
    var half=_n*_cell*.5,cx=bc_clamp_x(_cx,half),cy=bc_clamp_y(_cy,half),out=[];
    for(var i=0;i<_n;i++)for(var j=0;j<_n;j++) {
        if((i+j) mod 2!=_parity)continue;
        var h=bc_rect(_b,_kind,cx-half+i*_cell,cy-half+(j+.5)*_cell,_cell,_cell,0,_warning,_active,_damage,_height);
        if(is_struct(h) && !h.expired)array_push(out,h);
    }
    return out;
}
/// Parallel stripes of width _stripe; every second stripe (selected by _parity) is dangerous.
function bc_stripes(_b,_kind,_cx,_cy,_angle,_stripe,_count,_length,_parity,_warning,_active,_damage,_height="ground") {
    var out=[];
    for(var k=0;k<_count;k++) {
        if(k mod 2!=_parity)continue;
        var off=(k-(_count-1)*.5)*_stripe;
        var sx=_cx+lengthdir_x(off,_angle+90)-lengthdir_x(_length*.5,_angle),sy=_cy+lengthdir_y(off,_angle+90)-lengthdir_y(_length*.5,_angle);
        var h=bc_rect(_b,_kind,sx,sy,_length,_stripe,_angle,_warning,_active,_damage,_height);
        if(is_struct(h) && !h.expired)array_push(out,h);
    }
    return out;
}
/// Two opposite 90 degree quadrants; call again with _first+90 for the other pair.
function bc_quadrants(_b,_kind,_cx,_cy,_radius,_first,_warning,_active,_damage,_height="ground") {
    bv2_sector(_b,_kind,_cx,_cy,_radius,_first,90,_warning,_active,_damage,_height);
    bv2_sector(_b,_kind,_cx,_cy,_radius,_first+180,90,_warning,_active,_damage,_height);
}
/// Out (donut, safe centre) followed by in (centre, safe outside) after _gap seconds; _in_first swaps the order.
function bc_in_out(_b,_kind,_cx,_cy,_inner,_outer,_warning,_gap,_active,_damage,_in_first=false,_height="all") {
    var t_ring=_in_first ? _warning+_gap : _warning,t_core=_in_first ? _warning : _warning+_gap;
    var r=bv2_ring(_b,_kind,_cx,_cy,_outer,_inner,t_ring,_active,_damage,_height);if(is_struct(r))r.hit_once=true;
    bv2_zone(_b,_kind,_cx,_cy,_inner+24,t_core,_active,_damage,_height);
}
/// Consecutive explosions marching along _angle.
function bc_line_burst(_b,_kind,_x,_y,_angle,_step,_count,_radius,_warning,_delay,_active,_damage,_height="all") {
    var out=[];
    for(var i=0;i<_count;i++) {
        var xx=_x+lengthdir_x(_step*i,_angle),yy=_y+lengthdir_y(_step*i,_angle);
        if(xx<_radius || yy<_radius || xx>room_width-_radius || yy>room_height-_radius)break;
        var h=bv2_zone(_b,_kind,xx,yy,_radius,_warning+i*_delay,_active,_damage,_height);
        if(is_struct(h) && !h.expired)array_push(out,h);
    }
    return out;
}
/// Long sweeping beam: telegraphed as the whole swept fan; the hitbox line turns from _from to _to during the active time.
function bc_sweep(_b,_kind,_x,_y,_from,_to,_width,_warning,_active,_damage,_height="high") {
    var h=bv2_hazard(_b,_kind,telegraph_make("line",_x,_y,bc_config().beam_length,_warning,_from,0,_width),_active,_damage,_height,false,undefined);
    // Fairness: a sweeping beam hits a player at most once per pass (no repeated ticks while it crosses the body).
    if(is_struct(h)){h.sweep_from=_from;h.sweep_to=_from+angle_difference(_to,_from);h.interval=.4;h.hit_once=true;}
    return h;
}
/// Sweeping sector (breath): same rule for cones.
function bc_sweep_sector(_h,_from,_to) {if(is_struct(_h)){_h.sweep_from=_from;_h.sweep_to=_from+angle_difference(_to,_from);_h.g.angle=_from;_h.hit_once=true;}return _h;}
/// Poison that closes in around (_cx,_cy): the safe inner radius shrinks from _from to _to during the active time.
function bc_closing_ring(_b,_kind,_cx,_cy,_from,_to,_band,_warning,_active,_damage) {
    var h=bv2_ring(_b,_kind,_cx,_cy,_from+_band,_from,_warning,_active,_damage,"ground");
    if(is_struct(h)){h.expand_from=_from+_band;h.expand_to=_to+_band;h.ring_width=_band;h.hit_once=false;h.interval=.6;h.closing=true;}
    return h;
}
/// Called from bv2_hazards_step for every active hazard.
function bc_hazard_update(_h,_p) {
    if(variable_struct_exists(_h,"sweep_from"))_h.g.angle=lerp(_h.sweep_from,_h.sweep_to,_p);
}
/// Telegraph for sweeps: the full fan that will be swept, the start edge and the sweep direction. Returns true if drawn.
function bc_hazard_telegraph(_h,_col) {
    if(variable_struct_exists(_h,"cell")) {
        // Overlapping waves stay readable: the next wave is strong with its countdown, a later wave is only a faint preview.
        var remaining=_h.warning-_h.age,u=clamp(1-(remaining-.35)/1.25,0,1),g=_h.g;
        telegraph_paint(g,_col,.012+.12*u,.06+.36*u);
        var mx=g.x+lengthdir_x(g.radius*.5,g.angle),my=g.y+lengthdir_y(g.radius*.5,g.angle);
        if(remaining<1.6) {
            var p=clamp(1-remaining/1.6,0,1),rad=clamp(min(g.radius,g.width)*.16,9,16),ang=90-360*p;
            draw_set_alpha(.35+.4*u);draw_set_color(_col);draw_circle(mx,my,rad,true);
            draw_set_alpha(.55+.4*u);draw_set_color(merge_color(_col,c_white,.6));draw_line_width(mx,my,mx+lengthdir_x(rad,ang),my+lengthdir_y(rad,ang),1);
            var late=clamp((p-.85)/.15,0,1);
            if(late>0){draw_set_alpha(.25*late);draw_set_color(merge_color(_col,c_white,.4));telegraph_paint(g,_col,0,.5*late);}
        } else {
            draw_set_alpha(.35);draw_set_color(_col);
            for(var k=-1;k<=1;k++)draw_circle(mx+k*7,my,1.6,false);
        }
        draw_set_alpha(1);draw_set_color(c_white);
        return true;
    }
    if(!variable_struct_exists(_h,"sweep_from"))return false;
    var g=_h.g,p=telegraph_progress(g),len=min(g.radius,1150),span=_h.sweep_to-_h.sweep_from;
    var fan=telegraph_make("sector",g.x,g.y,len,1,(_h.sweep_from+_h.sweep_to)*.5,abs(span));
    if(g.shape=="sector")fan.span=abs(span)+g.span;
    telegraph_paint(fan,_col,.055,.22);
    if(g.shape=="line")telegraph_paint(telegraph_make("line",g.x,g.y,len,1,_h.sweep_from,0,g.width),_col,.12,.5);
    // direction arrows along the arc
    draw_set_color(merge_color(_col,c_white,.4));draw_set_alpha(.75);
    for(var k=1;k<=3;k++) {
        var a=_h.sweep_from+span*(k/4),r=len*(.35+.18*k),ax=g.x+lengthdir_x(r,a),ay=g.y+lengthdir_y(r,a),dir=a+(span>0 ? 90 : -90);
        draw_triangle(ax+lengthdir_x(9,dir),ay+lengthdir_y(9,dir),ax+lengthdir_x(6,dir+140),ay+lengthdir_y(6,dir+140),ax+lengthdir_x(6,dir-140),ay+lengthdir_y(6,dir-140),false);
    }
    // countdown clock at the origin side
    var cx=g.x+lengthdir_x(min(160,len*.3),_h.sweep_from),cy=g.y+lengthdir_y(min(160,len*.3),_h.sweep_from),rad=16,ang=90-360*p;
    draw_set_alpha(.4);draw_set_color(_col);draw_circle(cx,cy,rad,true);
    draw_set_alpha(.9);draw_set_color(merge_color(_col,c_white,.65));draw_line_width(cx,cy,cx+lengthdir_x(rad,ang),cy+lengthdir_y(rad,ang),1);
    draw_set_alpha(1);draw_set_color(c_white);
    return true;
}
/// Active look for pattern cells and long beams. Returns true if drawn.
function bc_hazard_active_draw(_h,_age,_col) {
    var g=_h.g,k=clamp((_h.active+.25-_age)*3,0,1);
    if(string_pos("dragon_",_h.kind)==1 && g.shape=="circle"){dragon_fx_sprite(string_pos("meteor",_h.kind)>0 ? 2 : 5,.375+clamp(_age/.65,0,.624),g.x,g.y,g.radius);draw_set_alpha(1);return true;}
    if(variable_struct_exists(_h,"cell")) {
        var nx=lengthdir_x(g.width*.5,g.angle+90),ny=lengthdir_y(g.width*.5,g.angle+90),ex=g.x+lengthdir_x(g.radius,g.angle),ey=g.y+lengthdir_y(g.radius,g.angle);
        gpu_set_blendmode(bm_add);draw_set_color(_col);draw_set_alpha(.34*k);
        draw_triangle(g.x+nx,g.y+ny,ex+nx,ey+ny,ex-nx,ey-ny,false);draw_triangle(g.x+nx,g.y+ny,ex-nx,ey-ny,g.x-nx,g.y-ny,false);
        draw_set_alpha(.8*k);draw_set_color(merge_color(_col,c_white,.35));
        draw_line_width(g.x+nx,g.y+ny,ex+nx,ey+ny,2);draw_line_width(ex+nx,ey+ny,ex-nx,ey-ny,2);draw_line_width(ex-nx,ey-ny,g.x-nx,g.y-ny,2);draw_line_width(g.x-nx,g.y-ny,g.x+nx,g.y+ny,2);
        gpu_set_blendmode(bm_normal);
        var mx=(g.x+ex)*.5,my=(g.y+ey)*.5;
        if(string_pos("dragon",_h.kind)>0)dragon_fx_sprite(5,.375+clamp(_age/.65,0,.624),mx,my,min(g.width,g.radius)*.55);
        else bv2_fx(_h.kind,clamp(_age/max(.35,_h.active),0,1),mx,my,min(g.width,g.radius)*.5);
        draw_set_alpha(1);return true;
    }
    if(g.shape=="line" && string_pos("dragon_beam",_h.kind)==1) {
        // The hitbox stays 2600 px; the flame art is only stretched up to the visible screen edge (same look as the original beam).
        var r=combat_view_rect(),vis=600,corners=[[r.left,r.top],[r.right,r.top],[r.left,r.bottom],[r.right,r.bottom]];
        for(var i=0;i<4;i++)vis=max(vis,(corners[i][0]-g.x)*lengthdir_x(1,g.angle)+(corners[i][1]-g.y)*lengthdir_y(1,g.angle)+100);
        dragon_fire_sprite(g,g.angle,min(g.radius,vis),g.width,floor(current_time/80) mod 4,k);return true;
    }
    if(variable_struct_exists(_h,"closing")) {
        gpu_set_blendmode(bm_add);draw_set_color(_col);
        for(var n=0;n<5;n++){draw_set_alpha(.07*k);draw_circle(g.x,g.y,g.inner+18+n*26,true);}
        draw_set_alpha(.55*k);draw_circle(g.x,g.y,g.inner,true);draw_circle(g.x,g.y,g.inner+2,true);
        gpu_set_blendmode(bm_normal);
        for(var n=0;n<24;n++){var a=n*15+_age*12;bv2_fx(_h.kind,.3+frac(_age*.7+n*.13)*.4,g.x+lengthdir_x(g.inner+36,a),g.y+lengthdir_y(g.inner+36,a),34,a);}
        draw_set_alpha(1);return true;
    }
    return false;
}
/// Activation sparks for cells (purely visual).
function bc_hazard_activated(_h) {
    if(!variable_struct_exists(_h,"cell"))return;
    var g=_h.g,mx=g.x+lengthdir_x(g.radius*.5,g.angle),my=g.y+lengthdir_y(g.radius*.5,g.angle);
    spell_vfx_burst(mx,my,min(g.width,g.radius)*.6,string_pos("ice",_h.kind)>0 ? 2 : (string_pos("swamp",_h.kind)>0 ? 6 : 1));
}

// ---------------- Rare catch-up moves (replace the technical teleport for ordinary distances) ----------------
function bc_catchup_init(_b) {_b.bc_far_time=0;_b.bc_catch_cd=bc_config().catchup_cooldown*.5;_b.bc_catch=undefined;_b.bc_alpha=1;_b.bc_lift=0;}
function bc_boss_distance(_b) {
    var pl=ObjectPlayer,x0=_b.x,y0=_b.y;
    if(variable_instance_exists(_b,"v2_kind") && _b.v2_kind=="twins" && instance_exists(_b.v2_child)){x0=(_b.x+_b.v2_child.x)*.5;y0=(_b.y+_b.v2_child.y)*.5;}
    return point_distance(x0,y0,pl.x,pl.y);
}
/// Returns true while a catch-up move owns the boss. _kind: "dragon", "twins", "behemoth".
function bc_catchup_step(_b,_kind,_dt) {
    if(!variable_instance_exists(_b,"bc_far_time"))bc_catchup_init(_b);
    if(!instance_exists(ObjectPlayer))return false;
    var cfg=bc_config(),pl=ObjectPlayer;
    _b.bc_catch_cd=max(0,_b.bc_catch_cd-_dt);
    if(is_struct(_b.bc_catch))return bc_catchup_run(_b,_kind,_dt);
    var idle=_b.boss_state=="recovery";
    _b.bc_far_time=(idle && bc_boss_distance(_b)>cfg.far_distance) ? _b.bc_far_time+_dt : (idle ? max(0,_b.bc_far_time-_dt) : _b.bc_far_time);
    if(!idle || _b.bc_far_time<cfg.far_time || _b.bc_catch_cd>0)return false;
    // Start: the destination is fixed and announced now; it never follows the player afterwards.
    var damage=_kind=="dragon" ? dragon_encounter_config("slam",_b.boss_phase).damage*_b.v2_scaling.damage : bv2_attack_profile(_kind=="twins" ? "twins" : "behemoth",_kind=="twins" ? 7 : 5).damage*_b.v2_scaling.damage;
    var c={kind:_kind,age:0,x0:_b.x,y0:_b.y,tx:bc_clamp_x(pl.x,150),ty:bc_clamp_y(pl.y,_kind=="twins" ? 230 : 340),damage:damage,stage:0};
    _b.bc_catch=c;_b.bc_far_time=0;_b.bc_catch_cd=cfg.catchup_cooldown;
    if(variable_instance_exists(_b,"v2_attack_log"))array_push(_b.v2_attack_log,{ability:0,phase:_b.boss_phase,time:global.round_seconds,catchup:_kind});
    if(_kind=="dragon") {
        c.warning=cfg.dive_warning;c.zone=bv2_zone(_b,"dragon_dive",c.tx,c.ty-10,cfg.dive_radius,c.warning,.35,damage,"ground");
        if(is_struct(c.zone))c.zone.push=70;
        fg_sfx("dragon_wind");light_pulse(_b.x,_b.y-120,300,make_color_rgb(255,150,70),.8,.4);
    } else if(_kind=="behemoth") {
        c.warning=.8+cfg.emerge_warning;c.zone=bv2_zone(_b,"swamp_emerge",c.tx,c.ty-10,cfg.emerge_radius,c.warning,.4,damage,"ground");
        if(is_struct(c.zone))c.zone.push=80;
        fg_sfx("swamp_5");
    } else {
        var a=point_direction(pl.x,pl.y,_b.x,_b.y)+90;
        c.fx=bc_clamp_x(pl.x+lengthdir_x(220,a),90);c.fy=bc_clamp_y(pl.y+lengthdir_y(150,a),240);
        c.ix=bc_clamp_x(pl.x-lengthdir_x(220,a),90);c.iy=bc_clamp_y(pl.y-lengthdir_y(150,a),240);
        c.warning=.45+cfg.reform_warning;
        bv2_zone(_b,"twins_fire_vortex",c.fx,c.fy-10,cfg.reform_radius,c.warning,.3,damage*.6,"all");
        bv2_zone(_b,"twins_ice_vortex",c.ix,c.iy-10,cfg.reform_radius,c.warning,.3,damage*.6,"all");
        fg_sfx("twins_5");
    }
    return true;
}
function bc_catchup_run(_b,_kind,_dt) {
    var c=_b.bc_catch;c.age+=_dt;
    var p=clamp(c.age/c.warning,0,1);
    if(_kind=="dragon") {
        // Visible flight: lift off, glide to the announced landing point, slam down exactly when the countdown ends.
        var e=p*p*(3-2*p);
        _b.x=lerp(c.x0,c.tx,e);_b.y=lerp(c.y0,c.ty,e);_b.bc_lift=sin(pi*p)*230;
        _b.dragon_facing=c.tx<c.x0 ? -1 : 1;
        if(p>=1 && c.stage==0){c.stage=1;_b.bc_lift=0;light_pulse(c.tx,c.ty,360,make_color_rgb(255,150,70),1.1,.4);spell_vfx_burst(c.tx,c.ty-10,160,5);spell_vfx_burst(c.tx,c.ty-10,120,1);fg_sfx("dragon_slam");}
        if(c.age>=c.warning+.45){_b.bc_catch=undefined;_b.bc_lift=0;dragon_state(_b,"recovery",.9);}
        return true;
    }
    if(_kind=="behemoth") {
        // Sink (0.8 s), travel hidden under the swamp, emerge at the announced point.
        if(c.age<.8)_b.bc_alpha=1-c.age/.8;
        else if(c.stage==0){c.stage=1;_b.x=c.tx;_b.y=c.ty;_b.bc_alpha=0;}
        if(p>=1){if(c.stage<2){c.stage=2;light_pulse(c.tx,c.ty-40,380,make_color_rgb(150,230,70),1,.4);spell_vfx_burst(c.tx,c.ty-10,170,6);spell_vfx_burst(c.tx,c.ty-10,140,5);fg_sfx("swamp_8");}_b.bc_alpha=clamp((c.age-c.warning)/.5,0,1);}
        if(c.age>=c.warning+.55){_b.bc_catch=undefined;_b.bc_alpha=1;bv2_encounter_state(_b,"recovery",.8);}
        return true;
    }
    // twins: dissolve into fire/ice vortices, re-form at the announced flank points (never on the player)
    if(c.age<.45)_b.bc_alpha=1-c.age/.45;
    else if(c.stage==0) {
        c.stage=1;_b.x=c.fx;_b.y=c.fy;if(instance_exists(_b.v2_child)){_b.v2_child.x=c.ix;_b.v2_child.y=c.iy;}
        _b.v2_center_x=c.tx;_b.v2_center_y=c.ty-10;_b.v2_formation="split";_b.v2_formation_age=0;_b.bc_alpha=0;
    }
    if(p>=1){if(c.stage<2){c.stage=2;spell_vfx_burst(c.fx,c.fy-60,90,1);spell_vfx_burst(c.ix,c.iy-60,90,2);}_b.bc_alpha=clamp((c.age-c.warning)/.35,0,1);}
    if(c.age>=c.warning+.4){_b.bc_catch=undefined;_b.bc_alpha=1;bv2_encounter_state(_b,"recovery",.7);}
    return true;
}
