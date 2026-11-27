/// FFXIV-style choreography on top of the shared Boss System 2.0 hazards (docs/Design/Boss-Design.md).
/// Every pattern piece is an ordinary bv2 hazard: warning and activation run on the owner's single v2_clock,
/// so the countdown clock and the hitbox can never drift apart. Damage values are always the calling
/// ability's existing damage; this file adds geometry and timing, no new balancing numbers.
function bc_config() {
    static cfg={beam_length:2600,       // "unbounded" beams: longer than any camera diagonal in a 4096 world
        far_distance:420,               // pressure starts beyond this distance (hysteresis: ends below far_exit) ...
        far_exit:330,far_span:520,      // ... and grows to full over far_span pixels (user order 26.11.: clearly more aggressive bosses)
        far_time:1.2,                   // announced catch-up move after this long at range (counted in every state, started only between attacks)
        catchup_cooldown:9,             // was 20 s: distance alone must not stay a risk-free strategy
        far_recovery_cut:.45,far_speed_dragon:230,far_speed_behemoth:170,far_follow_twins:1.0, // twins already aim at the player; a faster centre shifted their beam origins away (boss suite 26.11.)
        dive_warning:1.6,dive_radius:170,emerge_warning:1.7,emerge_radius:190,reform_warning:1.1,reform_radius:85,
        cell:118,grid:5,
        seq_every:2,seq_gap:.5,seq_rest:2.2}; // choreographed sequences: regular attacks between two, fair pause between steps, rest after
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
/// Field-wide checkerboard (Phase 2B): ONE hazard whose cells are anchored to world coordinates and cover the whole
/// arena (room), independent of boss distance, player position and camera. _parity 0/1 selects the dangerous colour.
function bc_field_checker(_b,_kind,_cell,_parity,_warning,_active,_damage,_height="all") {
    var g=telegraph_make("checker",0,0,_cell,_warning,0,0,_cell);g.parity=_parity;g.bounds=[0,0,room_width,room_height];
    var h=bv2_hazard(_b,_kind,g,_active,_damage,_height,true,undefined);
    if(is_struct(h)){h.warning=max(0,_warning);h.field=true;}
    return h;
}
/// Parity of the world cell the player stands on: the first wave uses it, so the board always forces a move
/// (the grid itself stays anchored in the world; only the dangerous colour is chosen at cast time).
function bc_field_parity(_cell) {
    if(!instance_exists(ObjectPlayer))return 0;
    return ((floor(ObjectPlayer.x/_cell)+floor((ObjectPlayer.y-10)/_cell)) mod 2+2) mod 2;
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
    if(variable_struct_exists(_h,"cell")){telegraph_draw(_h.g,_col,hz_element_of(_h.kind));return true;} // queued: priority by time to impact
    if(!variable_struct_exists(_h,"sweep_from"))return false;
    var g=_h.g,p=telegraph_progress(g),len=min(g.radius,1150),span=_h.sweep_to-_h.sweep_from;
    var fan=telegraph_make("sector",g.x,g.y,len,1,(_h.sweep_from+_h.sweep_to)*.5,abs(span));
    if(g.shape=="sector")fan.span=abs(span)+g.span;
    telegraph_paint(fan,_col,.07,.32); // whole swept fan: visible but calm, the start lane carries the countdown
    if(g.shape=="line"){var lane=telegraph_make("line",g.x,g.y,len,g.duration,_h.sweep_from,0,g.width);lane.elapsed=g.elapsed;telegraph_draw(lane,_col,hz_element_of(_h.kind));}
    else {var start=telegraph_make("sector",g.x,g.y,len,g.duration,_h.sweep_from,g.span);start.elapsed=g.elapsed;telegraph_draw(start,_col,hz_element_of(_h.kind));}
    // direction arrows along the arc
    draw_set_color(merge_color(_col,c_white,.4));draw_set_alpha(.75);
    for(var k=1;k<=3;k++) {
        var a=_h.sweep_from+span*(k/4),r=len*(.35+.18*k),ax=g.x+lengthdir_x(r,a),ay=g.y+lengthdir_y(r,a),dir=a+(span>0 ? 90 : -90);
        draw_triangle(ax+lengthdir_x(9,dir),ay+lengthdir_y(9,dir),ax+lengthdir_x(6,dir+140),ay+lengthdir_y(6,dir+140),ax+lengthdir_x(6,dir-140),ay+lengthdir_y(6,dir-140),false);
    }
    draw_set_alpha(1);draw_set_color(c_white);
    return true;
}
/// Active look for pattern cells and long beams. Returns true if drawn.
function bc_hazard_active_draw(_h,_age,_col) {
    var g=_h.g,k=clamp((_h.active+.25-_age)*3,0,1);
    if(string_pos("dragon_",_h.kind)==1 && g.shape=="circle"){hz_area_draw(g,string_pos("void",_h.kind)>0 ? 4 : 1,_col,_age,_h.active,round(g.x));dragon_fx_sprite(string_pos("meteor",_h.kind)>0 ? 2 : 5,.375+clamp(_age/.65,0,.624),g.x,g.y,g.radius);draw_set_alpha(1);return true;}
    if(variable_struct_exists(_h,"cell")){hz_area_draw(g,hz_element_of(_h.kind),_col,_age,_h.active,round(g.x+g.y));return true;}
    if(g.shape=="line" && string_pos("dragon_beam",_h.kind)==1) {
        // The hitbox stays 2600 px; the flame art is only stretched up to the visible screen edge (same look as the original beam).
        vfx_beam_stream(g,1,_age,_h.active,7);return true; // coherent fire stream over the 2600 px hit line (drawn to the view edge)
    }
    if(variable_struct_exists(_h,"closing")){hz_area_draw(g,hz_element_of(_h.kind),_col,_age,_h.active,3);return true;}
    return false;
}
/// Activation sparks for cells (purely visual).
function bc_hazard_activated(_h) {
    if(!variable_struct_exists(_h,"cell"))return;
    var g=_h.g,mx=g.x+lengthdir_x(g.radius*.5,g.angle),my=g.y+lengthdir_y(g.radius*.5,g.angle);
    spell_vfx_burst(mx,my,min(g.width,g.radius)*.6,string_pos("ice",_h.kind)>0 ? 2 : (string_pos("swamp",_h.kind)>0 ? 6 : 1));
}

// ---------------- Rare catch-up moves (replace the technical teleport for ordinary distances) ----------------
/// Distance pressure 0..1 with hysteresis (enter beyond far_distance, leave below far_exit). Drives approach speed,
/// recovery length, the far attack pool and catch-up moves. Running, announced attacks are never interrupted by it.
function bc_pressure(_b) {
    if(!instance_exists(ObjectPlayer))return 0;
    var cfg=bc_config(),d=bc_boss_distance(_b);
    if(!variable_instance_exists(_b,"bc_far"))_b.bc_far=false;
    if(_b.bc_far && d<cfg.far_exit)_b.bc_far=false;else if(!_b.bc_far && d>cfg.far_distance)_b.bc_far=true;
    return _b.bc_far ? clamp((d-cfg.far_exit)/cfg.far_span,.25,1) : 0;
}
function bc_recovery(_b,_base) {return _base*(1-bc_config().far_recovery_cut*bc_pressure(_b));}
/// Far attack pool for the dragon: close-range patterns are swapped for reaching ones while the player keeps away.
function bc_dragon_far_pick(_b,_kind) {
    if(bc_pressure(_b)<.5 || !array_contains(["stomp","slam","vortex","wind"],_kind))return _kind;
    if(!variable_instance_exists(_b,"bc_far_pick"))_b.bc_far_pick=0;
    _b.bc_far_pick++;return (_b.bc_far_pick mod 2)==0 ? "beam" : "meteor";
}
/// Contracting ring waves (outside -> inside): _count concentric bands start at _from and shrink toward the centre,
/// each _delay later. Height "ground": a timed jump or dodge crosses a band; an optional gap is a walkable opening.
function bc_closing_waves(_b,_kind,_cx,_cy,_count,_from,_to,_band,_delay,_warning,_active,_damage,_gap_width=0,_gap_angle=0) {
    var out=[];
    for(var i=0;i<_count;i++) {
        var h=bc_closing_ring(_b,_kind,_cx,_cy,_from,_to,_band,_warning+i*_delay,_active,_damage);
        if(is_struct(h)){h.hit_once=true;h.interval=99;if(_gap_width>0){h.gap_width=_gap_width;h.gap_angle=_gap_angle+i*137;h.rotate_speed=0;}array_push(out,h);}
    }
    return out;
}
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
    // Range is counted in every state (pressure builds during long attacks too); the move itself starts only between attacks.
    _b.bc_far_time=bc_pressure(_b)>0 ? _b.bc_far_time+_dt : max(0,_b.bc_far_time-_dt*2);
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

/// Choreographed sequences (Boss-Design.md "Choreografierte Sequenzen", user decision 26.11.): fixed, learnable chains of
/// the boss's existing abilities. They complement the dynamic selection (rotation, distance pressure, melee, catch-up)
/// instead of replacing it: after every seq_every regular attacks the boss runs the next sequence of its current phase,
/// in list order. Every step is the complete ability (warning, countdown, activation). The next step starts only when
/// every hazard of the previous step has ended plus seq_gap (fair pause); after the last step the boss rests seq_rest.
/// Only sequences whose abilities are all unlocked are used. A phase change ends a sequence between steps; an announced
/// step always runs out. Data only: twins and behemoth can add their lists here (pilot: dragon).
function bc_sequences(_kind,_phase) {
    if(_kind!="dragon")return [];
    switch(_phase) {
        case 1:return [{name:"Feuerschneise",steps:["beam","arc"]},{name:"Glutboden",steps:["stomp","beam"]}];
        // 27.11.: no two identical sequences (Inferno was a copy of Feuersturm), void and volley in two sequences each, stomp
        // in five instead of seven; each phase keeps one sequence of abilities 1-3 for the minute-5 boss, told apart by
        // repetition and length instead of being a permutation of the same three steps
        case 2:return [{name:"Glutfaecher",steps:["arc","stomp","beam"]},{name:"Sternenbahn",steps:["meteor","beam","wind"]},{name:"Erdbeben",steps:["slam","wind","stomp"]}];
        case 3:return [{name:"Feuersturm",steps:["beam","stomp","vortex"]},{name:"Meteorhagel",steps:["meteor","volley","slam"]},{name:"Feuerwand",steps:["beam","arc","beam"]}];
        default:return [{name:"Inferno",steps:["vortex","void","volley"]},{name:"Sturmauge",steps:["wind","void","meteor"]},{name:"Letzte Glut",steps:["arc","beam","arc","stomp"]}];
    }
}
function bc_seq_available(_b,_kind,_phase=-1) {
    var seqs=bc_sequences(_kind,_phase<0 ? _b.boss_phase : _phase),out=[]; // ("all" is a GML keyword)
    for(var i=0;i<array_length(seqs);i++){var ok=true;for(var s=0;s<array_length(seqs[i].steps);s++)if(!boss_v2_attack_allowed(_b,seqs[i].steps[s]))ok=false;if(ok)array_push(out,seqs[i]);}
    return out;
}
function bc_seq_init(_b) {if(!variable_instance_exists(_b,"bc_seq")){_b.bc_seq=undefined;_b.bc_seq_done=undefined;_b.bc_seq_count=0;_b.bc_seq_next=0;_b.bc_seq_log=[];_b.bc_seq_force=-1;_b.bc_seq_wait=0;}}
/// Any hazard of this owner still warning or active (the next step of a sequence waits for it).
function bc_owner_busy(_b) {
    if(!variable_global_exists("bv2_hazards"))return false;
    for(var i=0;i<array_length(global.bv2_hazards);i++){var h=global.bv2_hazards[i];if(h.owner==_b && h.age<h.warning+h.active)return true;}
    return false;
}
/// Called when the boss decides its next attack. Returns true if a sequence owns this decision (a step started, or the
/// boss waits out the fair pause); false lets the normal selection run. _begin(_b,_kind) starts one ability.
function bc_seq_decide(_b,_kind,_begin,_dt) {
    if(!variable_instance_exists(_b,"v2_enabled") || !_b.v2_enabled)return false;
    bc_seq_init(_b);
    if(is_struct(_b.bc_seq) && _b.bc_seq.phase!=_b.boss_phase)_b.bc_seq=undefined; // phase change between steps ends it
    if(!is_struct(_b.bc_seq)) {
        var list=bc_seq_available(_b,_kind);
        if(array_length(list)==0 || (_b.bc_seq_force<0 && _b.bc_seq_count<bc_config().seq_every))return false;
        var idx=(_b.bc_seq_force>=0 ? _b.bc_seq_force : _b.bc_seq_next) mod array_length(list);
        if(_b.bc_seq_force<0)_b.bc_seq_next++;
        _b.bc_seq={def:list[idx],step:0,phase:_b.boss_phase,started:global.round_seconds,ran:[]};_b.bc_seq_count=0;_b.bc_seq_wait=0;
    }
    var s=_b.bc_seq;
    if(s.step>0) { // fair pause: all hazards of the previous step have ended, then seq_gap
        if(bc_owner_busy(_b)){_b.bc_seq_wait=0;return true;}
        _b.bc_seq_wait+=_dt;if(_b.bc_seq_wait<bc_config().seq_gap)return true;
    }
    var kind=s.def.steps[s.step];s.step++;_b.bc_seq_wait=0;array_push(s.ran,kind);
    _begin(_b,kind);
    if(s.step>=array_length(s.def.steps)) {
        array_push(_b.bc_seq_log,{name:s.def.name,phase:s.phase,steps:s.ran,started:s.started});if(array_length(_b.bc_seq_log)>32)array_delete(_b.bc_seq_log,0,1);
        _b.bc_seq_done=s;_b.bc_seq=undefined;
    }
    return true;
}
/// A regular (non-sequence) attack was chosen: counts toward the next sequence.
function bc_seq_regular(_b) {bc_seq_init(_b);_b.bc_seq_count++;}
/// Recovery after an attack: minimal inside a sequence (the step gate adds the fair pause), long after its last step.
function bc_seq_recovery(_b,_default) {
    bc_seq_init(_b);
    if(is_struct(_b.bc_seq))return .1;
    if(is_struct(_b.bc_seq_done)){_b.bc_seq_done=undefined;return bc_config().seq_rest;}
    return _default;
}
/// Name of the running sequence and step ("" if none), for the boss test HUD and review notes.
function bc_seq_label(_b) {
    if(!variable_instance_exists(_b,"bc_seq") || !is_struct(_b.bc_seq))return "";
    return _b.bc_seq.def.name+" "+string(_b.bc_seq.step)+"/"+string(array_length(_b.bc_seq.def.steps));
}
