/// Shared attack looks of every boss and miniboss (paths merged 27.11., docs/Systeme/Bosse.md): ONE place for how a
/// bv2 hazard announces itself (warning), how it looks while it hits (active) and what sound and light its ignition has.
/// bv2_hazards_draw and bv2_hazards_step call these first; returning false keeps the generic renderer (telegraph_draw,
/// hz_area_draw, vfx_beam_stream) or the generic ignition light. Hit test, clock and geometry stay in boss_hazards_v2.
/// Hazard fields used here (all optional): col (colour override), warn_g (warning shape when it differs from the hit
/// shape, e.g. the full extent of an expanding ring), ring_fn/ring_origin (expanding ring, see hz_ring_at), src_x/src_y
/// (where a lobbed projectile starts), enc (part of the running encounter attack), marker (announcement only).

/// Expanding ring of a hazard at active time _t (seconds since activation): the one geometry for hit test, picture and
/// the boss suite's oracle. Dragon slam and vortex use dragon_ring_geometry (unchanged formula).
function hz_ring_at(_h,_t) {return dragon_ring_geometry(_h.ring_fn,_h.ring_origin,clamp(_t,0,_h.active),_h.active);}

function hz_look_warning(_h,_col) {
    var k=_h.kind,g=_h.g;
    if(variable_struct_exists(_h,"warn_g")){var w=_h.warn_g;w.elapsed=_h.age;w.duration=_h.warning;telegraph_draw(w,_col,hz_element_of(k));return true;}
    if(k=="dragon_bite" || k=="dragon_tail"){telegraph_draw(g,_col,0);return true;} // physical strike
    if(k=="dragon_meteor" && variable_struct_exists(_h,"enc")){telegraph_draw(g,_col,1);var p=telegraph_progress(g);dragon_fx_sprite(2,.2,g.x-50*(1-p),g.y-300*(1-p),36,285);return true;}
    if(k=="mini_lob") {
        telegraph_draw(g,_col,1);
        var p=clamp(_h.age/max(.001,_h.warning),0,1),xx=lerp(_h.src_x,g.x,p),gy=lerp(_h.src_y,g.y,p),hh=sin(p*pi)*125;
        draw_set_alpha(.5);draw_set_color(c_black);draw_ellipse(xx-11,gy-4,xx+11,gy+4,false);
        draw_set_alpha(1);draw_set_color(make_color_rgb(204,96,235));draw_circle(xx,gy-hh,11,false);draw_set_color(c_white);draw_circle(xx-3,gy-hh-3,3,false);
        return true;
    }
    return bc_hazard_telegraph(_h,_col);
}
function hz_look_active(_h,_age,_col) {
    var k=_h.kind,g=_h.g;
    switch(k) {
        case "dragon_arc":vfx_fire_cone(g.x,g.y,g.angle,g.span,g.radius,_age,_h.active);return true; // fills exactly the hit sector
        case "dragon_bite":case "dragon_tail":if(_age<.08)telegraph_flash(g,_col);return true;
        case "dragon_slam":case "dragon_vortex":{
            if(_age>_h.active)return true;
            var ring=hz_ring_at(_h,_age),r=ring.radius,o=_h.ring_origin; // the hit test reads the same ring
            if(k=="dragon_vortex")dragon_fx_sprite(6,.25+frac(_age)*.35,o.x,o.y,r,_h.owner.v2_clock*100);
            else {for(var dust=0;dust<12;dust++){var a=dust*30;class_fx_sprite(7,clamp(_age/_h.active,0,1),o.x+lengthdir_x(r-20,a),o.y+lengthdir_y(r-20,a),28,a);}if(_age<.4)class_fx_sprite(7,_age/.4,o.x,o.y,90);}
            hz_area_draw(ring,k=="dragon_slam" ? 5 : 1,_col,_age,_h.active,k=="dragon_slam" ? 2 : 8);
            return true;
        }
        case "mini_lightning":case "mini_lob":{
            var fade=1-clamp(_age/(_h.active+.28),0,1);
            draw_set_alpha(fade*.65);draw_set_color(make_color_rgb(255,85,126));draw_circle(g.x,g.y,g.radius,false);
            draw_set_alpha(fade);draw_set_color(make_color_rgb(255,233,235));draw_circle(g.x,g.y,g.radius,true);
            if(k=="mini_lightning"){draw_line_width(g.x-6,g.y-145,g.x+8,g.y-83,5);draw_line_width(g.x+8,g.y-83,g.x-7,g.y-46,5);draw_line_width(g.x-7,g.y-46,g.x,g.y,5);}
            draw_set_alpha(1);return true;
        }
    }
    return bc_hazard_active_draw(_h,_age,_col);
}
/// Ignition (first active frame): sounds and light of the attack. True = handled (no generic light).
function hz_look_activate(_h) {
    var k=_h.kind,g=_h.g,o=_h.owner;
    if(variable_struct_exists(_h,"enc") && (k=="dragon_meteor" || k=="dragon_magma")) {
        // one eruption sound per attack frame, a light flash per field (as before the merge)
        if(!variable_instance_exists(o,"enc_sfx_at") || o.enc_sfx_at!=o.v2_clock){fg_sfx(k=="dragon_meteor" ? "dragon_meteor" : "dragon_magma");o.enc_sfx_at=o.v2_clock;}
        light_flash(g.x,g.y,300,make_color_rgb(255,121,44),1.3,.32,.06);return true;
    }
    switch(k) {
        case "dragon_slam":fg_sfx("dragon_slam");return true;
        case "dragon_vortex":fg_sfx("dragon_vortex");return true;
        case "dragon_arc":case "dragon_bite":case "dragon_tail":case "dragon_beam_line":return true; // the breath/strike light comes from the dragon's state change
        case "mini_lightning":fg_sfx("lightning");light_pulse(g.x,g.y,700,make_color_rgb(184,213,255),1.5,.32);return true;
        case "mini_lob":fg_sfx("explosion");light_pulse(g.x,g.y,390,make_color_rgb(255,139,72),1.5,.32);return true;
    }
    return false;
}
/// Remove the hazards of the running encounter attack of _b (e.g. the boss repositions mid-attack); pattern hazards stay.
function bv2_clear_enc(_b) {
    if(!variable_global_exists("bv2_hazards"))return;
    for(var i=array_length(global.bv2_hazards)-1;i>=0;i--){var h=global.bv2_hazards[i];if(h.owner==_b && variable_struct_exists(h,"enc"))array_delete(global.bv2_hazards,i,1);}
}
/// Hit cadence of a hazard: _interval seconds between hits while active, or once.
function bv2_cadence(_h,_interval,_once) {if(is_struct(_h)){_h.interval=_interval;_h.hit_once=_once;}return _h;}
