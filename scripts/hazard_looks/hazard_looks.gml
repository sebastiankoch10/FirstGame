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
    // dragon (pilot): the attack is the warning - precursors instead of a marker (hz_pre_render)
    if(string_pos("dragon_",k)==1){var look=hz_dragon_look(_h);if(look!=""){
        var w=g;if(variable_struct_exists(_h,"warn_g")){w=_h.warn_g;w.elapsed=_h.age;w.duration=_h.warning;w.height=_h.height;}
        var ex=variable_struct_exists(_h,"sweep_from") ? {from:_h.sweep_from,to:_h.sweep_to} : undefined;
        telegraph_draw(w,_col,1,look,ex);return true;}}
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
    if(HZ_PRE_ENABLED && string_pos("dragon_",k)==1 && hz_dragon_active(_h,_age))return true; // the attack itself (hz_act_*)
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
    hz_look_impact_fx(_h);
    if(variable_struct_exists(_h,"enc") && (k=="dragon_meteor" || k=="dragon_magma")) {
        // one eruption sound and one flash per attack frame; further fields of that frame only glow (several flashes at
        // once washed out the screen, recording 27.11.)
        if(!variable_instance_exists(o,"enc_sfx_at") || o.enc_sfx_at!=o.v2_clock){fg_sfx(k=="dragon_meteor" ? "dragon_meteor" : "dragon_magma");o.enc_sfx_at=o.v2_clock;light_flash(g.x,g.y,min(300,g.radius*1.6+40),make_color_rgb(255,121,44),.7,.3,.02);}
        else light_pulse(g.x,g.y,220,make_color_rgb(255,121,44),.6,.25);
        return true;
    }
    switch(k) {
        case "dragon_slam":fg_sfx("dragon_slam");return true;
        case "dragon_vortex":fg_sfx("dragon_vortex");return true;
        case "dragon_arc":case "dragon_bite":case "dragon_tail":case "dragon_beam_line":return true; // the breath/strike light comes from the dragon's state change
        case "dragon_cone":case "dragon_fire_ring":case "dragon_meteor_ring":case "dragon_magma_cell":{
            // one soft light per attack frame: three cones igniting together flashed the screen white (visual-qa 27.11.)
            if(!variable_instance_exists(o,"enc_light_at") || o.enc_light_at!=o.v2_clock){o.enc_light_at=o.v2_clock;var cx=g.x,cy=g.y;if(g.shape=="sector"){cx+=lengthdir_x(min(g.radius,500)*.4,g.angle);cy+=lengthdir_y(min(g.radius,500)*.4,g.angle);}light_pulse(cx,cy,320,make_color_rgb(255,130,60),.8,.3);}
            return true;
        }
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

/// Impact particles of the dragon's attacks on ignition (HD-2D attack structure: core, sparks, shock ring, dust).
/// Visual only; budgets follow "Effektqualitaet" (fxp_n). Cells of a field-wide board burst in at most 8 visible cells.
function hz_look_impact_fx(_h) {
    if(!HZ_PRE_ENABLED || string_pos("dragon_",_h.kind)!=1)return;
    var k=_h.kind,g=_h.g;
    switch(k) {
        case "dragon_arc":case "dragon_cone":{
            repeat(fxp_n(k=="dragon_arc" ? 14 : 6)){var pt=geo_sample(g,vfx_random(1),vfx_random(1));fxp_add(pt.x,pt.y,vfx_random_range(-20,20),-vfx_random_range(40,110),vfx_random_range(.3,.6),1,vfx_choose(1,2),FXP_EMBER,FXP_EMIT,-60,2,0);}
            fx_shock(g.x,g.y,60,2,.25);
        }break;
        case "dragon_magma":case "dragon_meteor":fxp_impact(g.x,g.y,1,k=="dragon_meteor" ? .6 : .5);break;
        case "dragon_magma_cell":{var cells=geo_checker_cells(g),c=g.radius;for(var i=0;i<min(8,array_length(cells));i++){var j=floor(vfx_random(array_length(cells)));fxp_impact(cells[j][0]+c*.5,cells[j][1]+c*.5,1,.3);}}break;
        case "dragon_slam":{
            var o=_h.ring_origin;fx_shock(o.x,o.y,330,3.5,.45);
            repeat(fxp_n(16)){var a=vfx_random(360);fxp_add(o.x+lengthdir_x(40,a),o.y+lengthdir_y(20,a),lengthdir_x(160,a),lengthdir_y(70,a)-10,vfx_random_range(.5,.9),5,vfx_choose(4,5,6),FXP_PUFF,FXP_LIT,-8,1.8,.2,.8);}
        }break;
        case "dragon_vortex":{var o=_h.ring_origin;repeat(fxp_n(18)){var a=vfx_random(360),r=vfx_random_range(100,300);fxp_add(o.x+lengthdir_x(r,a),o.y+lengthdir_y(r,a),lengthdir_x(120,a+90),lengthdir_y(120,a+90),vfx_random_range(.3,.6),1,1,FXP_EMBER,FXP_EMIT,-30,1.5,0);}}break;
        case "dragon_bite":case "dragon_tail":{
            repeat(fxp_n(8)){var pt=geo_sample(g,vfx_random(1),vfx_random(1));fxp_add(pt.x,pt.y,vfx_random_range(-30,30),-vfx_random_range(10,30),vfx_random_range(.4,.7),5,vfx_choose(3,4),FXP_PUFF,FXP_LIT,-6,2,.2,.7);}
            fx_shock(g.x+lengthdir_x(g.radius*.5,g.angle),g.y+lengthdir_y(g.radius*.5,g.angle),70,2,.2);
        }break;
        case "dragon_fire_ring":case "dragon_meteor_ring":{repeat(fxp_n(10)){var pt=geo_sample(g,vfx_random(1),vfx_random(1));fxp_add(pt.x,pt.y,0,-vfx_random_range(40,90),vfx_random_range(.3,.5),1,1,FXP_EMBER,FXP_EMIT,-50,2,0);}}break;
    }
}

// ---------------- "Die Attacke ist die Warnung" (Leitbild G19, Kampf & Begegnungen 5.0, Boss-Design B2) ----------------
/// Precursors: the attack announces itself with its own elements, which build up exactly inside the hit shape and
/// intensify until they trigger (flames sprout and flicker, magma cracks glow, a meteor falls with its shadow, the ground
/// quakes, dust is kicked up, embers race along the lane a beam will ignite). Fairness:
///   - form = hit area: every element is sampled inside the shape and its boundary is lined with elements;
///   - same clock as the hit (p = elapsed / duration of the hazard), so lead time and trigger are unchanged;
///   - drawn on the readability layer (telegraph_flush): crisp, never post-processed, soonest mechanic on top, later ones
///     dimmed; the glow comes from the world light (hz_pre_lights, post-processed);
///   - height reads from the elements: ground attacks stay flat (cracks, low flames, dust), "all" attacks rise above figure
///     height (tall flames, falling rock), "high" attacks float at body height (embers in the air).
/// Pilot: the dragon (hz_dragon_look). Other bosses keep their marker telegraphs until they are converted.
#macro HZ_PRE_ENABLED true

/// Look of a dragon hazard kind ("" = classic telegraph).
function hz_dragon_look(_h) {
    if(!HZ_PRE_ENABLED)return "";
    switch(_h.kind) {
        case "dragon_arc":case "dragon_cone":case "dragon_fire_ring":return "flames";
        case "dragon_meteor_ring":return _h.g.shape=="ring" ? "flames" : "meteor";
        case "dragon_beam":case "dragon_beam_line":return "lane";
        case "dragon_magma":case "dragon_magma_cell":return "magma";
        case "dragon_meteor":return "meteor";
        case "dragon_slam":return "quake";
        case "dragon_vortex":return "swirl";
        case "dragon_bite":case "dragon_tail":return "dust";
    }
    return "";
}
/// Boundary points of a shape, inset by 2 px, every _step px (only those inside the view).
function hz_pre_edge_pts(_g,_step) {
    var out=[],v=combat_view_rect(),m=8;
    if(geo_is_checker(_g)) {
        var cells=geo_checker_cells(_g),c=_g.radius,w=c-5;
        for(var i=0;i<array_length(cells);i++){var x0=cells[i][0]+2,y0=cells[i][1]+2;for(var d=0;d<w;d+=_step)array_push(out,[x0+d,y0],[x0+w,y0+d],[x0+w-d,y0+w],[x0,y0+w-d]);}
        return out;
    }
    if(geo_is_line(_g)) {
        var hw=_g.width*.5-2,len=fx_beam_visible_len(_g.x,_g.y,_g.angle,_g.radius);
        for(var d=4;d<len;d+=_step)for(var s=-1;s<=1;s+=2){var px=_g.x+lengthdir_x(d,_g.angle)+lengthdir_x(hw*s,_g.angle+90),py=_g.y+lengthdir_y(d,_g.angle)+lengthdir_y(hw*s,_g.angle+90);if(px>v.left-m && px<v.right+m && py>v.top-m && py<v.bottom+m)array_push(out,[px,py]);}
        return out;
    }
    var arc=geo_arc(_g),r=_g.radius-2,r0=geo_inner(_g),n=max(6,round(arc[1]*pi/180*r/_step));
    for(var i=0;i<=n;i++){var a=arc[0]+arc[1]*i/n,px=_g.x+lengthdir_x(r,a),py=_g.y+lengthdir_y(r,a);if(px>v.left-m && px<v.right+m && py>v.top-m && py<v.bottom+m)array_push(out,[px,py]);}
    if(r0>4){var k=max(6,round(arc[1]*pi/180*r0/_step));for(var i=0;i<=k;i++){var a=arc[0]+arc[1]*i/k;array_push(out,[_g.x+lengthdir_x(r0+2,a),_g.y+lengthdir_y(r0+2,a)]);}}
    if(arc[1]<360)for(var s=0;s<2;s++){var a=arc[0]+arc[1]*s+(s==0 ? 1 : -1)*min(3,arc[1]*.1);for(var d=r0+4;d<r;d+=_step)array_push(out,[_g.x+lengthdir_x(d,a),_g.y+lengthdir_y(d,a)]);}
    return out;
}
/// One precursor element at (px,py). _h: stable hash 0..1, _tall: rises above figure height ("all").
function hz_pre_sprout(_px,_py,_kind,_el,_p,_k,_h,_t,_tall) {
    // per-frame budget (telegraph_flush): later mechanics draw from their own small pool, the next one keeps its elements
    if((_px>global.hz_brl && _px<global.hz_brr && _py>global.hz_brt && _py<global.hz_brb) || (_px>global.hz_prl && _px<global.hz_prr && _py>global.hz_prt && _py<global.hz_prb))return; // dragon body / player figure
    if(global.hz_pre_later){if(global.hz_pre_left_late<=0)return;global.hz_pre_left_late--;}else{if(global.hz_pre_left<=0)return;global.hz_pre_left--;}
    var pal=vfx_palette(_el),x0=round(_px),y0=round(_py),late=clamp((_p-.7)/.3,0,1);
    if(late>0 && (floor(_t*24+_h*7) mod 2)==0)x0+=_h>.5 ? 1 : -1; // it trembles just before it triggers
    switch(_kind) {
        case "flame":{
            var hgt=max(2,round((2+(_tall ? 11 : 6)*_p)*(.55+.45*_h)+sin(_t*17+_h*20)*(1+_p)));
            draw_set_alpha(_k*(.55+.45*_p));draw_set_color(pal[0]);draw_rectangle(x0-1,y0,x0+1,y0,false);
            draw_set_color(pal[1]);draw_rectangle(x0,y0-hgt+1,x0+1,y0-1,false);
            draw_set_alpha(_k*(.7+.3*_p));draw_set_color(late>.5 ? c_white : pal[2]);draw_rectangle(x0,y0-hgt,x0,y0-hgt+1,false);
        }break;
        case "bubble":{
            var ph=frac(_t*(.8+_h)+_h),s=ph<.7 ? 1 : 2;
            draw_set_alpha(_k*(.35+.65*_p)*(ph<.85 ? 1 : (1-ph)/.15));draw_set_color(ph<.5 ? pal[1] : pal[2]);draw_rectangle(x0,y0,x0+s-1,y0+s-1,false);
        }break;
        case "pebble":{
            var hop=round(abs(sin(_t*11+_h*30))*(1+3*late)*_p);
            draw_set_alpha(_k*(.55+.45*_p));draw_set_color(make_color_rgb(40,32,26));draw_rectangle(x0,y0+1,x0+1,y0+1,false);
            draw_set_color(make_color_rgb(112,96,78));draw_rectangle(x0,y0-hop-1,x0+1,y0-hop+(_h>.6 ? 0 : -1),false);draw_set_color(make_color_rgb(176,156,124));draw_point(x0,y0-hop-1);
        }break;
        case "dust":{
            var rise=round(frac(_t*(1+_h)+_h)*(2+4*_p));
            draw_set_alpha(_k*(.3+.6*_p)*(1-frac(_t*(1+_h)+_h)*.6));draw_set_color(merge_color(make_color_rgb(150,128,98),make_color_rgb(220,200,160),_h));
            draw_rectangle(x0,y0-rise,x0+(_p>.4 ? 1 : 0),y0-rise,false);
        }break;
        default:{ // ember: a flickering point of the element at body height for "high" attacks
            draw_set_alpha(_k*(.5+.5*_p)*(.65+.35*sin(_t*23+_h*40)));draw_set_color(_h>.5 ? pal[1] : pal[2]);draw_rectangle(x0,y0,x0+1,y0+(_p>.5 ? 1 : 0),false);
        }break;
    }
}
/// Elements spread over the area (area-uniform, stable positions) plus a lined boundary.
function hz_pre_field(_g,_kind,_el,_p,_k,_seed,_t,_tall,_dens=260,_edge=8) {
    var q=vfx_quality(),n=clamp(round(geo_area(_g)/_dens*(q==0 ? .5 : (q==1 ? .75 : 1))),8,260),v=combat_view_rect();
    var grow=.6+.4*_p; // most elements from the start (lead time readable, visual-qa 27.11.), the rest toward the trigger
    for(var i=0;i<n;i++) {
        var h1=vfx_hash(i,_seed+1)*.5+.5;if(h1>grow)continue;
        var pt=geo_sample(_g,frac(h1*7.31),vfx_hash(i,_seed+5)*.5+.5);
        if(pt.x<v.left-10 || pt.x>v.right+10 || pt.y<v.top-10 || pt.y>v.bottom+14)continue;
        if(!telegraph_contains(_g,pt.x,pt.y))continue;
        hz_pre_sprout(pt.x,pt.y,_kind,_el,_p,_k,vfx_hash(i,_seed+9)*.5+.5,_t,_tall);
    }
    // the boundary as a fringe of elements, irregular (jittered inward, some missing), not as a dotted line
    var e=(_edge>0 && _g.shape!="ring") ? hz_pre_edge_pts(_g,_edge) : [];
    for(var i=0;i<array_length(e);i++){var h=vfx_hash(i,_seed+13)*.5+.5,h2=vfx_hash(i,_seed+17)*.5+.5;if(h2<.22)continue;
        var px=e[i][0]+(h-.5)*12,py=e[i][1]+(h2-.5)*12;if(!telegraph_contains(_g,px,py)){px=e[i][0];py=e[i][1];}
        hz_pre_sprout(px,py,_kind,_el,_p,_k*.9,h,_t,_tall);}
}
/// Fire swirling around inside a ring band (vortex): embers circling on several radii, faster and denser toward the trigger.
function hz_pre_swirl(_g,_p,_k,_seed,_t,_el) {
    var pal=vfx_palette(_el),r0=max(geo_inner(_g),4),r1=_g.radius,arc=geo_arc(_g),rings=4;
    for(var j=0;j<rings;j++) {
        var rr=lerp(r0+4,r1-4,(j+.5)/rings),n=max(8,round(rr*arc[1]*pi/180/16)),spin=_t*(30+60*_p)*(j mod 2 ? -1 : 1);
        for(var i=0;i<n;i++) {
            if(vfx_hash(i+j*97,_seed)*.5+.5>.3+.7*_p)continue;
            var a=arc[0]+frac(i/n+spin/max(1,arc[1]))*arc[1],px=round(_g.x+lengthdir_x(rr,a)),py=round(_g.y+lengthdir_y(rr,a)),tail=round(2+3*_p);
            vfx_pixel_line(px,py,px+lengthdir_x(tail,a+(j mod 2 ? 90 : -90)),py+lengthdir_y(tail,a+(j mod 2 ? 90 : -90)),1,j<2 ? pal[1] : pal[2],_k*(.4+.6*_p));
        }
    }
    var e=hz_pre_edge_pts(_g,14);
    for(var i=0;i<array_length(e);i++){var h=vfx_hash(i,_seed+13)*.5+.5;if(h<.45)continue;var px=e[i][0]+(vfx_hash(i,_seed+19))*8,py=e[i][1]+(vfx_hash(i,_seed+23))*8;if(telegraph_contains(_g,px,py))hz_pre_sprout(px,py,"flame",_el,_p*(.6+.4*h),_k*.85,h,_t,false);}
}
/// Lane a beam will ignite: embers race out along it inside the hit width, sputtering sides, flame licks in the last 30 %.
/// _x (optional) {from,to}: the swept fan; embers drift across it in the sweep direction from 40 % on.
function hz_pre_lane(_g,_p,_k,_seed,_t,_x) {
    var pal=vfx_palette(1),len=fx_beam_visible_len(_g.x,_g.y,_g.angle,_g.radius),hw=_g.width*.5,ux=lengthdir_x(1,_g.angle),uy=lengthdir_y(1,_g.angle),nx=-uy,ny=ux;
    var n=round(16+56*_p);
    for(var i=0;i<n;i++) {
        var h1=vfx_hash(i,_seed)*.5+.5,h2=vfx_hash(i+7,_seed)*.5+.5,d=frac(h1+_t*(.35+.5*h2)*(.6+_p))*len,o=(h2-.5)*(hw*2-6),tl=round(2+5*_p);
        var px=_g.x+ux*d+nx*o,py=_g.y+uy*d+ny*o;
        vfx_pixel_line(px,py,px-ux*tl,py-uy*tl,1,h2>.6 ? pal[2] : pal[1],_k*(.45+.55*_p));
    }
    var e=hz_pre_edge_pts(_g,10),tick=floor(_t*10);
    for(var i=0;i<array_length(e);i++)if(vfx_hash(i,_seed+tick)*.5+.5<.35+.55*_p)hz_pre_sprout(e[i][0],e[i][1],"ember",1,_p,_k,vfx_hash(i,_seed+3)*.5+.5,_t,false);
    if(_p>.7)fxp_lane_licks(_g,len,(_p-.7)/.3,_k,_t,_seed);
    if(is_struct(_x) && _p>.4) {
        var span=_x.to-_x.from,dirn=sign(span),m=round(32+56*_p),lim=min(len,900);
        for(var i=0;i<m;i++) {
            var h1=vfx_hash(i,_seed+21)*.5+.5,h2=vfx_hash(i,_seed+23)*.5+.5,d=60+h2*(lim-60),a=_x.from+span*frac(h1+_t*(.25+.3*h2)),px=_g.x+lengthdir_x(d,a),py=_g.y+lengthdir_y(d,a);
            vfx_pixel_line(px,py,px-lengthdir_x(6,a+90*dirn),py-lengthdir_y(6,a+90*dirn),1,h2>.7 ? pal[2] : pal[1],_k*(.3+.45*(_p-.4)/.6));
        }
    }
}
/// Short flame licks along the lane near ignition (inside 80 % of the hit width).
function fxp_lane_licks(_g,_len,_q,_k,_t,_seed) {
    var pal=vfx_palette(1),hw=_g.width*.4,ux=lengthdir_x(1,_g.angle),uy=lengthdir_y(1,_g.angle),nx=-uy,ny=ux,n=round(10+30*_q),reach=_len*_q;
    for(var i=0;i<n;i++){var h1=vfx_hash(i,_seed+41)*.5+.5,h2=vfx_hash(i,_seed+43)*.5+.5,d=h1*reach,o=(h2-.5)*2*hw,fl=round(2+4*_q*(.6+.4*sin(_t*20+i)));
        var px=_g.x+ux*d+nx*o,py=_g.y+uy*d+ny*o;draw_set_alpha(_k*(.5+.5*_q));draw_set_color(h2>.5 ? pal[1] : pal[2]);draw_rectangle(round(px),round(py)-fl,round(px),round(py),false);}
}
/// Meteor: the penumbra of its shadow is the exact hit circle from the start (faint), the umbra grows to it by the impact,
/// heat glints line the rim, the rock falls in.
function hz_pre_meteor(_g,_p,_k,_seed,_t,_later) {
    _k=max(_k,.75); // a later meteor stays readable on dark ground (visual-qa 27.11.)
    geo_fill(_g,c_black,_k*(.30+.08*_p));
    geo_fill_band(_g,0,max(1,_g.radius*_p),c_black,_k*(.15+.25*_p));
    var mp=vfx_palette(1);gpu_set_blendmode(bm_add);geo_fill(_g,mp[0],_k*(.05+.10*_p));gpu_set_blendmode(bm_normal); // the rock's glow on the ground
    if(_p>.35){var pal=vfx_palette(1),n=round(8+22*_p),q=(_p-.35)/.65;
        for(var i=0;i<n;i++){var pt=geo_sample(_g,vfx_hash(i,_seed+71)*.5+.5,vfx_hash(i,_seed+73)*.5+.5),fl=.6+.4*sin(_t*21+i*1.7);
            draw_set_alpha(_k*q*fl);draw_set_color(i mod 3==0 ? pal[2] : pal[1]);draw_point(round(pt.x),round(pt.y));}}
    hz_meteor_rock(_g,_p,_t,_seed);
}
/// Heat of the attack on the ground over exactly its hit area: a flickering glow that deepens toward the trigger (no
/// outline, no filling countdown). With the elements on top it carries the form; recording 27.11.: elements alone were
/// too faint to read the safe area at play size.
function hz_pre_heat(_g,_el,_p,_k,_t,_seed) {
    var pal=vfx_palette(_el),fl=.85+.15*sin(_t*9+_seed);
    var kk=geo_is_checker(_g) ? max(_k,.8) : _k;
    geo_fill(_g,merge_color(pal[0],c_black,.25),kk*(.15+.12*_p)*fl); // readable from the start (visual-qa 27.11.)
    if(_p>.6)geo_fill(_g,pal[1],_k*.08*(_p-.6)/.4*fl);
}
/// Render one queued precursor (called from telegraph_flush in time-to-impact order).
function hz_pre_render(_g,_col,_el,_later,_look,_x) {
    var p=clamp(_g.elapsed/max(.001,_g.duration),0,1),t=current_time/1000,k=_later ? .4 : 1,seed=round(_g.x*.37+_g.y*.71)+round(_g.radius);
    global.hz_pre_later=_later;
    var tall=variable_struct_exists(_g,"height") && _g.height=="all",ground=variable_struct_exists(_g,"height") && _g.height=="ground";
    if(_look=="flames" || _look=="magma" || _look=="swirl" || _look=="lane")hz_pre_heat(_g,1,p,k,t,seed);
    if(_look=="dust"){var dp=vfx_palette(5);geo_fill(_g,merge_color(dp[0],dp[1],.5),k*(.12+.12*p));}
    switch(_look) {
        case "flames":hz_pre_field(_g,ground ? "flame" : (tall ? "flame" : "ember"),1,p,k,seed,t,tall);break;
        case "magma":hz_crack_net(_g,p,k,seed,false);hz_pre_field(_g,"bubble",1,p,k,seed,t,false,900,0);if(tall)hz_pre_field(_g,"flame",1,p*.9,k,seed+3,t,true,2400,0);break;
        case "meteor":hz_pre_meteor(_g,p,k,seed,t,_later);break;
        case "quake":{var dp=vfx_palette(5);geo_fill(_g,merge_color(dp[0],dp[1],.5),k*(.12+.10*p));}hz_crack_net(_g,p,k,seed,false,true);hz_pre_field(_g,"pebble",5,p,k,seed,t,false,700,12);break;
        case "swirl":hz_pre_swirl(_g,p,k,seed,t,1);break;
        case "dust":hz_pre_field(_g,"dust",5,p,k,seed,t,tall,240,10);break;
        case "lane":hz_pre_lane(_g,p,k,seed,t,_x);break;
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Light of the dragon's attacks on the world (inside atmosphere_draw; post-processed glow, never a hard shape): the
/// precursors glow up toward the trigger, burning and molten ground lights its surroundings while active (beams light
/// themselves in fx_attacks_lights).
function hz_pre_lights(_rect) {
    if(!HZ_PRE_ENABLED || !variable_global_exists("bv2_hazards"))return;
    var lit=0,col=make_color_rgb(255,120,50);
    for(var i=0;i<array_length(global.bv2_hazards) && lit<8;i++) {
        var h=global.bv2_hazards[i];if(string_pos("dragon_",h.kind)!=1)continue;
        var look=hz_dragon_look(h);if(look=="" || look=="dust" || look=="quake")continue;
        var g=variable_struct_exists(h,"warn_g") ? h.warn_g : h.g,s=0;
        if(h.age>=h.warning) {
            var aa=h.age-h.warning;if(h.active<=0 || aa>h.active+.3 || look=="lane")continue;
            g=variable_struct_exists(h,"ring_fn") ? hz_ring_at(h,aa) : h.g;
            s=hz_act_fade(aa,h.active)*(look=="magma" || look=="meteor" ? .42 : .34);
        } else s=.18+.45*clamp(h.age/max(.001,h.warning),0,1);
        if(geo_is_checker(g))continue; // field-wide boards: the cells' own glow is enough
        if(geo_is_line(g)){for(var k=1;k<=3;k++){var d=min(g.radius,700)*k/3;atmosphere_source(g.x+lengthdir_x(d,g.angle),g.y+lengthdir_y(d,g.angle),120,col,s*.66,_rect);}lit++;continue;}
        var cx=g.x,cy=g.y;if(g.shape=="sector"){cx+=lengthdir_x(min(g.radius,600)*.55,g.angle);cy+=lengthdir_y(min(g.radius,600)*.55,g.angle);}
        atmosphere_source(cx,cy,min(380,g.radius*1.25),col,s,_rect);lit++;
    }
}
/// One crack segment; dark ground fissures get a lit lower lip (top-down light).
function hz_crack_seg(_ax,_ay,_bx,_by,_w,_col,_a,_dark,_pal) {
    vfx_pixel_line(_ax,_ay,_bx,_by,_w,_col,_a);
    if(_dark)vfx_pixel_line(_ax,_ay+2,_bx,_by+2,1,_pal[2],_a*.3);
}

// ---------------- Active looks of the dragon's attacks (pilot, HD-2D attack structure) ----------------
/// While a dragon attack hits, its area shows the attack itself instead of a marker: burning ground for fire sheets,
/// molten crust for magma and meteor craters, a dust wave for the slam, a swipe for bite and tail. Exactly the hit
/// geometry (the filled ground gives the edge; no outline, no countdown); the glow reaches the world through
/// hz_pre_lights. Visual only; per-frame element budget.
function hz_act_budget(_n) {
    var f=variable_global_exists("hz_frame") ? global.hz_frame : 0;
    if(!variable_global_exists("hz_act_frame") || global.hz_act_frame!=f){global.hz_act_frame=f;global.hz_act_left=(vfx_quality()==0 ? 300 : (vfx_quality()==1 ? 550 : 800));hz_boss_rect();}
    var n=max(0,min(_n,global.hz_act_left));global.hz_act_left-=n;return n;
}
/// Fade of an active surface: quick ignition, burns while active, dies down over 0.3 s afterwards.
function hz_act_fade(_age,_active) {return _age<=_active ? clamp(_age/.05,.35,1) : clamp(1-(_age-_active)/.3,0,1);}
/// The part of a round shape that can be on screen (sampling only; fills and hit tests keep the full shape): the radius
/// is cut at the farthest view corner and, when the centre lies off screen, the arc at the angular window of the view.
/// Big rings and long cones would otherwise spend their elements off screen.
function hz_vis_g(_g) {
    if(geo_is_checker(_g) || geo_is_line(_g))return _g;
    var v=combat_view_rect(),cx=[v.left,v.right,v.left,v.right],cy=[v.top,v.top,v.bottom,v.bottom],m=0,an=[];
    for(var i=0;i<4;i++){m=max(m,point_distance(_g.x,_g.y,cx[i],cy[i]));array_push(an,point_direction(_g.x,_g.y,cx[i],cy[i]));}
    var inside=_g.x>=v.left && _g.x<=v.right && _g.y>=v.top && _g.y<=v.bottom;
    if(m>=_g.radius && inside)return _g;
    var c=variable_clone(_g);c.radius=max(geo_inner(_g)+1,min(_g.radius,m));if(inside)return c;
    array_sort(an,true);var best=0,bi=0;
    for(var i=0;i<4;i++){var gap=(i<3 ? an[i+1] : an[0]+360)-an[i];if(gap>best){best=gap;bi=i;}}
    var arc=geo_arc(_g),w0=((bi<3 ? an[bi+1] : an[0])-arc[0]+720) mod 360,w1=w0+360-best,lo=0,hi=0;
    if(arc[1]>=360){lo=w0;hi=w1;}
    else {var l1=max(0,w0),h1=min(arc[1],min(w1,360)),l2=0,h2=min(arc[1],max(0,w1-360));if(h1-l1>=h2-l2){lo=l1;hi=h1;}else{lo=l2;hi=h2;}}
    var sp=max(.5,hi-lo);
    if(_g.shape=="ring"){c.gap_width=360-sp;c.gap_angle=arc[0]+lo+sp+c.gap_width*.5;}
    else {c.shape="sector";c.angle=arc[0]+lo+sp*.5;c.span=sp;}
    return c;
}
/// One pixel flame: wide dark-red base, orange body, a swaying upper tongue, a yellow core. _s 0..1 size.
function hz_act_flame(_px,_py,_s,_k,_pal,_hot,_t,_h) {
    if(_s<=.05 || (_px>global.hz_brl && _px<global.hz_brr && _py>global.hz_brt && _py<global.hz_brb) || (_px>global.hz_prl && _px<global.hz_prr && _py>global.hz_prt+14 && _py<global.hz_prb+14))return;
    var x0=round(_px),y0=round(_py),hh=max(3,round(4+15*_s)),w=max(1,round(1+3.5*_s)),sw=round(sin(_t*9+_h*20)*(.5+1.5*_s)),w7=max(1,round(w*.7)),w3=max(1,round(w*.4));
    draw_set_alpha(_k*.92);draw_set_color(_pal[0]);draw_rectangle(x0-w,y0-round(hh*.3),x0+w-1,y0,false);
    draw_set_color(_pal[1]);draw_rectangle(x0-w7,y0-round(hh*.68),x0+w7-1,y0-1,false);
    draw_rectangle(x0-w3+sw,y0-hh+1,x0+w3-1+sw,y0-round(hh*.6),false);
    if(_s>.45 || _hot){draw_set_color(_hot ? c_white : _pal[2]);draw_rectangle(x0-w3,y0-round(hh*.42),x0+w3-1,y0-1,false);}
    if(_s>.6){draw_set_color(_pal[2]);draw_point(x0+sw,y0-hh);}
}
/// Soft round glow (vertex alpha fan, centre _a, rim 0): light without a hard edge.
function hz_soft_glow(_x,_y,_r,_col,_a) {
    if(_a<=0 || _r<1)return;
    draw_primitive_begin(pr_trianglelist);
    for(var i=0;i<12;i++){var a=i*30,b=a+30;draw_vertex_colour(_x,_y,_col,_a);draw_vertex_colour(_x+lengthdir_x(_r,a),_y+lengthdir_y(_r,a)*.8,_col,0);draw_vertex_colour(_x+lengthdir_x(_r,b),_y+lengthdir_y(_r,b)*.8,_col,0);}
    draw_primitive_end();
}
/// Smooth radial glow of a round shape from its origin (vertex alpha, light layer of the surface).
function hz_glow_radial(_g,_col,_a_in,_a_out,_r) {
    var arc=geo_arc(_g),steps=max(8,ceil(arc[1]/6)),r=min(_r,_g.radius);
    draw_primitive_begin(pr_trianglelist);
    for(var i=0;i<steps;i++){var a=arc[0]+arc[1]*i/steps,b=arc[0]+arc[1]*(i+1)/steps;
        draw_vertex_colour(_g.x,_g.y,_col,_a_in);draw_vertex_colour(_g.x+lengthdir_x(r,a),_g.y+lengthdir_y(r,a),_col,_a_out);draw_vertex_colour(_g.x+lengthdir_x(r,b),_g.y+lengthdir_y(r,b),_col,_a_out);}
    draw_primitive_end();
}
/// Burning ground over the exact hit shape: scorched red ground, uneven glow, a living carpet of flames that sprout,
/// peak and die, a smaller flame fringe at the edge; breath fans glow brighter toward the mouth.
function hz_act_fire(_g,_age,_active,_seed,_src) {
    var k=hz_act_fade(_age,_active);if(k<=0)return;
    var pal=vfx_palette(1),t=current_time/1000,v=combat_view_rect(),vg=hz_vis_g(_g),area=geo_area(vg),ign=clamp(1-_age/.12,0,1);
    geo_fill(_g,merge_color(pal[0],c_black,.4),k*.30);
    var band=_g.shape=="ring",n=hz_act_budget(clamp(round(area/(band ? 900 : 2000)),6,70)),hot=_age<.15,px=array_create(n,-99999),py=array_create(n,0),ps=array_create(n,0),ph=array_create(n,0);
    for(var i=0;i<n;i++) {
        var h0=vfx_hash(i,_seed+31)*.5+.5,life=t*2.4+h0*3,cyc=floor(life),q=life-cyc;
        var pt=geo_sample(vg,vfx_hash(i*7+cyc,_seed+33)*.5+.5,vfx_hash(i*5+cyc,_seed+35)*.5+.5);
        if(pt.x<v.left-10 || pt.x>v.right+10 || pt.y<v.top-4 || pt.y>v.bottom+22 || !telegraph_contains(_g,pt.x,pt.y))continue;
        px[i]=pt.x;py[i]=pt.y;ps[i]=sin(q*pi)*(.4+.6*h0);ph[i]=h0;
    }
    gpu_set_blendmode(bm_add);
    geo_fill(_g,pal[0],k*(.09+.03*sin(t*11+_seed)));
    if(_src && !geo_is_checker(_g))hz_glow_radial(_g,pal[1],k*.16,0,min(vg.radius,_g.radius*.6));
    if(ign>0 && area<160000)geo_fill(_g,pal[2],ign*.18);
    for(var i=0;i<n;i++)if(px[i]>-99999)hz_soft_glow(px[i],py[i]-3,10+14*ps[i],pal[0],k*.22*ps[i]);
    gpu_set_blendmode(bm_normal);
    for(var i=0;i<n;i++)if(px[i]>-99999){
        for(var c=1;c<=3;c++){var ox=vfx_hash(i*3+c,_seed+37)*7,oy=vfx_hash(i*3+c,_seed+39)*2+1,sc=ps[i]*(.45+.2*c/3)*(.8+.2*sin(t*13+c+i));if(telegraph_contains(_g,px[i]+ox,py[i]+oy))hz_act_flame(px[i]+ox,py[i]+oy,sc,k,pal,false,t,ph[i]+c*.21);}
        hz_act_flame(px[i],py[i],min(1.15,ps[i]*1.15),k,pal,hot,t,ph[i]);
    }
    var e=band ? [] : hz_pre_edge_pts(_g,11),m=hz_act_budget(array_length(e));
    for(var i=0;i<m;i++){var h=vfx_hash(i,_seed+13)*.5+.5;if(h<.4)continue;var q=frac(t*2.1+h*5);hz_act_flame(e[i][0]+(h-.5)*6,e[i][1]+vfx_hash(i,_seed+17)*3,(.15+.3*h)*(.5+.5*sin(q*pi)),k*.9,pal,false,t,h);}
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Network of jagged cracks scattered over the area (each runs both ways from a stable start and stops at the edge);
/// no radial star. Dark hairlines that glow up toward the trigger, or molten (_hot: wide glow, bright core).
function hz_crack_net(_g,_p,_k,_seed,_hot,_dark=false) {
    var dp=vfx_palette(5),pal=vfx_palette(1),vg=hz_vis_g(_g),area=geo_area(vg),n=clamp(round(area/2600),4,36),glow=clamp((_p-.2)/.8,0,1),v=combat_view_rect();
    var col=_hot ? pal[2] : merge_color(make_color_rgb(30,18,14),pal[1],glow),a0=_k*(.5+.5*_p),seg=geo_is_checker(_g) ? max(4,_g.radius*.11) : clamp(sqrt(area/n)*.16,5,13);
    for(var i=0;i<n;i++) {
        var pt=geo_sample(vg,vfx_hash(i,_seed+81)*.5+.5,vfx_hash(i,_seed+83)*.5+.5),a1=(vfx_hash(i,_seed+85)*.5+.5)*360,steps=round(2+4*(vfx_hash(i,_seed+87)*.5+.5));
        if(pt.x<v.left-60 || pt.x>v.right+60 || pt.y<v.top-60 || pt.y>v.bottom+60)continue;
        for(var dir=0;dir<2;dir++){var x0=pt.x,y0=pt.y,a=a1+dir*180;
            for(var s=0;s<steps;s++){a+=vfx_hash(i*17+s+dir*7,_seed+89)*38;var x1=x0+lengthdir_x(seg,a),y1=y0+lengthdir_y(seg,a);if(!telegraph_contains(_g,x1,y1))break;
                var mx=(x0+x1)*.5,my=(y0+y1)*.5;if(mx>global.hz_prl && mx<global.hz_prr && my>global.hz_prt && my<global.hz_prb){x0=x1;y0=y1;continue;}
                if(_hot){vfx_pixel_line(x0,y0,x1,y1,3,pal[0],_k*.6);vfx_pixel_line(x0,y0,x1,y1,1,s<steps-1 ? col : pal[1],_k);}
                else if(_dark)hz_crack_seg(x0,y0,x1,y1,2,make_color_rgb(30,22,17),a0,true,dp);
                else vfx_pixel_line(x0,y0,x1,y1,1,col,a0);
                x0=x1;y0=y1;}}
    }
}
/// Molten ground (magma eruption, meteor crater): a hot burst, then dark crust split by glowing cracks (the same network
/// that cracked during the warning), lava bubbles, eruption flames in the first moments; it cools while active.
function hz_act_magma(_g,_age,_active,_seed,_meteor) {
    var k=hz_act_fade(_age,_active);if(k<=0)return;
    var pal=vfx_palette(1),t=current_time/1000,v=combat_view_rect(),vg=hz_vis_g(_g),area=geo_area(vg),heat=clamp(1-_age/(_active+.3),0,1),ign=clamp(1-_age/(_meteor ? .16 : .12),0,1);
    if(_age>_active){geo_fill(_g,make_color_rgb(52,48,46),k*.5);return;} // cooled: grey, no glow (3a: what is safe looks safe)
    geo_fill(_g,make_color_rgb(30,12,9),k*.62);
    gpu_set_blendmode(bm_add);
    geo_fill(_g,pal[0],k*(.10+.14*heat)*(.9+.1*sin(t*8+_seed)));
    if(ign>0){geo_fill(_g,pal[1],ign*.12);if(!geo_is_checker(_g))hz_glow_radial(_g,pal[2],ign*.3,ign*.03,_g.radius);}
    gpu_set_blendmode(bm_normal);
    hz_crack_net(_g,1,k*(.55+.45*heat),_seed,true);
    var n=hz_act_budget(clamp(round(area/700),5,120));
    for(var i=0;i<n;i++) {
        var pt=geo_sample(vg,vfx_hash(i,_seed+41)*.5+.5,vfx_hash(i,_seed+43)*.5+.5);
        if(pt.x<v.left-8 || pt.x>v.right+8 || pt.y<v.top-4 || pt.y>v.bottom+22)continue;
        var h=vfx_hash(i,_seed+47)*.5+.5,q=frac(t*(.9+h)+h),x0=round(pt.x),y0=round(pt.y);
        if(_age<.4 && h>.4){hz_act_flame(pt.x,pt.y,(1-_age/.4)*(.55+.45*h),k,pal,_age<.1,t,h);continue;}
        var s=q<.6 ? 2 : 3;draw_set_alpha(k*(.45+.55*heat)*(q<.85 ? 1 : (1-q)/.15));draw_set_color(pal[0]);draw_rectangle(x0-1,y0-1,x0+s-1,y0+s-1,false);draw_set_color(q<.4 ? pal[2] : pal[1]);draw_rectangle(x0,y0,x0+s-2,y0+s-2,false);
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Dust wave of the slam over the exact expanding ring band: a billowing wall of dust, thicker at the front, grit thrown
/// outward (lit dust particles come from fx_hazard_flames_step). The band is the hit area; the inside is not marked.
function hz_act_shock(_ring,_age,_active,_seed) {
    var k=hz_act_fade(_age,_active);if(k<=0)return;
    var r0=geo_inner(_ring),r1=_ring.radius,t=current_time/1000,v=combat_view_rect(),c0=make_color_rgb(70,56,42),c1=make_color_rgb(128,106,80),c2=make_color_rgb(172,148,112);
    geo_fill(_ring,c0,k*.4);geo_fill(_ring,c1,k*.22);
    var m=hz_act_budget(max(16,round(r1*2*pi/4)));
    for(var i=0;i<m;i++) {
        var h=vfx_hash(i,_seed+51)*.5+.5,h2=vfx_hash(i,_seed+53)*.5+.5,a=(i+h*.9)*360/m,rr=lerp(r0+4,r1-3,sqrt(h2)),px=round(_ring.x+lengthdir_x(rr,a)),py=round(_ring.y+lengthdir_y(rr,a));
        if(px<v.left-14 || px>v.right+14 || py<v.top-14 || py>v.bottom+14)continue;
        var s=max(2,round((3+7*h)*(.6+.4*h2)+sin(t*7+i)));
        draw_set_alpha(k*.6);draw_set_color(c0);draw_circle(px,py,s,false);
        draw_set_alpha(k*.55);draw_set_color(c1);draw_circle(px-1,py-round(s*.5),max(1,s-2),false);
        if(h2>.55){draw_set_alpha(k);draw_set_color(make_color_rgb(52,40,30));draw_rectangle(px+round(s*.4),py-1,px+round(s*.4)+1,py,false);}
        if(h>.75){draw_set_alpha(k*.4);draw_set_color(c2);draw_circle(px-2,py-s,max(1,s-4),false);}
        if(h2>.85){var d=r1+2+8*frac(t*3+h);draw_set_alpha(k*.9);draw_set_color(make_color_rgb(60,46,36));draw_rectangle(round(_ring.x+lengthdir_x(d,a)),round(_ring.y+lengthdir_y(d,a))-2,round(_ring.x+lengthdir_x(d,a))+1,round(_ring.y+lengthdir_y(d,a))-1,false);}
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Bite and tail strike: curved swipe trails (warm dust tones, unlike the player's white sword arcs) sweep through the
/// exact sector (bite: from both sides, closing like jaws; tail: one sweep across), kicked-up dust settles over it.
function hz_act_swipe(_g,_age,_tail,_seed) {
    if(_age>.4)return;
    var pal=vfx_palette(0),dust=vfx_palette(5),q=clamp(_age/.1,0,1),k=_age<.12 ? 1 : clamp(1-(_age-.12)/.28,0,1),a0=_g.angle-_g.span*.5,sp=_g.span;
    geo_fill(_g,merge_color(dust[0],dust[1],.4),.34*k);
    var rows=_tail ? [.62,.8,.95] : [.7,.9],sweeps=_tail ? 1 : 2;
    for(var j=0;j<array_length(rows);j++)for(var s=0;s<sweeps;s++) {
        var rr=_g.radius*rows[j],w=_tail ? 7-j : 6,head=_tail ? q : (s==0 ? .5*q : 1-.5*q),dir=s==0 ? 1 : -1,tl=clamp(head-dir*.35,0,1);
        for(var i=0;i<10;i++){var u0=lerp(tl,head,i/10),u1=lerp(tl,head,(i+1)/10),fr=(i+1)/10,aa=a0+sp*u0,bb=a0+sp*u1,ax=_g.x+lengthdir_x(rr,aa),ay=_g.y+lengthdir_y(rr,aa),bx=_g.x+lengthdir_x(rr,bb),by=_g.y+lengthdir_y(rr,bb);
            vfx_pixel_line(ax,ay,bx,by,max(1,round(w*fr))+2,dust[0],k*(.3+.6*fr));
            vfx_pixel_line(ax,ay,bx,by,max(1,round(w*fr)),fr>.8 ? pal[2] : pal[1],k*(.35+.65*fr));}
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Active look of a dragon hazard; false = generic renderer.
function hz_dragon_active(_h,_age) {
    var k=_h.kind,g=_h.g,seed=round(g.x*.37+g.y*.71)+round(g.radius);
    switch(k) {
        case "dragon_arc":case "dragon_cone":hz_act_fire(g,_age,_h.active,seed,true);return true;
        case "dragon_fire_ring":hz_act_fire(g,_age,_h.active,seed,false);return true;
        case "dragon_meteor_ring":if(g.shape=="ring")hz_act_fire(g,_age,_h.active,seed,false);else hz_act_magma(g,_age,_h.active,seed,true);return true;
        case "dragon_magma":case "dragon_magma_cell":hz_act_magma(g,_age,_h.active,seed,false);return true;
        case "dragon_meteor":hz_act_magma(g,_age,_h.active,seed,true);return true;
        case "dragon_slam":case "dragon_vortex":{
            if(_age>_h.active)return true;
            var o=_h.ring_origin,ring=hz_ring_at(_h,_age),sd=round(o.x*.37+o.y*.71); // the hit test reads the same ring
            if(k=="dragon_slam"){if(variable_struct_exists(_h,"warn_g")){var dp=vfx_palette(5);geo_fill(_h.warn_g,merge_color(dp[0],dp[1],.5),.14);}hz_act_shock(ring,_age,_h.active,sd);}
            else hz_act_fire(ring,_age,_h.active,sd,false);
            return true;
        }
        case "dragon_bite":case "dragon_tail":hz_act_swipe(g,_age,k=="dragon_tail",seed);return true;
    }
    return false;
}
/// The falling meteor: a dark rock with glowing cracks inside a hot glow, a tapered flame trail back along its path.
function hz_meteor_rock(_g,_p,_t,_seed) {
    var pal=vfx_palette(1),rx=_g.x-50*(1-_p),ry=_g.y-300*(1-_p),ux=50/304.1,uy=300/304.1,s=round(6+5*_p),len=22+22*_p;
    gpu_set_blendmode(bm_add);hz_soft_glow(rx,ry,s*3.2,pal[0],.55);hz_soft_glow(rx,ry,s*1.8,pal[1],.35);gpu_set_blendmode(bm_normal);
    var lay=[[s*2.6,pal[0],.8],[s*1.8,pal[1],.9],[max(2,s*.9),pal[2],1]];
    for(var L=0;L<3;L++)for(var i=0;i<5;i++){var d0=len*i/5,d1=len*(i+1)/5,w=max(1,round(lay[L][0]*(1-i/6)*(.85+.15*sin(_t*30+i+L))));
        vfx_pixel_line(rx+ux*d0,ry-uy*d0,rx+ux*d1,ry-uy*d1,w,lay[L][1],lay[L][2]*(1-i*.15));}
    var x0=round(rx),y0=round(ry);
    draw_set_alpha(1);draw_set_color(make_color_rgb(54,34,28));draw_circle(x0,y0,s,false);draw_circle(x0+1,y0-1,s-1,false);
    draw_set_color(make_color_rgb(96,64,50));draw_circle(x0-round(s*.3),y0-round(s*.3),max(1,round(s*.5)),false);
    draw_set_color(pal[1]);draw_rectangle(x0+1,y0-1,x0+3,y0,false);draw_rectangle(x0-3,y0+2,x0-2,y0+3,false);draw_set_color(pal[2]);draw_point(x0+2,y0);draw_point(x0-1,y0+1);
}

/// Screen rectangle of the dragon's body (per frame): ground elements there would lie on the body, so they are skipped
/// (the body stands in front of the ground; the fill below stays so the hit area is never hidden).
function hz_boss_rect() {
    global.hz_brl=0;global.hz_brr=0;global.hz_brt=0;global.hz_brb=0;global.hz_prl=0;global.hz_prr=0;global.hz_prt=0;global.hz_prb=0;
    if(instance_exists(ObjectPlayer)){var pl=ObjectPlayer;global.hz_prl=pl.x-12;global.hz_prr=pl.x+12;global.hz_prt=pl.y-38;global.hz_prb=pl.y+4;}
    if(!variable_global_exists("active_boss") || !instance_exists(global.active_boss))return;
    var b=global.active_boss;if(!b.dragon_enabled || !variable_instance_exists(b,"visual_height"))return;
    var vh=b.visual_height;global.hz_brl=b.x-vh*.42;global.hz_brr=b.x+vh*.42;global.hz_brt=b.y-vh*.85;global.hz_brb=b.y-6;
}
